import logging
import os
import time
from google.cloud import secretmanager

GCP_PROJECT = "nutmeg-9099c"

_SECRET_NAMES = [
    "DYNAMIC_LINK_API_KEY",
    "GOOGLE_MAPS_API_KEY",
    "STRIPE_KEY",
    "STRIPE_KEY_TEST",
    "STRIPE_KEY_ES",
    "STRIPE_KEY_TEST_ES",
    "STRIPE_WEBHOOK_SECRET_ES",
    "STRIPE_WEBHOOK_SECRET_ES_TEST",
]


class Secrets:
    DYNAMIC_LINK_API_KEY: str = ""
    GOOGLE_MAPS_API_KEY: str = ""
    STRIPE_KEY: str = ""
    STRIPE_KEY_TEST: str = ""
    STRIPE_KEY_ES: str = ""
    STRIPE_KEY_TEST_ES: str = ""
    STRIPE_WEBHOOK_SECRET_ES: str = ""
    STRIPE_WEBHOOK_SECRET_ES_TEST: str = ""


def load_secrets():
    started_at = time.perf_counter()
    client = secretmanager.SecretManagerServiceClient()
    logging.info("Loading %d secrets", len(_SECRET_NAMES))
    values = {}
    # Allow env var overrides (useful for local dev, e.g. Stripe CLI webhook secret)
    for name in _SECRET_NAMES:
        value = os.environ.get(name)
        if not value:
            secret_path = f"projects/{GCP_PROJECT}/secrets/{name}/versions/latest"
            response = client.access_secret_version(request={"name": secret_path})
            value = response.payload.data.decode("UTF-8")
        values[name] = value

    for name in _SECRET_NAMES:
        setattr(Secrets, name, values[name])

    elapsed_ms = int((time.perf_counter() - started_at) * 1000)
    logging.info("Loaded %d secrets in %dms", len(_SECRET_NAMES), elapsed_ms)
