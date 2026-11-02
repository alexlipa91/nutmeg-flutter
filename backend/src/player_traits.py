"""
FIFA-style attributes of a player from the traits others give them when rating.

Each trait is a vote for an attribute (fast -> PAC, shooter -> SHO, great_passer
-> PAS, dribbler -> DRI, solid_defender -> DEF, strong -> PHY, great_in_goal ->
GK). When a rating round closes, the votes a player got and how many raters
used traits for them are added to their user document; the attribute values
are worked out from those totals when the profile is read.

Pure functions, so they can be tested without Firestore.
"""
from typing import Any, Dict, Tuple

from src.models._ratings import TRAITS

ATTRIBUTE_OF_TRAIT = {
    "fast": "PAC",
    "shooter": "SHO",
    "great_passer": "PAS",
    "dribbler": "DRI",
    "solid_defender": "DEF",
    "strong": "PHY",
    "great_in_goal": "GK",
}

# Attributes show once this many raters used traits for the player (two or
# three games); before that there is too little to say anything.
MIN_RATERS = 5
# A trait nobody gave still counts a little, and a few raters count for less
# than many: the share is (votes + PRIOR_VOTES) / (raters + PRIOR_RATERS).
PRIOR_VOTES = 1
PRIOR_RATERS = 5
# Half of the raters giving a trait is the top of the scale, 99.
TOP_SHARE = 0.5
VALUE_FLOOR = 45
VALUE_SPAN = 54
# Goalkeeping only shows for players who really are given it.
GK_MIN_SHARE = 0.15


def trait_votes_for(player_id: str, skills: Dict[str, Any]) -> Tuple[Dict[str, int], int]:
    """
    From a match's skills, {rated_user_id: {rater_id: [trait, ...]}}: the votes
    per trait the player got and how many raters used traits for them (a rater
    who picked none for them still counts, as long as they sent their traits).
    """
    by_rater = (skills or {}).get(player_id) or {}
    votes: Dict[str, int] = {}
    for traits in by_rater.values():
        for trait in traits or []:
            if trait in TRAITS:
                votes[trait] = votes.get(trait, 0) + 1
    return votes, len(by_rater)


def attribute_values(votes: Dict[str, int], raters: int) -> Dict[str, int]:
    """{"PAC": 78, ...} from the totals, or nothing with too few raters."""
    if raters < MIN_RATERS:
        return {}
    values: Dict[str, int] = {}
    for trait, attribute in ATTRIBUTE_OF_TRAIT.items():
        given = votes.get(trait, 0)
        if attribute == "GK" and given / raters < GK_MIN_SHARE:
            continue
        share = (given + PRIOR_VOTES) / (raters + PRIOR_RATERS)
        values[attribute] = int(
            VALUE_FLOOR + VALUE_SPAN * min(1.0, share / TOP_SHARE) + 0.5
        )
    return values
