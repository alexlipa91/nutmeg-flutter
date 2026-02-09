from google.cloud import secretmanager
import os

GCP_PROJECT = "nutmeg-9099c"

SECRETS = [
    "DYNAMIC_LINK_API_KEY",
    "GOOGLE_MAPS_API_KEY",
    "STRIPE_KEY",
    "STRIPE_KEY_TEST",
    "STRIPE_CHECKOUT_WEBHOOK_SECRET",
    "STRIPE_CHECKOUT_WEBHOOK_SECRET_TEST",
    "STRIPE_CONNECT_UPDATED_WEBHOOK_SECRET",
    "STRIPE_CONNECT_UPDATED_WEBHOOK_SECRET_TEST",
]


def load_secrets():
    client = secretmanager.SecretManagerServiceClient()
    for name in SECRETS:
        secret_path = f"projects/{GCP_PROJECT}/secrets/{name}/versions/latest"
        response = client.access_secret_version(request={"name": secret_path})
        os.environ[name] = response.payload.data.decode("UTF-8")
