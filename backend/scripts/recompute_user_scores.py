"""
One-off script to recompute `scores.number_of_scored_games` and `scores.total_sum`
for every user by scanning all rated matches and their finalScores from ratings docs.
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import firebase_admin
from firebase_admin import firestore
from collections import defaultdict
from src.models._ratings import ratings_ref


def recompute_user_scores(db, dry_run=True, only_user=None):
    # user_id -> {"number_of_scored_games": int, "total_sum": float}
    user_scores = defaultdict(lambda: {"number_of_scored_games": 0, "total_sum": 0.0})

    matches = db.collection("matches").get()
    print(f"Scanning {len(matches)} matches...")

    skipped = {"no_scores_computed": 0, "cancelled": 0, "no_ratings_doc": 0, "no_final_scores": 0}
    processed = 0

    for m in matches:
        match_data = m.to_dict()

        # skip unrated or cancelled matches
        if "scoresComputedAt" not in match_data:
            skipped["no_scores_computed"] += 1
            continue
        if match_data.get("cancelledAt"):
            skipped["cancelled"] += 1
            continue

        # get finalScores from ratings doc
        ratings_doc = ratings_ref(m.id, db).get()
        if not ratings_doc.exists:
            skipped["no_ratings_doc"] += 1
            continue

        ratings_data = ratings_doc.to_dict()
        final_scores = ratings_data.get("finalScores")
        if not final_scores:
            skipped["no_final_scores"] += 1
            continue

        processed += 1

        for user_id, score in final_scores.items():
            if score:  # same check as UserUpdates.from_single_game: `1 if score else 0`
                user_scores[user_id]["number_of_scored_games"] += 1
                user_scores[user_id]["total_sum"] += score

    print(f"\nProcessed {processed} matches with finalScores")
    print(f"Skipped: {skipped}")
    print(f"Found scores for {len(user_scores)} users\n")

    if only_user:
        if only_user not in user_scores:
            print(f"User {only_user} has no scores from any match")
            user_doc = db.collection("users").document(only_user).get()
            if user_doc.exists:
                current = user_doc.to_dict().get("scores", {})
                print(f"  Current scores in DB: {current}")
            return
        users_to_process = {only_user: user_scores[only_user]}
    else:
        users_to_process = dict(user_scores)

    # show and optionally write updates
    for user_id, computed in users_to_process.items():
        user_doc = db.collection("users").document(user_id).get()
        current = {}
        if user_doc.exists:
            current = user_doc.to_dict().get("scores", {})

        current_games = current.get("number_of_scored_games", 0)
        current_sum = current.get("total_sum", 0)

        changed = (
            current_games != computed["number_of_scored_games"]
            or abs(current_sum - computed["total_sum"]) > 0.001
        )

        status = "CHANGED" if changed else "ok"
        print(
            f"  [{status}] {user_id}: "
            f"games: {current_games} -> {computed['number_of_scored_games']}, "
            f"total_sum: {current_sum:.2f} -> {computed['total_sum']:.2f}"
        )

        if not dry_run and changed:
            db.collection("users").document(user_id).update({"scores": computed})
            print(f"    -> written to Firestore")

    print("\nDone.")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Recompute user scores (number_of_scored_games, total_sum) from match history"
    )
    parser.add_argument(
        "--write",
        action="store_true",
        help="Actually write to Firestore (default is dry-run)",
    )
    parser.add_argument(
        "--user", help="Only recompute for a single user ID"
    )
    args = parser.parse_args()

    firebase_admin.initialize_app()
    db = firestore.client()

    print(f"Mode: {'WRITE' if args.write else 'DRY RUN'}")
    if args.user:
        print(f"Filtering to user: {args.user}")
    print()

    recompute_user_scores(db, dry_run=not args.write, only_user=args.user)
