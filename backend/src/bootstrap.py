import logging
import os

import firebase_admin
from firebase_admin import firestore

from src.common.cloud_logging import setup_cloud_logging
from src.secrets import load_secrets


def init():
    """Initialize logging, secrets, Firebase app and return Firestore client."""
    if "GAE_SERVICE" in os.environ:
        setup_cloud_logging()
    else:
        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s %(levelname)s %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )

    load_secrets()

    try:
        firebase_admin.get_app()
    except ValueError:
        firebase_admin.initialize_app()

    return firestore.client()
