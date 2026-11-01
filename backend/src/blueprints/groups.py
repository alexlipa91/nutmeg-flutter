import re

import flask
from flask import Blueprint, request
from flask import current_app as app
from google.cloud.firestore_v1.base_query import FieldFilter

from src import group_stats
from src.models._matches import Match

bp = Blueprint("groups", __name__, url_prefix="/groups")


def _matches_where(field, op, value):
    docs = (
        app.db_client.collection("matches")
        .where(filter=FieldFilter(field, op, value))
        .get()
    )
    return [Match.from_doc(d) for d in docs]


@bp.route("/<organizer_id>/monthly", methods=["GET"])
def get_monthly_group_stats(organizer_id):
    """
    Monthly performance of the players in an organizer's matches.
    `organizer_id` can be "mine": the group of the logged in user, i.e. the
    organizer of the matches they played most.
    """
    month = request.args.get("month")
    if month is not None and not re.fullmatch(r"\d{6}", month):
        return {"error": "month must be YYYYMM"}, 400

    if organizer_id == "mine":
        uid = flask.g.uid
        if not uid:
            return {"error": "login required"}, 401
        organizer_id = group_stats.most_played_organizer(
            _matches_where("goingPlayers", "array_contains", uid)
        )
        if organizer_id is None:
            return {"data": group_stats.monthly_group_stats([], month)}, 200

    matches = _matches_where("organizerId", "==", organizer_id)
    return {"data": group_stats.monthly_group_stats(matches, month)}, 200
