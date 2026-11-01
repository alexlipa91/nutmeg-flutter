"""
Rebuild the `pair_stats` collection from match history (frozen, scored,
non-test, non-cancelled matches) and mark those matches as applied.

Writes absolute values (not increments), so it can be re-run safely.
Dry run by default:

    python scripts/backfill_pair_stats.py            # dry run
    python scripts/backfill_pair_stats.py --apply    # write
"""
import sys, os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import firebase_admin
from firebase_admin import firestore

from src.models._matches import Match
from src.pair_stats import (
    PAIR_STATS_COLLECTION,
    match_is_frozen,
    pair_results_for_match,
)


def backfill(db, apply=False):
    totals = {}
    last_played = {}
    applied_matches = []

    docs = db.collection("matches").get()
    print(f"Scanning {len(docs)} matches...")
    for doc in docs:
        match = Match.from_doc(doc)
        if not match or not match_is_frozen(match):
            continue
        results = pair_results_for_match(match)
        if not results:
            continue
        applied_matches.append(doc.reference)
        for key, counters in results.items():
            acc = totals.setdefault(key, {"users": counters["users"]})
            for field, value in counters.items():
                if field != "users":
                    acc[field] = acc.get(field, 0) + value
            if match.date_time and (
                key not in last_played or match.date_time > last_played[key]
            ):
                last_played[key] = match.date_time

    print(f"{len(applied_matches)} matches -> {len(totals)} pairs")
    top = sorted(totals.values(), key=lambda s: s["together"], reverse=True)[:5]
    for s in top:
        print("  top together:", s)

    if not apply:
        print("Dry run, nothing written. Pass --apply to write.")
        return

    batch = db.batch()
    n = 0
    for key, acc in totals.items():
        acc["last_played"] = last_played.get(key)
        batch.set(db.collection(PAIR_STATS_COLLECTION).document(key), acc)
        n += 1
        if n % 400 == 0:
            batch.commit()
            batch = db.batch()
    batch.commit()

    batch = db.batch()
    for i, ref in enumerate(applied_matches, 1):
        batch.update(ref, {"pairStatsAppliedAt": firestore.SERVER_TIMESTAMP})
        if i % 400 == 0:
            batch.commit()
            batch = db.batch()
    batch.commit()
    print(f"Wrote {len(totals)} pair docs, marked {len(applied_matches)} matches.")


if __name__ == "__main__":
    try:
        firebase_admin.get_app()
    except ValueError:
        firebase_admin.initialize_app()
    backfill(firestore.client(), apply="--apply" in sys.argv)
