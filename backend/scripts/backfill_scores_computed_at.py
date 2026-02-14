"""
Backfill script: copy scoresComputedAt into ratings.computed_at
for all matches that have the old field but not the new one.
"""
import firebase_admin
from firebase_admin import firestore


def backfill(db, dry_run=True):
    matches = db.collection("matches").get()
    print(f"Found {len(matches)} matches\n")

    migrated = 0
    skipped_no_old = 0
    skipped_already = 0

    for match_doc in matches:
        match_id = match_doc.id
        data = match_doc.to_dict()

        old_val = data.get("scoresComputedAt")
        if not old_val:
            skipped_no_old += 1
            continue

        ratings_map = data.get("ratings", {}) or {}
        if ratings_map.get("computed_at"):
            skipped_already += 1
            continue

        print(f"  [MIGRATE] {match_id}: scoresComputedAt={old_val}")

        if not dry_run:
            db.collection("matches").document(match_id).update({
                "ratings.computed_at": old_val,
            })

        migrated += 1

    print(f"\nResults ({'DRY RUN' if dry_run else 'WRITE'}):")
    print(f"  Migrated:       {migrated}")
    print(f"  Already done:   {skipped_already}")
    print(f"  No old field:   {skipped_no_old}")
    print("Done.")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Backfill scoresComputedAt -> ratings.computed_at"
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
