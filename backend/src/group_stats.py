"""
Monthly performance of a group of players (everyone who played in the matches
of one organizer): who won/lost the most, best average rating, strongest
chemistry and repeated awards.

Pure functions over Match objects, so they can be tested without Firestore.
"""
from __future__ import annotations

import math
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Tuple

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


# --- Ranking score -----------------------------------------------------------
#
# A player's score is 60% wins and 40% match rating, shown as a FIFA-like card
# number. Wins count every game; ratings only come from rated games.
WINS_WEIGHT = 0.6
RATING_WEIGHT = 0.4
# Rating used for a player with no rated game at all.
NEUTRAL_RATING = 3.0
# Games of rating history used when a month is not fully rated.
HISTORY_GAMES = 5

# A month is scored on the absolute scale: 0 points is 50 and 100 points is 99.
CARD_FLOOR = 50
CARD_SPAN = 0.49

# --- A year or all time ------------------------------------------------------
#
# Over many games everyone drifts towards the average, so on the absolute scale
# above all scores sit in a narrow band (about 70-85 in our group) and the weak
# players don't look weak. Three choices keep the long tables readable:
#
# 1. Few games count for less. A player is treated as having also played
#    SHRINK_GAMES average games (and SHRINK_RATED average rated ones), so one
#    good game cannot beat a long record.
# 2. A player needs a share of what a regular has played, never less than
#    MIN_GAMES_FLOOR games, to be ranked at all (see `ranking`).
# 3. The score is computed on FIXED RANGES: each part is stretched so that the
#    results people really get fill its 0-100, instead of using the whole
#    0-100 for results nobody reaches. A win rate of LONG_WINS_RANGE[0] or less
#    counts as 0 and LONG_WINS_RANGE[1] or more as 100; the same for the average
#    rating with LONG_RATING_RANGE. The result goes on a card scale of
#    LONG_CARD_FLOOR..LONG_CARD_TOP.
#
# Why fixed ranges and not "compare each player with the group" (a z-score
# around the group average): that would work too, but a player's number would
# then depend on who else is in the table, and the same results would give a
# different score next month. With fixed ranges a score depends only on the
# player's own wins and ratings, and means the same on every tab and over time.
#
# The ranges are a judgement call, set from our group's all-time records, where
# regular players' win rates run from about 30% to 70% and their average
# ratings from about 2.5 to 4 stars; with them the weakest regulars land at
# 60-65 and the best around 90. If the group changes a lot (a much stronger or
# weaker league), revisit these numbers.
SHRINK_GAMES = 5
SHRINK_RATED = 3
MIN_GAMES_SHARE = 0.3
MIN_GAMES_FLOOR = 4
REGULAR_PERCENTILE = 0.75
LONG_WINS_RANGE = (20.0, 70.0)  # win rate in percent: counts as 0 and as 100
LONG_RATING_RANGE = (2.0, 4.2)  # average rating: counts as 0 and as 100
LONG_CARD_FLOOR = 40
LONG_CARD_TOP = 95


def card_score(avg_rating: float, wins: float, draws: float, played: float) -> int:
    """Score of a month, on the absolute scale."""
    rating_part = (avg_rating - 1) / 4 * 100
    wins_part = (wins + 0.5 * draws) / played * 100
    points = WINS_WEIGHT * wins_part + RATING_WEIGHT * rating_part
    return int(CARD_FLOOR + CARD_SPAN * points + 0.5)


def _stretch(value: float, low_high: Tuple[float, float]) -> float:
    """0-100 between `low` (or less) and `high` (or more)."""
    low, high = low_high
    return max(0.0, min(1.0, (value - low) / (high - low))) * 100


def long_period_score(avg_rating: float, wins: float, played: float) -> int:
    """Score of a year or all time, on the fixed ranges (see above). `wins` is
    the number of wins, a draw being half a win."""
    wins_part = _stretch(wins / played * 100, LONG_WINS_RANGE)
    rating_part = _stretch(avg_rating, LONG_RATING_RANGE)
    points = WINS_WEIGHT * wins_part + RATING_WEIGHT * rating_part
    return int(LONG_CARD_FLOOR + (LONG_CARD_TOP - LONG_CARD_FLOOR) * points / 100 + 0.5)


def _recent_rating(history: Optional[Dict[str, float]], month: str) -> float:
    """Average of the last HISTORY_GAMES rated games up to `month`.
    `history` maps a game date (yyyyMMdd...) to the player's rating."""
    scores = [v for k, v in sorted((history or {}).items()) if k[:6] <= month]
    recent = scores[-HISTORY_GAMES:]
    return sum(recent) / len(recent) if recent else NEUTRAL_RATING


def _is_month(period: str) -> bool:
    return bool(period) and len(period) == 6


def _in_period(match: Match, period: str) -> bool:
    """`period` is a month (yyyymm), a year (yyyy) or "all"."""
    if period == "all":
        return True
    return month_of(match).startswith(period)


def _period_end(period: str) -> str:
    """Last month (yyyymm) of the period."""
    if period == "all":
        return "999999"
    return period if _is_month(period) else period + "12"


