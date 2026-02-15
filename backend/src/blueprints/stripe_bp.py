import flask

import stripe
from flask import Blueprint
from flask import current_app as app
from google.cloud.firestore_v1 import DELETE_FIELD

from src.secrets import Secrets
from src.utils import build_dynamic_link
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
    stripe.api_key = Secrets.STRIPE_KEY_TEST if is_test else Secrets.STRIPE_KEY


@bp.route("/checkout_webhook", methods=["POST"])
def stripe_checkout_webhook():
    is_test = _get_is_test()
    sig_header = flask.request.headers['STRIPE_SIGNATURE']

    secret = Secrets.STRIPE_CHECKOUT_WEBHOOK_SECRET if not is_test else Secrets.STRIPE_CHECKOUT_WEBHOOK_SECRET_TEST

    try:
        event = stripe.Webhook.construct_event(flask.request.data, sig_header, secret)
    except ValueError as e:
        # Invalid payload
        raise e
    except stripe.error.SignatureVerificationError as e:
        # Invalid signature
        raise e

    event_data = event["data"]["object"]

    # Handle the event
    if event["type"] == "checkout.session.completed":
        add_user_to_match(
            event_data["metadata"]["match_id"],
            event_data["metadata"]["user_id"],
            event_data["payment_intent"],            
        )
    else:
        print("checkout not successful")

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
        # Pre-fill with user info from Firestore
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

    # Derive base URLs from the incoming request so it works for both local and remote
    base_url = flask.request.host_url.rstrip("/")
    frontend_url = flask.request.args.get("redirect_url", "https://web.nutmegapp.com").rstrip("/")

    redirect_path = ("/match/" + match_id if match_id else "/user") + "?stripe_onboarding=complete"
    redirect_link = frontend_url + redirect_path

    # Only wrap in dynamic link for production frontend
    if "nutmegapp.com" in frontend_url:
        redirect_link = build_dynamic_link("http://web.nutmegapp.com" + redirect_path)

    # If the account is already fully onboarded, skip Stripe and go straight back
    account = stripe.Account.retrieve(account_id)
    if account.charges_enabled:
        # Sync to Firestore in case it wasn't already
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


@bp.route("/connect_account_updated_webhook", methods=["POST"])
def stripe_connect_account_updated_webhook():
    is_test = _get_is_test()
    sig_header = flask.request.headers['STRIPE_SIGNATURE']

    secret = Secrets.STRIPE_CONNECT_UPDATED_WEBHOOK_SECRET if not is_test else Secrets.STRIPE_CONNECT_UPDATED_WEBHOOK_SECRET_TEST

    try:
        event = stripe.Webhook.construct_event(flask.request.data, sig_header, secret)
    except ValueError as e:
        # Invalid payload
        raise e
    except stripe.error.SignatureVerificationError as e:
        # Invalid signature
        raise e

    is_test = not event["livemode"]
    event_data = event["data"]["object"]
    prefix = _stripe_prefix(is_test)

    # Handle the event
    if event["type"] == "account.updated" and event_data["charges_enabled"]:
        user_id = event_data["metadata"]["userId"]

        user_data = app.db_client.collection("users").document(user_id).get().to_dict()

        app.db_client.collection("users").document(user_id).update({
            "{}.charges_enabled".format(prefix): True
        })
        print("user {} can now receive payments on stripe".format(user_id))
        
    else:
        print("event not handled")

    return {}


@bp.route("/account/status")
def check_account_status():
    """Check connected account status on Stripe and sync to Firestore."""
    is_test = _get_is_test()
    _setup_stripe_key(is_test)
    prefix = _stripe_prefix(is_test)

    user_id = flask.request.args["user_id"]
    user_ref = app.db_client.collection('users').document(user_id)
    user_data = user_ref.get().to_dict()

    account_id = user_data.get(prefix, {}).get("connected_account_id")
    if not account_id:
        return {"data": {"has_account": False, "charges_enabled": False}}

    account = stripe.Account.retrieve(account_id)
    charges_enabled = account.charges_enabled

    # Sync to Firestore if changed
    if charges_enabled and not user_data.get(prefix, {}).get("charges_enabled", False):
        user_ref.update({"{}.charges_enabled".format(prefix): True})

    return {"data": {
        "has_account": True,
        "charges_enabled": charges_enabled,
    }}
