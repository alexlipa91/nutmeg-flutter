"""
One-off script to recompute `last_date_scores` for every user
by scanning all rated matches and keeping the 10 most recent scores.
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import firebase_admin
from firebase_admin import firestore
from flask import Flask
from collections import defaultdict
from src.models._ratings import ratings_ref


def recompute_last_date_scores(db, dry_run=True, only_user=None):
    # user_id -> list of (datetime, score)
    user_scores = defaultdict(list)

    matches = db.collection("matches").get()
    print(f"Scanning {len(matches)} matches...")

    for m in matches:
        match_data = m.to_dict()

        # skip unrated or cancelled matches
        ratings_map = match_data.get("ratings", {}) or {}
        if not ratings_map.get("computed_at") and "scoresComputedAt" not in match_data:
            continue
        if match_data.get("cancelledAt"):
            continue

        match_date = match_data.get("dateTime")
        if not match_date:
            continue

        # get final scores from ratings doc
        ratings_doc = ratings_ref(m.id, db).get()
        ratings_data = ratings_doc.to_dict() if ratings_doc.exists else None
        if not ratings_data or "finalScores" not in ratings_data:
            continue

        final_scores = ratings_data["finalScores"]

        for user_id, score in final_scores.items():
            if score:
                user_scores[user_id].append((match_date, score))

    print(f"Found scores for {len(user_scores)} users")

    if only_user:
        if only_user not in user_scores:
            print(f"User {only_user} has no scores")
            return
        users_to_process = {only_user: user_scores[only_user]}
    else:
        users_to_process = user_scores

    # for each user, keep the 10 most recent scores and write to Firestore
    for user_id, scores in users_to_process.items():
        scores.sort(key=lambda t: t[0], reverse=True)
        top_ten = scores[:10]
        last_date_scores = {
            d.strftime("%Y%m%d%H%M%S"): v for d, v in top_ten
        }

        print(f"  {user_id}: {last_date_scores}")
        if not dry_run:
            db.collection("users").document(user_id).update(
                {"last_date_scores": last_date_scores}
            )
            print(f"  -> written to Firestore")

    print("Done.")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--write", action="store_true",
        help="Actually write to Firestore (default is dry-run)"
    )
    parser.add_argument(
        "--user",
        help="Only recompute for a single user ID"
    )
    args = parser.parse_args()

    firebase_admin.initialize_app()
    db = firestore.client()

    recompute_last_date_scores(db, dry_run=not args.write, only_user=args.user)
