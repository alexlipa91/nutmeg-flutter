"""
One-off script to backfill the `players_joined` map in
users/{organizerId}/organizer/data by scanning all matches.
Stores {player_id: count} for each organizer.
"""
import firebase_admin
from firebase_admin import firestore
from collections import defaultdict


def backfill_organizer_players(db, dry_run=True, only_organizer=None):
    # organizer_id -> {player_id: count}
    organizer_players = defaultdict(lambda: defaultdict(int))

    num_matches = 0

    for m in db.collection("matches").stream():
        num_matches += 1
        match_data = m.to_dict()

        organizer_id = match_data.get("organizerId")
        if not organizer_id:
            continue

        if only_organizer and organizer_id != only_organizer:
            continue

        going_players = match_data.get("goingPlayers", [])

        for player_id in going_players:
            if player_id != organizer_id:
                organizer_players[organizer_id][player_id] += 1

    print(f"Scanned {num_matches} matches")
    print(f"Found {len(organizer_players)} organizers with players")

    for organizer_id, players in organizer_players.items():
        if not players:
            continue

        sorted_players = sorted(players.items(), key=lambda x: x[1], reverse=True)
        print(f"  {organizer_id}: {len(players)} unique players")
        for pid, count in sorted_players[:5]:
            print(f"    {pid}: {count} matches")
        if len(sorted_players) > 5:
            print(f"    ... and {len(sorted_players) - 5} more")

        if not dry_run:
            doc_ref = (
                db.collection("users")
                .document(organizer_id)
                .collection("organizer")
                .document("data")
            )
            doc_ref.set({"players_joined": dict(players)}, merge=True)
            print(f"  -> written to Firestore")

    print("Done.")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Backfill organizer players_joined from match history"
    )
    parser.add_argument(
        "--write",
        action="store_true",
        help="Actually write to Firestore (default is dry-run)",
    )
    parser.add_argument(
        "--organizer",
        help="Only backfill for a single organizer user ID",
    )
    args = parser.parse_args()

    firebase_admin.initialize_app()
    db = firestore.client()

    backfill_organizer_players(
        db, dry_run=not args.write, only_organizer=args.organizer
    )
