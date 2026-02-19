import firebase_admin
import flask
import stripe
from firebase_admin import firestore

from flask import Blueprint, Flask

from src.models._matches import Match as MatchModel
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

    if not match_info.get("price"):
        return (
            flask.jsonify({"error": "This match does not support Nutmeg payments"}),
            400,
        )

    match = MatchModel.from_dict(match_info, match_id)
    user_name = _get_user_name(user_id)
    match_desc = match.describe()
    product_name = match_desc
    product_description = "{} — paid by {}".format(match_desc, user_name)
    pi_description = "{} — paid by {}".format(match_desc, user_name)
    statement_suffix = _build_statement_descriptor_suffix(match_info)
    transfer_metadata = _build_transfer_metadata(match_info, user_name, match_id)

    price_amount = match_info["price"]["basePrice"] + match_info["price"].get("userFee", NUTMEG_FEE_CENTS)

    session = _create_checkout_session_with_deep_links(
        _get_stripe_customer_id(user_id, is_test),
        user_id,
        match_info["organizerId"],
        match_id,
        price_amount,
        is_test,
        web_origin,
        product_name=product_name,
        product_description=product_description,
        pi_description=pi_description,
        statement_suffix=statement_suffix,
        transfer_metadata=transfer_metadata,
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


def _parse_match_datetime(match_info):
    dt = match_info.get("dateTime")
    if dt is None:
        return None
    if hasattr(dt, "strftime"):
        return dt
    try:
        from datetime import datetime
        return datetime.fromisoformat(str(dt).replace("Z", "+00:00"))
    except Exception:
        return None


def _build_transfer_metadata(match_info, user_name, match_id):
    """Metadata attached to the auto-created transfer for programmatic lookups."""
    meta = {"match_id": match_id, "player_name": user_name}
    sport_center = match_info.get("sportCenter", {})
    venue = sport_center.get("name", "")
    if venue:
        meta["venue"] = venue
    dt = _parse_match_datetime(match_info)
    if dt:
        meta["match_date"] = dt.strftime("%Y-%m-%d %H:%M")
    return meta


def _build_statement_descriptor_suffix(match_info):
    """Max 22 chars for Stripe statement_descriptor_suffix."""
    sport_center = match_info.get("sportCenter", {})
    venue = sport_center.get("name", "")
    if venue:
        return venue[:22]
    city = sport_center.get("city", "")
    if city:
        return city[:22]
    return "Match"


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



def _create_checkout_redirects_to_web(
    customer_id,
    user_id,
    organizer_id,
    match_id,
    price_amount,
    test_mode,
    web_origin="https://web.nutmegapp.com",
    product_name=None,
    product_description=None,
    pi_description=None,
    statement_suffix=None,
    transfer_metadata=None,
):
    stripe.api_key = Secrets.STRIPE_KEY_TEST if test_mode else Secrets.STRIPE_KEY

    product_data = {"name": product_name or "Nutmeg Match"}
    if product_description:
        product_data["description"] = product_description

    pi_metadata = {"user_id": user_id, "match_id": match_id}
    if transfer_metadata:
        pi_metadata.update(transfer_metadata)

    session = stripe.checkout.Session.create(
        success_url="{}/match/{}?payment_outcome={}".format(
            web_origin, match_id, "success"
        ),
        cancel_url="{}/match/{}?payment_outcome={}".format(
            web_origin, match_id, "cancel"
        ),
        line_items=[{
            "price_data": {
                "currency": "eur",
                "unit_amount": price_amount,
                "product_data": product_data,
            },
            "quantity": 1,
        }],
        payment_intent_data={
            "metadata": pi_metadata,
            **({"description": pi_description} if pi_description else {}),
            **({"statement_descriptor_suffix": statement_suffix} if statement_suffix else {}),
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
    user_id,
    organizer_id,
    match_id,
    price_amount,
    test_mode,
    web_origin="https://web.nutmegapp.com",
    product_name=None,
    product_description=None,
    pi_description=None,
    statement_suffix=None,
    transfer_metadata=None,
):
    stripe.api_key = Secrets.STRIPE_KEY_TEST if test_mode else Secrets.STRIPE_KEY

    product_data = {"name": product_name or "Nutmeg Match"}
    if product_description:
        product_data["description"] = product_description

    pi_metadata = {"user_id": user_id, "match_id": match_id}
    if transfer_metadata:
        pi_metadata.update(transfer_metadata)

    session = stripe.checkout.Session.create(
        success_url=_build_redirect_url(web_origin, match_id, "success"),
        cancel_url=_build_redirect_url(web_origin, match_id, "cancel"),
        line_items=[{
            "price_data": {
                "currency": "eur",
                "unit_amount": price_amount,
                "product_data": product_data,
            },
            "quantity": 1,
        }],
        payment_intent_data={
            "metadata": pi_metadata,
            **({"description": pi_description} if pi_description else {}),
            **({"statement_descriptor_suffix": statement_suffix} if statement_suffix else {}),
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
