import logging

import google.cloud.logging


def setup_cloud_logging():
    """Set up Google Cloud Logging with trace-based correlation.

    App logs will appear correlated with App Engine request logs in
    Logs Explorer (nested under the request), not as separate entries.
    """
    client = google.cloud.logging.Client()
    client.setup_logging(log_level=logging.INFO)
