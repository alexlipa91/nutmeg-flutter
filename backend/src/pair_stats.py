"""
Pairwise player stats: how often two players play together / against each
other and what the results were.

One doc per pair in `pair_stats/{uidLo}_{uidHi}` (uids sorted). Updated once
per match when its stats are frozen; `scripts/backfill_pair_stats.py` rebuilds
the whole collection from match history.
"""
from __future__ import annotations

from itertools import combinations
from typing import Any, Dict, Iterable, List, Optional, Tuple

from firebase_admin import firestore

from src.models._matches import Match

PAIR_STATS_COLLECTION = "pair_stats"
# Minimum games before a pair shows up in a preview.
MIN_GAMES_FOR_CLAIM = 3


def is_guest(user_id: str) -> bool:
    return user_id.startswith("guest_")


def sorted_pair(a: str, b: str) -> Tuple[str, str]:
    return (a, b) if a <= b else (b, a)


def pair_key(a: str, b: str) -> str:
    return "{}_{}".format(*sorted_pair(a, b))


def match_has_result(match: Match) -> bool:
    """Scored, real (non-test) and not cancelled."""
    return not (
        match.is_test or match.is_cancelled() or match.get_score_delta() is None
    )


def match_is_frozen(match: Match) -> bool:
    """Stats already frozen: used by the backfill to mirror live behaviour."""
    return match_has_result(match) and bool(
        match.scores_computed_at or (match.ratings_summary or {}).get("computed_at")
    )


def pair_results_for_match(match: Match) -> Dict[str, Dict[str, Any]]:
    """
    Per-pair counters contributed by one match, keyed by pair key.
    Guests are skipped (their ids are not stable across games).
    """
    team_a, team_b = match.get_team_players()
    delta = match.get_score_delta()
    if delta is None or not team_a or not team_b:
        return {}

    team_a = [u for u in team_a if not is_guest(u)]
    team_b = [u for u in team_b if not is_guest(u)]
    results: Dict[str, Dict[str, Any]] = {}

    def entry(a: str, b: str) -> Dict[str, Any]:
        lo, hi = sorted_pair(a, b)
        return results.setdefault(
            pair_key(a, b),
            {
                "users": [lo, hi],
                "together": 0,
                "together_wins": 0,
                "together_draws": 0,
                "together_losses": 0,
                "against": 0,
                "lo_wins_against": 0,
                "hi_wins_against": 0,
                "draws_against": 0,
            },
        )

    for team, team_delta in ((team_a, delta), (team_b, -delta)):
        for a, b in combinations(team, 2):
            e = entry(a, b)
            e["together"] += 1
            if team_delta > 0:
                e["together_wins"] += 1
            elif team_delta == 0:
                e["together_draws"] += 1
            else:
                e["together_losses"] += 1

    for a in team_a:
        for b in team_b:
            e = entry(a, b)
            e["against"] += 1
            if delta == 0:
                e["draws_against"] += 1
            else:
                winner = a if delta > 0 else b
                e["lo_wins_against" if winner == e["users"][0] else "hi_wins_against"] += 1

    return results


def apply_match_to_pair_stats(transaction, db, match: Match) -> int:
    """Queue Increment writes for one finished match. Returns pairs touched."""
    results = pair_results_for_match(match)
    for key, counters in results.items():
        update: Dict[str, Any] = {"users": counters["users"]}
        for field, value in counters.items():
            if field != "users" and value:
                update[field] = firestore.Increment(value)
        update["last_played"] = match.date_time
        transaction.set(
            db.collection(PAIR_STATS_COLLECTION).document(key), update, merge=True
        )
    return len(results)


def get_pair_stats(
    db, user_ids: Iterable[str]
) -> Dict[Tuple[str, str], Dict[str, Any]]:
    """Fetch stats for every pair among user_ids (guests excluded)."""
    ids = sorted({u for u in user_ids if not is_guest(u)})
    refs = [
        db.collection(PAIR_STATS_COLLECTION).document(pair_key(a, b))
        for a, b in combinations(ids, 2)
    ]
    out: Dict[Tuple[str, str], Dict[str, Any]] = {}
    if not refs:
        return out
    for doc in db.get_all(refs):
        if doc.exists:
            data = doc.to_dict()
            lo, hi = data.get("users", [None, None])
            if lo and hi:
                out[(lo, hi)] = data
    return out


def pairs_from_lineup(
    stats: Dict[Tuple[str, str], Dict[str, Any]],
    team_a: List[str],
    team_b: List[str],
    min_games: int = MIN_GAMES_FOR_CLAIM,
) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    """
    Split stored pair stats into (teammates, opponents) for this lineup,
    keeping only pairs with enough games to say something about.
    """
    side = {**{u: "a" for u in team_a}, **{u: "b" for u in team_b}}
    teammates, opponents = [], []
    for (lo, hi), s in stats.items():
        if lo not in side or hi not in side:
            continue
        if side[lo] == side[hi] and s.get("together", 0) >= min_games:
            teammates.append({"users": [lo, hi], **s})
        elif side[lo] != side[hi] and s.get("against", 0) >= min_games:
            opponents.append({"users": [lo, hi], **s})
    teammates.sort(key=lambda s: s.get("together", 0), reverse=True)
    opponents.sort(key=lambda s: s.get("against", 0), reverse=True)
    return teammates, opponents
