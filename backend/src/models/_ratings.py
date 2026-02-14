"""Helpers for the ratings subcollection under matches."""

from google.cloud.firestore_v1.client import Client


def ratings_ref(match_id: str, db: Client):
    """Return a DocumentReference for matches/{matchId}/ratings/data."""
    return db.collection("matches").document(match_id).collection("ratings").document("data")
