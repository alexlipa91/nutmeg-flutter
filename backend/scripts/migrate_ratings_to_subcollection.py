"""
Migration script: copy ratings from top-level `ratings/{matchId}`
to subcollection `matches/{matchId}/ratings/data`.

Safe to run multiple times -- skips matches that already have the new doc.
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import firebase_admin
from firebase_admin import firestore
from src.models._ratings import ratings_ref


def migrate_ratings(db, dry_run=True):
    old_ratings = db.collection("ratings").get()
    print(f"Found {len(old_ratings)} documents in ratings/ collection\n")

    migrated = 0
    skipped_empty = 0
    skipped_already_exists = 0

    for doc in old_ratings:
        match_id = doc.id
        data = doc.to_dict()

        if not data:
            skipped_empty += 1
            continue

        # check if match doc exists
        match_doc = db.collection("matches").document(match_id).get()
        if not match_doc.exists:
            print(f"  [SKIP] {match_id}: match document doesn't exist")
            skipped_empty += 1
            continue

        # check if already migrated
        new_ref = ratings_ref(match_id, db)
        new_doc = new_ref.get()
        if new_doc.exists:
            skipped_already_exists += 1
            continue

        print(f"  [MIGRATE] {match_id}: {len(data)} top-level fields")

        if not dry_run:
            new_ref.set(data)
            migrated += 1
        else:
            migrated += 1

    print(f"\nResults ({'DRY RUN' if dry_run else 'WRITE'}):")
    print(f"  Migrated:         {migrated}")
    print(f"  Already existed:  {skipped_already_exists}")
    print(f"  Skipped (empty):  {skipped_empty}")
    print("Done.")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Migrate ratings from ratings/{matchId} to matches/{matchId}/ratings/data"
    )
    parser.add_argument(
        "--write", action="store_true",
        help="Actually write to Firestore (default is dry-run)",
    )
    args = parser.parse_args()

    firebase_admin.initialize_app()
    db = firestore.client()

    print(f"Mode: {'WRITE' if args.write else 'DRY RUN'}")
    print()

    migrate_ratings(db, dry_run=not args.write)
