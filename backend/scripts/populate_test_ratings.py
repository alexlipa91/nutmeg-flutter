"""
Populate test ratings for a match. Each going player rates every other player
with a random score between 1 and 5.
"""

import sys, os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import random
import firebase_admin
from firebase_admin import firestore
from src.models._ratings import ratings_ref


def populate_ratings(db, match_id, dry_run=True):
    match_doc = db.collection("matches").document(match_id).get()
    if not match_doc.exists:
        print(f"Match {match_id} not found")
        return

    match_data = match_doc.to_dict()
    going = list((match_data.get("going") or {}).keys())

    if len(going) < 2:
        print(f"Not enough players ({len(going)}), need at least 2")
        return

    print(f"Match: {match_id}")
    print(f"Players ({len(going)}): {going}\n")

    awards = ["best_defender", "best_goal", "best_goalkeeper", "best_striker"]

    scores = {}
    skills = {}
    award_votes = {}

    for rater in going:
        # scores: rate every other player
        for rated in going:
            if rater == rated:
                continue
            score = random.randint(1, 5)

            if rated not in scores:
                scores[rated] = {}
            scores[rated][rater] = score

            if rated not in skills:
                skills[rated] = {}
            skills[rated][rater] = []

            print(f"  {rater} -> {rated}: {score}")

        # awards: vote a random other player for each award
        others = [p for p in going if p != rater]
        award_votes[rater] = {a: random.choice(others) for a in awards}
        print(f"  {rater} awards: {award_votes[rater]}")

    print(f"\nTotal ratings: {sum(len(v) for v in scores.values())}")
    print(f"Total award voters: {len(award_votes)}")

    if not dry_run:
        ratings_ref(match_id, db).set(
            {"scores": scores, "skills": skills, "awardVotes": award_votes},
            merge=True,
        )
        print("Written to Firestore.")
    else:
        print("DRY RUN - nothing written.")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Populate test ratings for a match")
    parser.add_argument("match_id", help="Firestore match document ID")
    parser.add_argument(
        "--write",
        action="store_true",
        help="Actually write to Firestore (default is dry-run)",
    )
    args = parser.parse_args()

    firebase_admin.initialize_app()
    db = firestore.client()

    print(f"Mode: {'WRITE' if args.write else 'DRY RUN'}\n")
    populate_ratings(db, args.match_id, dry_run=not args.write)
