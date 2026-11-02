"""
One-off push notification: tell players to check the new cards and leaderboards.

Sent only to players who opened the app recently and run a version that has the
cards: on iOS/Android the stored build number must be >= --min-build, the web
app is always the latest. Opening the notification goes to the leaderboard.

Dry run by default.
"""
import sys, os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from datetime import datetime, timedelta, timezone

import firebase_admin
from firebase_admin import firestore

from src.utils import send_notification_to_users

TITLE = "New: player cards \U0001f0cf"
BODY = "Check the new cards and the leaderboards."


def _build(app_info):
    # "1.2.10+384" -> 384
    try:
        return int(str(app_info.get("app_version", "")).split("+")[1])
    except (IndexError, ValueError):
        return 0


def _parse(ts):
    try:
        return datetime.fromisoformat(str(ts).replace("Z", "+00:00"))
    except ValueError:
        return None


def eligible_users(db, min_build, active_days):
    since = datetime.now(timezone.utc) - timedelta(days=active_days)
    users = []
    for doc in db.collection("users").stream():
        d = doc.to_dict()
        if not d.get("tokens"):
            continue
        for platform, info in (d.get("app_info") or {}).items():
            seen = _parse(info.get("last_updated"))
            if not seen or seen < since:
                continue
            if platform == "web" or (
                platform in ("ios", "android") and _build(info) >= min_build
            ):
                users.append(doc.id)
                break
    return users


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--min-build", type=int, required=True,
                        help="Lowest iOS/Android build number that has the cards")
    parser.add_argument("--active-days", type=int, default=60)
    parser.add_argument("--user", help="Only send to this user ID (to test)")
    parser.add_argument("--send", action="store_true",
                        help="Actually send (default is dry-run)")
    args = parser.parse_args()

    firebase_admin.initialize_app()
    db = firestore.client()

    users = [args.user] if args.user else eligible_users(
        db, args.min_build, args.active_days)
    print(f"{'SEND' if args.send else 'DRY RUN'}: {len(users)} users")
    if args.send:
        send_notification_to_users(
            db, TITLE, BODY,
            {"click_action": "FLUTTER_NOTIFICATION_CLICK", "route": "/leaderboard"},
            users,
        )
