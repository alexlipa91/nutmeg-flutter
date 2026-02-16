import logging

import flask
import googlemaps
import requests
from flask import Blueprint

from src.secrets import Secrets

logger = logging.getLogger(__name__)

bp = Blueprint('locations', __name__, url_prefix='/locations')


def _get_gmaps_client():
    return googlemaps.Client(key=Secrets.GOOGLE_MAPS_API_KEY)


def _format_predictions(predictions):
    return [{
        "description": p["description"],
        "matched_substrings": p["matched_substrings"],
        "place_id": p["place_id"],
    } for p in predictions]


@bp.route("/ip", methods=["GET"])
def get_location_from_ip():
    client_ip = flask.request.headers.get("X-Forwarded-For", flask.request.remote_addr)
    if client_ip and "," in client_ip:
        client_ip = client_ip.split(",")[0].strip()

    try:
        resp = requests.get(f"https://ipwho.is/{client_ip}", timeout=5)
        data = resp.json()
        if data.get("success", False):
            return {"data": {
                "country": data.get("country_code"),
                "city": data.get("city"),
                "lat": data.get("latitude"),
                "lng": data.get("longitude"),
            }}, 200
    except Exception:
        pass

    return {"data": None}, 200


@bp.route("/predictions", methods=["GET"])
def get_location_predictions_from_query():
    query = flask.request.args.get("query", None)
    predictions = _get_gmaps_client().places_autocomplete(query)
    return {"data": {"predictions": _format_predictions(predictions)}}, 200


@bp.route("/cities", methods=["GET"])
def get_city_from_query():
    query = flask.request.args.get("query", None)
    predictions = _get_gmaps_client().places_autocomplete(query, types="(cities)")
    return {"data": {"predictions": _format_predictions(predictions)}}, 200


@bp.route("/coordinates", methods=["GET"])
def get_location_details():
    data = flask.request.args
    lat = float(data["lat"])
    lng = float(data["lng"])

    results = _get_gmaps_client().reverse_geocode(
        (lat, lng), result_type="locality"
    )

    result = {}
    if results:
        for a in results[0]["address_components"]:
            if "locality" in a["types"]:
                result["city"] = a["long_name"]
            elif "country" in a["types"]:
                result["country"] = a["short_name"]

        result["lat"] = results[0]["geometry"]["location"]["lat"]
        result["lng"] = results[0]["geometry"]["location"]["lng"]
        result["place_id"] = results[0]["place_id"]

    return {"data": result}, 200


@bp.route("/place/<place_id>", methods=["GET"])
def get_place_location_info(place_id):
    place = _get_gmaps_client().place(
        place_id,
        fields=["name", "formatted_address", "geometry", "utc_offset", "address_component"]
    )["result"]

    lat = place["geometry"]["location"]["lat"]
    lng = place["geometry"]["location"]["lng"]

    country = None
    city = None
    for a in place["address_components"]:
        if "country" in a["types"]:
            country = a["short_name"]
        elif "locality" in a["types"]:
            city = a["short_name"]

    return {
        "data": {
            "name": place["name"],
            "formatted_address": place["formatted_address"],
            "country": country,
            "city": city,
            "lat": lat,
            "lng": lng,
        }
    }