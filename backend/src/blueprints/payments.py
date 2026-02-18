import firebase_admin
import flask
import stripe
from firebase_admin import firestore

from flask import Blueprint, Flask

from src.secrets import Secrets
from src.utils import build_dynamic_link, NUTMEG_FEE_CENTS
from flask import current_app as app

bp = Blueprint("payments", __name__, url_prefix="/payments")


@bp.route("/checkout", methods=["GET"])
def checkout():
    request = flask.request
    match_id = request.args["match_id"]
    user_id = request.args["user_id"]
    is_test = (
        request.args.get("is_test") == "true"
        or request.headers.get("X-Test-Mode") == "true"
    )
    web_origin = request.args.get("web_origin", "https://web.nutmegapp.com")

    match_info = _get_match_info(match_id, is_test=is_test)

    if not match_info:
        return flask.jsonify({"error": "Match not found"}), 404

    if "stripePriceId" not in match_info:
        return (
            flask.jsonify({"error": "This match does not support Nutmeg payments"}),
            400,
        )

    user_name = _get_user_name(user_id)
    description = _build_payment_description(match_info, user_name)

    session = _create_checkout_session_with_deep_links(
        _get_stripe_customer_id(user_id, is_test),
        _get_stripe_connected_account_id(match_info["organizerId"], is_test),
        user_id,
        match_info["organizerId"],
        match_id,
        match_info["stripePriceId"],
        NUTMEG_FEE_CENTS,
        is_test,
        web_origin,
        description,
    )

    return flask.redirect(session.url)


def _get_match_info(match_id, is_test=False):
    coll = "matches_test" if is_test else "matches"
    data = app.db_client.collection(coll).document(match_id).get().to_dict()
    return data


def _get_user_name(user_id):
    data = app.db_client.collection("users").document(user_id).get(
        field_paths={"name"}).to_dict()
    return data.get("name", "Unknown") if data else "Unknown"


def _build_payment_description(match_info, user_name):
    parts = []

    sport_center = match_info.get("sportCenter", {})
    venue = sport_center.get("name", "")
    city = sport_center.get("city", "")
    if venue and city:
        parts.append("{}, {}".format(venue, city))
    elif venue or city:
        parts.append(venue or city)

    dt = match_info.get("dateTime")
    if dt:
        try:
            if hasattr(dt, "strftime"):
                parts.append(dt.strftime("%a %d %b %H:%M"))
            else:
                from datetime import datetime
                parsed = datetime.fromisoformat(str(dt).replace("Z", "+00:00"))
                parts.append(parsed.strftime("%a %d %b %H:%M"))
        except Exception:
            pass

    duration = match_info.get("duration")
    if duration:
        parts.append("{}min".format(duration))

    match_line = " · ".join(parts) if parts else "Nutmeg match"
    return "{} — paid by {}".format(match_line, user_name)


def _get_stripe_customer_id(user_id, test_mode):
    stripe.api_key = Secrets.STRIPE_KEY_TEST if test_mode else Secrets.STRIPE_KEY

    doc = app.db_client.collection("users").document(user_id)

    prefix = "stripe_test" if test_mode else "stripe"

    data = doc.get(field_paths={"name", "email", prefix}).to_dict()

    stripe_data = data.get(prefix, {})
    customer_id = stripe_data.get("customer_id")

    if not customer_id:
        print(
            "missing {}.customer_id for user {}. Creating it...".format(prefix, user_id)
        )
        response = stripe.Customer.create(email=data["email"], name=data["name"])
        customer_id = response["id"]
        doc.update({"{}.customer_id".format(prefix): customer_id})

    return customer_id


def _get_stripe_connected_account_id(organizer_id, test_mode):
    doc = app.db_client.collection("users").document(organizer_id)

    prefix = "stripe_test" if test_mode else "stripe"

    data = doc.get(field_paths={prefix}).to_dict()

    return data.get(prefix, {}).get("connected_account_id")


# application_fee_amount includes stripe fees
def _create_checkout_redirects_to_web(
    customer_id,
    connected_account_id,
    user_id,
    organizer_id,
    match_id,
    price_id,
    application_fee_amount,
    test_mode,
    web_origin="https://web.nutmegapp.com",
    description=None,
):
    stripe.api_key = Secrets.STRIPE_KEY_TEST if test_mode else Secrets.STRIPE_KEY

    session = stripe.checkout.Session.create(
        success_url="{}/match/{}?payment_outcome={}".format(
            web_origin, match_id, "success"
        ),
        cancel_url="{}/match/{}?payment_outcome={}".format(
            web_origin, match_id, "cancel"
        ),
        line_items=[{"price": price_id, "quantity": 1}],
        payment_intent_data={
            "application_fee_amount": application_fee_amount,
            "transfer_data": {
                "destination": connected_account_id,
            },
            "metadata": {"user_id": user_id, "match_id": match_id},
            **({"description": description} if description else {}),
        },
        mode="payment",
        customer=customer_id,
        metadata={
            "user_id": user_id,
            "match_id": match_id,
            "organizer_id": organizer_id,
        },
    )
    return session


def _build_redirect_url(web_origin, match_id, outcome):
    return "{}/match/{}?payment_outcome={}".format(web_origin, match_id, outcome)


def _create_checkout_session_with_deep_links(
    customer_id,
    connected_account_id,
    user_id,
    organizer_id,
    match_id,
    price_id,
    application_fee_amount,
    test_mode,
    web_origin="https://web.nutmegapp.com",
    description=None,
):
    stripe.api_key = Secrets.STRIPE_KEY_TEST if test_mode else Secrets.STRIPE_KEY

    session = stripe.checkout.Session.create(
        success_url=_build_redirect_url(web_origin, match_id, "success"),
        cancel_url=_build_redirect_url(web_origin, match_id, "cancel"),
        line_items=[{"price": price_id, "quantity": 1}],
        payment_intent_data={
            "application_fee_amount": application_fee_amount,
            "transfer_data": {
                "destination": connected_account_id,
            },
            "metadata": {"user_id": user_id, "match_id": match_id},
            **({"description": description} if description else {}),
        },
        mode="payment",
        customer=customer_id,
        metadata={
            "user_id": user_id,
            "match_id": match_id,
            "organizer_id": organizer_id,
            "is_test": str(test_mode).lower(),
        },
    )
    return session


if __name__ == "__main__":
    from dotenv import load_dotenv
    load_dotenv("scripts/.env.local")
    firebase_admin.initialize_app()
    app = Flask("test_app")
    app.db_client = firestore.client()
