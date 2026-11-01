"""
Monthly performance of a group of players (everyone who played in the matches
of one organizer): who won/lost the most, best average rating, strongest
chemistry and repeated awards.

Pure functions over Match objects, so they can be tested without Firestore.
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

import pytz

from src.models._matches import Match
from src.pair_stats import is_guest, match_has_result, pair_results_for_match
from src.player_form import result_for_user

LOCAL_TZ = pytz.timezone("Europe/Madrid")
# A pair needs this many games together and this win rate to count as chemistry.
CHEMISTRY_MIN_GAMES = 2
CHEMISTRY_MIN_WIN_RATE = 0.75


# Only matches this recent count when picking a user's group, so moving to a
# new group is picked up; with nothing recent, all-time is used.
RECENT_DAYS = 90


def most_played_organizer(
    matches: List[Match], now: Optional[datetime] = None
) -> Optional[str]:
    """
    The organizer whose matches appear most in `matches` (a user's matches):
    that is the user's group. Looks at the last RECENT_DAYS first, then falls
    back to all-time.
    """
    cutoff = (now or datetime.now(timezone.utc)) - timedelta(days=RECENT_DAYS)
    recent = [m for m in matches if m and m.date_time and m.date_time >= cutoff]
    return _most_played_organizer(recent) or _most_played_organizer(matches)


def _most_played_organizer(matches: List[Match]) -> Optional[str]:
    """Organizer with most (non cancelled, non test) matches; ties go to the
    one with the most recent match."""
    counts: Dict[str, List[Any]] = {}  # organizer -> [count, latest date]
    for m in matches:
        if not m or not m.organizer_id or m.is_test or m.is_cancelled():
            continue
        c = counts.setdefault(m.organizer_id, [0, None])
        c[0] += 1
        if m.date_time and (c[1] is None or m.date_time > c[1]):
            c[1] = m.date_time
    if not counts:
        return None
    epoch = datetime.min.replace(tzinfo=timezone.utc)
    return max(counts, key=lambda o: (counts[o][0], counts[o][1] or epoch))


def month_of(match: Match) -> str:
    return match.date_time.astimezone(LOCAL_TZ).strftime("%Y%m")


def _eligible(match: Match) -> bool:
    team_a, team_b = match.get_team_players()
    return bool(
        match.date_time and match_has_result(match) and team_a and team_b
    )


def _award_winners(final_awards: Dict[str, Dict[str, int]]) -> Dict[str, List[str]]:
    """award_id -> users with the most votes (ties share the award)."""
    winners = {}
    for award_id, votes in (final_awards or {}).items():
        votes = {u: n for u, n in (votes or {}).items() if n}
        if votes:
            top = max(votes.values())
            winners[award_id] = [u for u, n in votes.items() if n == top]
    return winners


def _top(entries: List[Dict[str, Any]], key: str):
    """All entries tied for the best value of `key` (list is pre-sorted)."""
    if not entries:
        return []
    best = entries[0][key]
    return [e for e in entries if e[key] == best]


def player_of_the_month(
    table: List[Dict[str, Any]],
    rated: List[Dict[str, Any]],
    top_wins: int,
) -> List[Dict[str, Any]]:
    """
    Players ranked by a combined score where wins and rating count equally:
    wins / the month's most wins + avg_rating / the best eligible rating.
    A player leading both scores close to 2. Only players with a rating
    (`rated`, already filtered to enough rated games) are eligible.
    Ties break on rating, then wins. Returns the top 3.
    """
    if not rated:
        return []
    best_rating = max(e["avg_rating"] for e in rated)

    def score(e):
        wins_part = e["wins"] / top_wins if top_wins else 0.0
        return round(wins_part + e["avg_rating"] / best_rating, 4)

    ranked = sorted(
        rated, key=lambda e: (-score(e), -e["avg_rating"], -e["wins"])
    )
    return [
        {
            **e,
            "score": score(e),
            "most_wins": top_wins > 0 and e["wins"] == top_wins,
            "best_rated": e["avg_rating"] == best_rating,
        }
        for e in ranked[:3]
    ]


def monthly_group_stats(
    matches: List[Match], month: Optional[str] = None
) -> Dict[str, Any]:
    eligible = [m for m in matches if m and _eligible(m)]
    months = sorted({month_of(m) for m in eligible}, reverse=True)
    if month is None and months:
        month = months[0]
    in_month = [m for m in eligible if month_of(m) == month]

    players: Dict[str, Dict[str, Any]] = {}
    pairs: Dict[str, Dict[str, Any]] = {}
    awards_won: Dict[str, Dict[str, int]] = {}  # award_id -> user -> times

    for m in in_month:
        summary = m.ratings_summary or {}
        scores = summary.get("finalScores") or {}
        team_a, team_b = m.get_team_players()
        for uid in team_a + team_b:
            if is_guest(uid):
                continue
            p = players.setdefault(
                uid,
                {"user_id": uid, "played": 0, "wins": 0, "draws": 0, "losses": 0,
                 "rating_sum": 0.0, "rated_games": 0},
            )
            p["played"] += 1
            result = result_for_user(m, uid)
            if result:
                p[{"w": "wins", "d": "draws", "l": "losses"}[result]] += 1
            if scores.get(uid) is not None:
                p["rating_sum"] += scores[uid]
                p["rated_games"] += 1

        for key, c in pair_results_for_match(m).items():
            acc = pairs.setdefault(key, {"users": c["users"], "together": 0,
                                         "wins": 0, "draws": 0, "losses": 0})
            acc["together"] += c["together"]
            acc["wins"] += c["together_wins"]
            acc["draws"] += c["together_draws"]
            acc["losses"] += c["together_losses"]

        for award_id, winners in _award_winners(summary.get("finalAwards")).items():
            for uid in winners:
                if not is_guest(uid):
                    counts = awards_won.setdefault(award_id, {})
                    counts[uid] = counts.get(uid, 0) + 1

    table = []
    for p in players.values():
        rated = p["rated_games"]
        table.append({
            "user_id": p["user_id"],
            "played": p["played"],
            "wins": p["wins"],
            "draws": p["draws"],
            "losses": p["losses"],
            "win_rate": round(p["wins"] / p["played"], 3),
            "rated_games": rated,
            "avg_rating": round(p["rating_sum"] / rated, 2) if rated else None,
        })

    by_wins = sorted(table, key=lambda e: (-e["wins"], -e["win_rate"], e["played"]))
    by_losses = sorted(table, key=lambda e: (-e["losses"], e["win_rate"]))
    # Prefer 2+ rated games for a rating ranking, but if nobody has that many
    # (recent matches are not rated yet), rank on what exists.
    max_rated = max((e["rated_games"] for e in table), default=0)
    min_games = 2 if max_rated >= 2 else 1
    rated = sorted(
        (e for e in table if e["avg_rating"] is not None and e["rated_games"] >= min_games),
        key=lambda e: (-e["avg_rating"], -e["rated_games"]),
    )

    chemistry = None
    candidates = [
        p for p in pairs.values()
        if p["together"] >= CHEMISTRY_MIN_GAMES
        and p["wins"] / p["together"] >= CHEMISTRY_MIN_WIN_RATE
    ]
    if candidates:
        chemistry = max(
            candidates,
            key=lambda p: (p["wins"] / p["together"], p["together"]),
        )

    repeat_awards = sorted(
        (
            {"award": award_id, "user_id": uid, "times": n}
            for award_id, counts in awards_won.items()
            for uid, n in counts.items()
            if n >= 2
        ),
        key=lambda a: (-a["times"], a["award"]),
    )

    podium = player_of_the_month(
        table, rated, by_wins[0]["wins"] if by_wins else 0
    )

    return {
        "month": month,
        "available_months": months,
        "matches": len(in_month),
        "player_of_the_month": podium[0] if podium else None,
        "runners_up": podium[1:],
        "highlights": {
            "most_wins": _top([e for e in by_wins if e["wins"] > 0], "wins"),
            "best_rating": _top(rated, "avg_rating"),
            "most_losses": _top([e for e in by_losses if e["losses"] > 0], "losses"),
            "chemistry": chemistry,
            "repeat_awards": repeat_awards,
        },
        "players": by_wins,
    }