def _percentile(values: List[int], q: float) -> int:
    """Nearest-rank percentile."""
    ordered = sorted(values)
    return ordered[max(0, math.ceil(q * len(ordered)) - 1)]


def ranking(
    matches: List[Match],
    period: str,
    history: Optional[Dict[str, Dict[str, float]]] = None,
) -> Tuple[List[Dict[str, Any]], str, int]:
    """
    Players ranked by card score over the period's matches, where the ratings
    came from ("month", "last_games" or, for a year or everything, "period")
    and the minimum number of games to be ranked. Wins and losses count every
    game; ratings only come from rated games (ratings computed).
    For a month: if every player has a rated game, the month's ratings are
    used; otherwise everyone's last rated games (`history`: user -> {date:
    rating}); no minimum. For a longer period each player's rated games in it
    are used (the last rated games only for a player with none), results and
    ratings are pulled towards the middle for players with few games, players
    below the minimum are left out, and the score uses fixed ranges (see the
    notes above `SHRINK_GAMES`).
    Best score first, ties on wins then rating.
    """
    acc: Dict[str, Dict[str, Any]] = {}
    for m in matches:
        scores = (m.ratings_summary or {}).get("finalScores") or {}
        team_a, team_b = m.get_team_players()
        for uid in team_a + team_b:
            if is_guest(uid):
                continue
            p = acc.setdefault(
                uid,
                {"played": 0, "wins": 0, "draws": 0, "rating_sum": 0.0, "rated": 0},
            )
            p["played"] += 1
            result = result_for_user(m, uid)
            if result == "w":
                p["wins"] += 1
            elif result == "d":
                p["draws"] += 1
            if scores.get(uid) is not None:
                p["rating_sum"] += scores[uid]
                p["rated"] += 1

    long_period = not _is_month(period)
    min_games = 0
    if long_period and acc:
        regular = _percentile([p["played"] for p in acc.values()], REGULAR_PERCENTILE)
        min_games = max(MIN_GAMES_FLOOR, int(MIN_GAMES_SHARE * regular + 0.5))

    month_is_rated = bool(acc) and all(p["rated"] for p in acc.values())
    use_period = month_is_rated if _is_month(period) else True
    table = []
    for uid, p in acc.items():
        if p["played"] < min_games:
            continue
        if use_period and p["rated"]:
            avg = p["rating_sum"] / p["rated"]
        else:
            avg = _recent_rating((history or {}).get(uid), _period_end(period))
        if long_period:
            rated_avg = avg
            if p["rated"]:
                rated_avg = (p["rating_sum"] + SHRINK_RATED * NEUTRAL_RATING) / (
                    p["rated"] + SHRINK_RATED
                )
            score = long_period_score(
                rated_avg,
                p["wins"] + 0.5 * p["draws"] + SHRINK_GAMES * 0.5,
                p["played"] + SHRINK_GAMES,
            )
        else:
            score = card_score(avg, p["wins"], p["draws"], p["played"])
        table.append({
            "user_id": uid,
            "played": p["played"],
            "wins": p["wins"],
            "avg_rating": round(avg, 2),
            "score": score,
        })
    table.sort(key=lambda e: (-e["score"], -e["wins"], -e["avg_rating"]))
    if long_period:
        return table, "period", min_games
    return table, "month" if month_is_rated else "last_games", 0


def best_improver(
    current: List[Dict[str, Any]], previous: List[Dict[str, Any]]
) -> Optional[Dict[str, Any]]:
    """The player whose score rose the most since the previous month, among
    players ranked in both; ties go to the higher score. None if nobody rose."""
    before = {e["user_id"]: e["score"] for e in previous}
    gains = [
        {
            "user_id": e["user_id"],
            "score": e["score"],
            "previous_score": before[e["user_id"]],
            "change": e["score"] - before[e["user_id"]],
        }
        for e in current
        if e["user_id"] in before and e["score"] > before[e["user_id"]]
    ]
    return max(gains, key=lambda g: (g["change"], g["score"]), default=None)


def monthly_group_stats(
    matches: List[Match],
    month: Optional[str] = None,
    history: Optional[Dict[str, Dict[str, float]]] = None,
) -> Dict[str, Any]:
    eligible = [m for m in matches if m and _eligible(m)]
    months = sorted({month_of(m) for m in eligible}, reverse=True)
    if month is None and months:
        month = months[0]
    in_month = [m for m in eligible if month and _in_period(m, month)]

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
    ranked, ranking_source, min_games = ranking(in_month, month, history)
    # improvement only makes sense month over month
    previous_month = next(
        (x for x in months if month and _is_month(month) and x < month), None
    )
    previous_ranked, _, _ = ranking(
        [m for m in eligible if month_of(m) == previous_month],
        previous_month,
        history,
    ) if previous_month else ([], "", 0)
    if previous_month:
        before = {e["user_id"]: e["score"] for e in previous_ranked}
        for e in ranked:
            e["change"] = (
                e["score"] - before[e["user_id"]] if e["user_id"] in before else None
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
        "ranking": ranked,
        "ranking_source": ranking_source,
        "ranking_min_games": min_games,
        "best_improver": best_improver(ranked, previous_ranked),
    }
