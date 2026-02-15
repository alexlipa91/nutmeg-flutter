"""
Backfill potm_dates map on user documents.

Scans all rated matches, finds POTMs from the ratings subcollection,
and writes a potm_dates map (keyed by match date in YYYYMMDDHHMMSS format)
to each user doc.

This is additive only — no existing fields are dropped or modified.
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import firebase_admin
from firebase_admin import firestore
from collections import defaultdict
from src.models._ratings import ratings_ref


def backfill(db, dry_run=True, only_user=None):
    # user_id -> {date_str: True}
    user_potm_dates = defaultdict(dict)

    matches = db.collection("matches").get()
    print(f"Scanning {len(matches)} matches...\n")

    skipped = defaultdict(int)
    processed = 0

    for m in matches:
        data = m.to_dict()

        # skip test
        if data.get("isTest", False):
            skipped["test"] += 1
            continue

        # skip cancelled
        if data.get("cancelledAt"):
            skipped["cancelled"] += 1
            continue

        # skip unrated
        ratings_map = data.get("ratings", {}) or {}
        if not ratings_map.get("computed_at") and "scoresComputedAt" not in data:
            skipped["unrated"] += 1
            continue

        match_date = data.get("dateTime")
        if not match_date:
            skipped["no_date"] += 1
            continue

        date_key = match_date.strftime("%Y%m%d%H%M%S")

        # get POTMs from ratings subcollection
        r_doc = ratings_ref(m.id, db).get()
        if not r_doc.exists:
            skipped["no_ratings_doc"] += 1
            continue

        r_data = r_doc.to_dict() or {}
        potms = r_data.get("finalPotms", [])

        for uid in potms:
            user_potm_dates[uid][date_key] = True

        processed += 1

    print(f"Processed {processed} rated matches")
    print(f"Skipped: {dict(skipped)}")
    print(f"Found POTM dates for {len(user_potm_dates)} users\n")

    # filter to single user if requested
    if only_user:
        if only_user not in user_potm_dates:
            print(f"User {only_user} has no POTM dates from any match")
            return
        user_potm_dates = {only_user: user_potm_dates[only_user]}

    # write to user docs
    changed_count = 0
    for uid, potm_dates in user_potm_dates.items():
        user_doc = db.collection("users").document(uid).get()
        if not user_doc.exists:
            print(f"  [MISSING] {uid}: user doc not found, skipping")
            continue

        current = user_doc.to_dict()
        existing_potm_dates = current.get("potm_dates", {})

        # merge: add new dates on top of existing ones
        merged = dict(existing_potm_dates)
        merged.update(potm_dates)

        if merged != existing_potm_dates:
            changed_count += 1
            new_dates = set(merged.keys()) - set(existing_potm_dates.keys())
            print(f"  [UPDATE] {uid}: {len(existing_potm_dates)} -> {len(merged)} potm_dates (+{len(new_dates)} new)")
            if not dry_run:
                db.collection("users").document(uid).update({"potm_dates": merged})
        else:
            print(f"  [ok] {uid}: {len(merged)} potm_dates (no change)")

    print(f"\n{'DRY RUN' if dry_run else 'WRITE'}: {changed_count} users updated out of {len(user_potm_dates)}")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Backfill potm_dates map on user documents")
    parser.add_argument("--write", action="store_true", help="Actually write (default is dry-run)")
    parser.add_argument("--user", help="Only backfill for a single user ID")
    args = parser.parse_args()

    firebase_admin.initialize_app()
    db = firestore.client()

    print(f"Mode: {'WRITE' if args.write else 'DRY RUN'}")
    if args.user:
        print(f"Filtering to user: {args.user}")
    print()

    backfill(db, dry_run=not args.write, only_user=args.user)
