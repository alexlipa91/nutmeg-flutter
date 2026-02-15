"""
Recompute all user stats from match history in a single pass:
  - num_matches_joined
  - scores.number_of_scored_games, scores.total_sum
  - potm_dates
  - record.num_win, record.num_draw, record.num_loss
  - last_date_scores (10 most recent)
  - played_with (set of all co-players)
  - organizer stats: users/{organizerId}/organizer/data -> players_joined

Skips test and cancelled matches.
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import firebase_admin
from firebase_admin import firestore
from collections import defaultdict
from src.models._ratings import ratings_ref


def _empty_stats():
    return {
        "num_matches_joined": 0,
        "num_scored_games": 0,
        "total_sum": 0.0,
        "potm_dates": {},  # {datetime: True}
        "num_win": 0,
        "num_draw": 0,
        "num_loss": 0,
        "date_scores": [],  # list of (datetime, score) – trimmed to 10 later
        "played_with": defaultdict(int),  # {user_id: count}
    }


def recompute(db, dry_run=True, only_user=None):
    user_stats = defaultdict(_empty_stats)
    # organizer_id -> {player_id: count}
    organizer_players = defaultdict(lambda: defaultdict(int))

    matches = db.collection("matches").get()
    print(f"Scanning {len(matches)} matches...\n")

    skipped = defaultdict(int)
    processed = 0

    for m in matches:
        data = m.to_dict()

        # -- organizer players (computed for ALL matches, not just rated) --
        organizer_id = data.get("organizerId")
        going_players = list((data.get("going") or {}).keys())

        if organizer_id:
            for pid in going_players:
                if pid != organizer_id:
                    organizer_players[organizer_id][pid] += 1

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

        if not going_players:
            skipped["no_going"] += 1
            continue

        match_date = data.get("dateTime")

        # -- num_matches_joined & played_with --
        for u in going_players:
            user_stats[u]["num_matches_joined"] += 1
            for other in going_players:
                if other != u:
                    user_stats[u]["played_with"][other] += 1

        # -- scores & potms (from ratings subcollection) --
        r_doc = ratings_ref(m.id, db).get()
        final_scores = {}
        potms = []
        if r_doc.exists:
            r_data = r_doc.to_dict() or {}
            final_scores = r_data.get("finalScores", {})
            potms = r_data.get("finalPotms", [])

        for uid, score in final_scores.items():
            if score:
                user_stats[uid]["num_scored_games"] += 1
                user_stats[uid]["total_sum"] += score
                if match_date:
                    user_stats[uid]["date_scores"].append((match_date, score))

        for uid in potms:
            if match_date:
                user_stats[uid]["potm_dates"][match_date] = True

        # -- win/draw/loss --
        match_score = data.get("score")
        if match_score and len(match_score) == 2:
            team_logic = "manual" if data.get("hasManualTeams", False) else "balanced"
            teams_data = data.get("teams", {}).get(team_logic, {}).get("players", {})
            team_a = teams_data.get("a", [])
            team_b = teams_data.get("b", [])

            if team_a or team_b:
                delta = match_score[0] - match_score[1]
                if delta > 0:
                    winners, losers, drawers = team_a, team_b, []
                elif delta == 0:
                    winners, losers, drawers = [], [], team_a + team_b
                else:
                    winners, losers, drawers = team_b, team_a, []

                for u in winners:
                    user_stats[u]["num_win"] += 1
                for u in losers:
                    user_stats[u]["num_loss"] += 1
                for u in drawers:
                    user_stats[u]["num_draw"] += 1

        processed += 1

    print(f"Processed {processed} rated matches")
    print(f"Skipped: {dict(skipped)}")
    print(f"Found stats for {len(user_stats)} users")
    print(f"Found {len(organizer_players)} organizers with players\n")

    # ---- write user stats ----

    if only_user:
        if only_user not in user_stats:
            print(f"User {only_user} has no stats from any match")
        else:
            _write_user_stats(db, {only_user: user_stats[only_user]}, dry_run)
        # also write organizer stats if this user is an organizer
        if only_user in organizer_players:
            _write_organizer_stats(db, {only_user: organizer_players[only_user]}, dry_run)
        elif not only_user in user_stats:
            pass  # already printed message
        return

    _write_user_stats(db, dict(user_stats), dry_run)
    _write_organizer_stats(db, dict(organizer_players), dry_run)


def _write_user_stats(db, users_to_process, dry_run):
    print(f"\n--- User stats ({len(users_to_process)} users) ---\n")
    changed_count = 0

    for uid, computed in users_to_process.items():
        user_doc = db.collection("users").document(uid).get()
        if not user_doc.exists:
            print(f"  [MISSING] {uid}: user doc not found, skipping")
            continue

        current = user_doc.to_dict()
        cur_record = current.get("record", {})
        cur_scores = current.get("scores", {})

        update = {}
        diffs = []

        # num_matches_joined
        cur_val = current.get("num_matches_joined", 0)
        if cur_val != computed["num_matches_joined"]:
            update["num_matches_joined"] = computed["num_matches_joined"]
            diffs.append(f"matches: {cur_val}->{computed['num_matches_joined']}")

        # scores
        cur_games = cur_scores.get("number_of_scored_games", 0)
        cur_sum = cur_scores.get("total_sum", 0)
        if cur_games != computed["num_scored_games"] or abs(cur_sum - computed["total_sum"]) > 0.001:
            update["scores"] = {
                "number_of_scored_games": computed["num_scored_games"],
                "total_sum": computed["total_sum"],
            }
            diffs.append(f"scored_games: {cur_games}->{computed['num_scored_games']}")
            diffs.append(f"total_sum: {cur_sum:.2f}->{computed['total_sum']:.2f}")

        # potm_dates
        new_potm_dates = {d.strftime("%Y%m%d%H%M%S"): True for d in computed["potm_dates"]}
        cur_potm_dates = current.get("potm_dates", {})
        if new_potm_dates != cur_potm_dates:
            update["potm_dates"] = new_potm_dates
            diffs.append(f"potm_dates: {len(cur_potm_dates)}->{len(new_potm_dates)}")

        # record
        new_record = {
            "num_win": computed["num_win"],
            "num_draw": computed["num_draw"],
            "num_loss": computed["num_loss"],
        }
        if (cur_record.get("num_win", 0) != new_record["num_win"]
                or cur_record.get("num_draw", 0) != new_record["num_draw"]
                or cur_record.get("num_loss", 0) != new_record["num_loss"]):
            update["record"] = new_record
            diffs.append(
                f"W/D/L: {cur_record.get('num_win',0)}/{cur_record.get('num_draw',0)}/{cur_record.get('num_loss',0)}"
                f"->{new_record['num_win']}/{new_record['num_draw']}/{new_record['num_loss']}"
            )

        # last_date_scores (10 most recent)
        date_scores = computed["date_scores"]
        date_scores.sort(key=lambda t: t[0], reverse=True)
        top_ten = date_scores[:10]
        new_last_date_scores = {d.strftime("%Y%m%d%H%M%S"): v for d, v in top_ten}
        cur_last_date_scores = current.get("last_date_scores", {})
        if new_last_date_scores != cur_last_date_scores:
            update["last_date_scores"] = new_last_date_scores
            diffs.append(f"last_date_scores: {len(cur_last_date_scores)} entries->{len(new_last_date_scores)} entries")

        # played_with
        new_played_with = dict(computed["played_with"])
        cur_played_with = current.get("played_with", {})
        if new_played_with != cur_played_with:
            update["played_with"] = new_played_with
            diffs.append(f"played_with: {len(cur_played_with)}->{len(new_played_with)} players")

        if update:
            changed_count += 1
            print(f"  [CHANGED] {uid}: {', '.join(diffs)}")
            if not dry_run:
                db.collection("users").document(uid).update(update)
        else:
            print(f"  [ok] {uid}")

    print(f"\n{'DRY RUN' if dry_run else 'WRITE'}: {changed_count} users with changes out of {len(users_to_process)}")


def _write_organizer_stats(db, organizers_to_process, dry_run):
    print(f"\n--- Organizer stats ({len(organizers_to_process)} organizers) ---\n")
    changed_count = 0

    for organizer_id, players in organizers_to_process.items():
        if not players:
            continue

        user_doc = db.collection("users").document(organizer_id).get()
        if not user_doc.exists:
            print(f"  [MISSING] {organizer_id}: user doc not found, skipping")
            continue

        existing_players = user_doc.to_dict().get("organizer_players", {})

        if dict(players) != existing_players:
            changed_count += 1
            print(f"  [CHANGED] {organizer_id}: {len(existing_players)} unique players -> {len(players)} unique players")
            if not dry_run:
                db.collection("users").document(organizer_id).update(
                    {"organizer_players": dict(players)}
                )
        else:
            print(f"  [ok] {organizer_id}: {len(players)} unique players")

    print(f"\n{'DRY RUN' if dry_run else 'WRITE'}: {changed_count} organizers with changes out of {len(organizers_to_process)}")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Recompute all user stats from match history")
    parser.add_argument("--write", action="store_true", help="Actually write (default is dry-run)")
    parser.add_argument("--user", help="Only recompute for a single user ID")
    args = parser.parse_args()

    firebase_admin.initialize_app()
    db = firestore.client()

    print(f"Mode: {'WRITE' if args.write else 'DRY RUN'}")
    if args.user:
        print(f"Filtering to user: {args.user}")
    print()

    recompute(db, dry_run=not args.write, only_user=args.user)
