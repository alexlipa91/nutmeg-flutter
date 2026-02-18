from src import _create_app
from src.common.cloud_logging import setup_cloud_logging
import firebase_admin
import os


def create_app():
    firebase_admin.initialize_app()

    from src.secrets import load_secrets
    load_secrets()

    if "GAE_SERVICE" in os.environ:
        setup_cloud_logging()

    return _create_app()


# variable used by Gunicorn
app = create_app()


if __name__ == "__main__":
    # Used when running locally only. When deploying to Google App
    # Engine, a webserver process such as Gunicorn will serve the app. This
    # can be configured by adding an `entrypoint` to app.yaml.
    app.run(host="localhost", port=8080, debug=True)
