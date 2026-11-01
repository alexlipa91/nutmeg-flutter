"""
Recent form of a player: results of their last few finished matches.

Derived from match history (teams + score), same rules as pair stats. Only
notable form is surfaced to the preview, so it stays an occasional extra.
"""
from __future__ import annotations

from typing import Any, Dict, List, Optional

from google.cloud.firestore_v1.base_query import FieldFilter

from src.models._matches import Match
from src.pair_stats import is_guest, match_is_frozen

FORM_GAMES = 5
# Wins out of the last FORM_GAMES needed to call the form notable.
NOTABLE_AT = 4


def result_for_user(match: Match, user_id: str) -> Optional[str]:
    """'w' / 'd' / 'l' for the user in a finished match, else None."""
    winners, drawers, losers = match.get_win_draw_loss()
    if user_id in winners:
        return "w"
    if user_id in drawers:
        return "d"
    if user_id in losers:
        return "l"
    return None


def recent_results(db, user_id: str, limit: int = FORM_GAMES) -> List[str]:
    """Results of the user's last `limit` finished matches, newest first."""
    docs = (
        db.collection("matches")
        .where(filter=FieldFilter("goingPlayers", "array_contains", user_id))
        .get()
    )
    dated = []
    for doc in docs:
        match = Match.from_doc(doc)
        if not match or not match.date_time or not match_is_frozen(match):
            continue
        result = result_for_user(match, user_id)
        if result:
            dated.append((match.date_time, result))
    dated.sort(key=lambda x: x[0], reverse=True)
    return [r for _, r in dated[:limit]]


def notable_form(results: List[str]) -> Optional[Dict[str, Any]]:
    """Form summary if the player is in great form, else None (only good form
    is surfaced: no calling players out for a bad run)."""
    if len(results) < FORM_GAMES:
        return None
    wins, draws, losses = (results.count(r) for r in ("w", "d", "l"))
    if wins < NOTABLE_AT:
        return None
    return {
        "last_games": len(results),
        "wins": wins,
        "draws": draws,
        "losses": losses,
    }


def forms_for_players(db, user_ids: List[str]) -> Dict[str, Dict[str, Any]]:
    """
    The single best form among the users, as {user_id: form}, or {} when
    nobody is in notable form. At most one so the preview stays an occasional
    extra. Guests have no history and are skipped.
    """
    best_uid, best = None, None
    for uid in user_ids:
        if is_guest(uid):
            continue
        form = notable_form(recent_results(db, uid))
        if form and (best is None or form["wins"] > best["wins"]):
            best_uid, best = uid, form
    return {best_uid: best} if best else {}
