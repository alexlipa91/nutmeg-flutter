"""
One-off script to recompute `record` (num_win, num_loss, num_draw) for every user
by scanning all rated matches and recalculating from match scores and team assignments.
"""
import firebase_admin
from firebase_admin import firestore
from collections import defaultdict


def recompute_user_record(db, dry_run=True, only_user=None):
    # user_id -> {"num_win": int, "num_loss": int, "num_draw": int}
    user_record = defaultdict(lambda: {"num_win": 0, "num_loss": 0, "num_draw": 0})

    matches = db.collection("matches").get()
    print(f"Scanning {len(matches)} matches...")

    skipped = {"no_scores_computed": 0, "cancelled": 0, "no_score": 0, "no_teams": 0}
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

        # need a match score to determine W/D/L
        if "score" not in match_data or len(match_data.get("score", [])) != 2:
            skipped["no_score"] += 1
            continue

        # determine team assignment
        team_logic = "manual" if match_data.get("hasManualTeams", False) else "balanced"
        teams_data = match_data.get("teams", {}).get(team_logic, {}).get("players", {})
        team_a = teams_data.get("a", [])
        team_b = teams_data.get("b", [])

        if not team_a and not team_b:
            skipped["no_teams"] += 1
            continue

        # determine outcome
        score_delta = match_data["score"][0] - match_data["score"][1]

        if score_delta > 0:
            winners = team_a
            losers = team_b
            drawers = []
        elif score_delta == 0:
            winners = []
            losers = []
            drawers = team_a + team_b
        else:
            winners = team_b
            losers = team_a
            drawers = []

        processed += 1

        for u in winners:
            user_record[u]["num_win"] += 1
        for u in losers:
            user_record[u]["num_loss"] += 1
        for u in drawers:
            user_record[u]["num_draw"] += 1

    print(f"\nProcessed {processed} matches with scores")
    print(f"Skipped: {skipped}")
    print(f"Found records for {len(user_record)} users\n")

    if only_user:
        if only_user not in user_record:
            print(f"User {only_user} has no W/D/L record from any match")
            # still show current value
            user_doc = db.collection("users").document(only_user).get()
            if user_doc.exists:
                current = user_doc.to_dict().get("record", {})
                print(f"  Current record in DB: {current}")
            return
        users_to_process = {only_user: user_record[only_user]}
    else:
        users_to_process = dict(user_record)

    # show and optionally write updates
    for user_id, record in users_to_process.items():
        # fetch current values for comparison
        user_doc = db.collection("users").document(user_id).get()
        current = {}
        if user_doc.exists:
            current = user_doc.to_dict().get("record", {})

        changed = (
            current.get("num_win", 0) != record["num_win"]
            or current.get("num_loss", 0) != record["num_loss"]
            or current.get("num_draw", 0) != record["num_draw"]
        )

        status = "CHANGED" if changed else "ok"
        print(
            f"  [{status}] {user_id}: "
            f"current={current} -> computed={record}"
        )

        if not dry_run and changed:
            db.collection("users").document(user_id).update({"record": record})
            print(f"    -> written to Firestore")

    print("\nDone.")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Recompute user W/D/L record from match history"
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

    recompute_user_record(db, dry_run=not args.write, only_user=args.user)
