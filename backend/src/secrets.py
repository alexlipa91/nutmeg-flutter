from google.cloud import secretmanager
import os

GCP_PROJECT = "nutmeg-9099c"

_SECRET_NAMES = [
    "DYNAMIC_LINK_API_KEY",
    "GOOGLE_MAPS_API_KEY",
    "STRIPE_KEY",
    "STRIPE_KEY_TEST",
    "STRIPE_KEY_ES",
    "STRIPE_KEY_TEST_ES",
    "STRIPE_CHECKOUT_WEBHOOK_SECRET",
    "STRIPE_CHECKOUT_WEBHOOK_SECRET_TEST",
    "STRIPE_CONNECT_UPDATED_WEBHOOK_SECRET",
    "STRIPE_CONNECT_UPDATED_WEBHOOK_SECRET_TEST",
]


class Secrets:
    DYNAMIC_LINK_API_KEY: str = ""
    GOOGLE_MAPS_API_KEY: str = ""
    STRIPE_KEY: str = ""
    STRIPE_KEY_TEST: str = ""
    STRIPE_KEY_ES: str = ""
    STRIPE_KEY_TEST_ES: str = ""
    STRIPE_CHECKOUT_WEBHOOK_SECRET: str = ""
    STRIPE_CHECKOUT_WEBHOOK_SECRET_TEST: str = ""
    STRIPE_CONNECT_UPDATED_WEBHOOK_SECRET: str = ""
    STRIPE_CONNECT_UPDATED_WEBHOOK_SECRET_TEST: str = ""


def load_secrets():
    client = secretmanager.SecretManagerServiceClient()
    for name in _SECRET_NAMES:
        # Allow env var overrides (useful for local dev, e.g. Stripe CLI webhook secret)
        value = os.environ.get(name)
        if not value:
            secret_path = f"projects/{GCP_PROJECT}/secrets/{name}/versions/latest"
            response = client.access_secret_version(request={"name": secret_path})
            value = response.payload.data.decode("UTF-8")
        setattr(Secrets, name, value)
