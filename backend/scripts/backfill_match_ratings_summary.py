"""
Backfill script: copy finalScores, finalPotms, finalAwards (or not-computed reason)
from the ratings subcollection doc into a `ratings` map on the main match document.
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import firebase_admin
from firebase_admin import firestore
from src.models._ratings import ratings_ref


def backfill(db, dry_run=True):
    matches = db.collection("matches").get()
    print(f"Found {len(matches)} matches\n")

    updated = 0
    skipped_no_ratings = 0
    skipped_empty = 0
    already_has = 0

    for match_doc in matches:
        match_id = match_doc.id
        match_data = match_doc.to_dict()

        # skip if match already has a ratings summary
        if match_data.get("ratings"):
            already_has += 1
            continue

        # read ratings subcollection
        r_doc = ratings_ref(match_id, db).get()
        if not r_doc.exists:
            skipped_no_ratings += 1
            continue

        r_data = r_doc.to_dict()
        if not r_data:
            skipped_empty += 1
            continue

        # build the summary
        summary = {}

        # migrate scoresComputedAt -> ratings.computed_at
        if match_data.get("scoresComputedAt"):
            summary["computed_at"] = match_data["scoresComputedAt"]

        if "ratings_not_computed_reason" in r_data:
            summary["ratings_not_computed_reason"] = r_data["ratings_not_computed_reason"]
        elif "finalScores" in r_data:
            summary["finalScores"] = r_data["finalScores"]
            summary["finalPotms"] = r_data.get("finalPotms", [])
            summary["finalAwards"] = r_data.get("finalAwards", {})
            # compute voter counts from raw scores/awardVotes
            raw_scores = r_data.get("scores", {})
            voters = set()
            for raters in raw_scores.values():
                voters.update(raters.keys())
            summary["num_distinct_score_voters"] = len(voters)
            summary["num_distinct_award_voters"] = len(r_data.get("awardVotes", {}))
        else:
            # no final data yet, skip
            skipped_empty += 1
            continue

        print(f"  [UPDATE] {match_id}: {list(summary.keys())}")

        if not dry_run:
            db.collection("matches").document(match_id).update({"ratings": summary})

        updated += 1

    print(f"\nResults ({'DRY RUN' if dry_run else 'WRITE'}):")
    print(f"  Updated:          {updated}")
    print(f"  Already has:      {already_has}")
    print(f"  No ratings doc:   {skipped_no_ratings}")
    print(f"  Empty/no finals:  {skipped_empty}")
    print("Done.")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Backfill ratings summary from subcollection into match documents"
    )
    parser.add_argument(
        "--write", action="store_true",
        help="Actually write to Firestore (default is dry-run)",
    )
    args = parser.parse_args()

    firebase_admin.initialize_app()
    db = firestore.client()

    print(f"Mode: {'WRITE' if args.write else 'DRY RUN'}\n")
    backfill(db, dry_run=not args.write)
