import base64
import logging
import threading
import time
from firebase_admin import firestore

import flask
from firebase_admin import auth
from flask import request
from flask_cors import CORS
import os
from src.blueprints import (
    feedback,
    sportcenters,
    locations,
    users,
    stripe_bp,
    matches,
    payments,
    leaderboard,
)


def _create_app():
    logging.info("Starting app")
    boot_time = time.perf_counter()
    first_request_lock = threading.Lock()
    first_request_seen = False

    app: flask.Flask = flask.Flask(__name__)
    db: firestore.client = firestore.client()
    app.db_client = db

    app.register_blueprint(matches.bp)
    app.register_blueprint(matches.bp_v2)
    app.register_blueprint(payments.bp)
    app.register_blueprint(users.bp)
    app.register_blueprint(sportcenters.bp)
    app.register_blueprint(locations.bp)
    app.register_blueprint(stripe_bp.bp)
    app.register_blueprint(feedback.bp)
    app.register_blueprint(leaderboard.bp)

    CORS(app)

    @app.before_request
    def before_request_callback():
        nonlocal first_request_seen

        if not first_request_seen:
            with first_request_lock:
                if not first_request_seen:
                    flask.g.is_boot_first_request = True
                    flask.g.first_request_started_at = time.perf_counter()
                    first_request_seen = True

        if "Authorization" in request.headers:
            decoded_token = auth.verify_id_token(
                request.headers["Authorization"].split(" ")[1]
            )
            flask.g.uid = decoded_token["uid"]
        else:
            flask.g.uid = None

        logging.info(
            f"[{request.method}] {request.path} "
            f"user={flask.g.uid or 'anon'} "
            f"client={request.headers.get('App-Version', 'unknown')}"
        )

        if request.method == "POST":
            try:
                body = request.get_data()
                if body:
                    encoded = base64.b64encode(body).decode("utf-8")
                    logging.info(f"Request body (base64): {encoded}")
            except Exception as e:
                logging.error(f"Error logging request body: {e}")

    @app.after_request
    def after_request_callback(response):
        if getattr(flask.g, "is_boot_first_request", False):
            now = time.perf_counter()
            request_duration_ms = int((now - flask.g.first_request_started_at) * 1000)
            since_boot_ms = int((now - boot_time) * 1000)
            logging.info(
                "First request after boot completed: "
                f"[{request.method}] {request.path} "
                f"status={response.status_code} "
                f"duration_ms={request_duration_ms} "
                f"since_boot_ms={since_boot_ms}"
            )
        return response

    @app.route("/routes", methods=["GET"])
    def routes():
        return ["%s" % rule for rule in app.url_map.iter_rules()], 200

    @app.errorhandler(Exception)
    def handle_exception(e):
        logging.exception("Unhandled exception")
        return {"error": str(e)}, 500

    @app.route("/_ah/warmup", methods=["GET"])
    def warmup():
        return {}, 200

    return app
