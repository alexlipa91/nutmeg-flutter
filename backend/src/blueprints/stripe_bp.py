import os

import flask

import stripe
from flask import Blueprint
from flask import current_app as app
from google.cloud.firestore_v1 import DELETE_FIELD

from src.secrets import Secrets
from src.utils import build_dynamic_link, setup_stripe
from src.blueprints.matches import add_user_to_match

bp = Blueprint('stripe', __name__, url_prefix='/stripe')


def _get_is_test():
    """Read is_test from X-Test-Mode header (preferred) or fall back to URL params."""
    header = flask.request.headers.get("X-Test-Mode", "").lower()
    if header:
        return header == "true"
    # fallback to query params for backwards compat (webhooks, refresh links)
    return flask.request.args.get("is_test",
        flask.request.args.get("test", "false")).lower() == "true"


def _stripe_prefix(is_test):
    """Return the Firestore dict key for stripe data."""
    return "stripe_test" if is_test else "stripe"


def _setup_stripe_key(is_test):
    setup_stripe(is_test)


def _get_webhook_secrets(is_test):
    """Return all known webhook signing secrets to try during verification."""
    env_override = os.environ.get("STRIPE_CHECKOUT_WEBHOOK")
    if env_override:
        return [env_override]
    if is_test:
        return [
            Secrets.STRIPE_WEBHOOK_SECRET_ES_TEST,
        ]
    return [
        Secrets.STRIPE_WEBHOOK_SECRET_ES,
    ]


def _verify_webhook(payload, sig_header, is_test):
    """Try each known webhook secret until one verifies, or raise."""
    secrets = _get_webhook_secrets(is_test)
    last_error = None
    for secret in secrets:
        try:
            return stripe.Webhook.construct_event(payload, sig_header, secret)
        except stripe.error.SignatureVerificationError as e:
            last_error = e
    raise last_error


@bp.route("/webhook", methods=["POST"])
def stripe_webhook():
    is_test = _get_is_test()
    sig_header = flask.request.headers["STRIPE_SIGNATURE"]
    event = _verify_webhook(flask.request.data, sig_header, is_test)

    is_test = not event["livemode"]
    event_data = event["data"]["object"]
    event_type = event["type"]
    print(f"Stripe webhook event: {event_type}")

    if event_type == "checkout.session.completed":
        add_user_to_match(
            event_data["metadata"]["match_id"],
            event_data["metadata"]["user_id"],
            event_data["payment_intent"],
            is_test=event_data["metadata"].get("is_test") == "true",
        )

    elif event_type == "account.updated" and event_data.get("charges_enabled"):
        user_id = event_data["metadata"]["userId"]
        prefix = _stripe_prefix(is_test)
        app.db_client.collection("users").document(user_id).update({
            "{}.charges_enabled".format(prefix): True
        })
        print("user {} can now receive payments on stripe".format(user_id))

    else:
        print(f"event {event_type} not handled")

    return {}


@bp.route("/account")
def go_to_account_login_link():
    is_test = _get_is_test()
    _setup_stripe_key(is_test)
    prefix = _stripe_prefix(is_test)

    user_id = flask.request.args.get("user_id")
    user_data = app.db_client.collection('users').document(user_id).get().to_dict()
    account_id = user_data.get(prefix, {}).get("connected_account_id")

    response = stripe.Account.create_login_link(account_id)
    return flask.redirect(response.url)


@bp.route("/account/onboard")
def go_to_onboard_connected_account():
    is_test = _get_is_test()
    _setup_stripe_key(is_test)
    prefix = _stripe_prefix(is_test)

    user_id = flask.request.args["user_id"]
    match_id = flask.request.args.get("match_id")

    user_ref = app.db_client.collection('users').document(user_id)
    user_data = user_ref.get().to_dict()
    account_id = user_data.get(prefix, {}).get("connected_account_id")

    # Create a connected account if one doesn't exist yet
    if not account_id:
        name = user_data.get("name", "")
        email = user_data.get("email", "")
        name_parts = name.split(" ", 1) if name else ["", ""]
        first_name = name_parts[0]
        last_name = name_parts[1] if len(name_parts) > 1 else ""

        response = stripe.Account.create(
            type="express",
            email=email or None,
            capabilities={
                "transfers": {"requested": True},
            },
            business_type="individual",
            individual={
                "first_name": first_name or None,
                "last_name": last_name or None,
                "email": email or None,
            },
            business_profile={
                "product_description": "Nutmeg football matches",
                "name": "Nutmeg - {}".format(name) if name else "Nutmeg",
            },
            metadata={"userId": user_id},
            settings={
                "payouts": {
                    "debit_negative_balances": True,
                    "schedule": {"interval": "manual"},
                }
            },
        )
        account_id = response.id
        user_ref.update({"{}.connected_account_id".format(prefix): account_id})

    base_url = flask.request.host_url.rstrip("/")
    frontend_url = flask.request.args.get("redirect_url", "https://web.nutmegapp.com").rstrip("/")

    redirect_path = ("/match/" + match_id if match_id else "/user") + "?stripe_onboarding=complete"
    redirect_link = frontend_url + redirect_path

    if "nutmegapp.com" in frontend_url:
        redirect_link = build_dynamic_link("http://web.nutmegapp.com" + redirect_path)

    account = stripe.Account.retrieve(account_id)
    if account.charges_enabled:
        user_ref.update({"{}.charges_enabled".format(prefix): True})
        return flask.redirect(redirect_link)

    refresh_link = "{}/stripe/account/onboard?is_test={}&user_id={}"\
        .format(base_url, is_test, user_id)

    if match_id:
        refresh_link = refresh_link + "&match_id=" + match_id

    response = stripe.AccountLink.create(
        account=account_id,
        refresh_url=refresh_link,
        return_url=redirect_link,
        type="account_onboarding",
        collect="currently_due",
    )
    return flask.redirect(response.url)
