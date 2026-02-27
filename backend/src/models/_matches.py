"""
Typed model for the Match Firestore document.
Uses dataclasses with a from_dict/from_doc classmethod to map
Firestore camelCase fields to snake_case Python attributes.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Dict, List, Optional, Tuple

from firebase_admin import firestore as fb_firestore


@dataclass
class Match:
    """Typed representation of a Firestore match document."""

    # document id
    id: str

    # --- core ---
    date_time: Optional[datetime] = None
    duration: Optional[int] = None  # minutes
    min_players: Optional[int] = None
    max_players: Optional[int] = None
    organizer_id: Optional[str] = None

    # --- location ---
    sport_center_id: Optional[str] = None
    sport_center: Optional[Dict[str, Any]] = None
    sport_center_sub_location: Optional[str] = None

    # --- pricing ---
    price: Optional[Dict[str, int]] = None  # {basePrice: int, userFee: int}
    is_manual_payment: bool = False

    # --- flags ---
    is_test: bool = False
    is_private: bool = False

    # --- players ---
    going: Dict[str, Dict[str, Any]] = field(default_factory=dict)
    going_players: List[str] = field(default_factory=list)
    wait_list: Dict[str, Dict[str, Any]] = field(default_factory=dict)

    # --- teams ---
    teams: Optional[Dict[str, Any]] = None
    has_manual_teams: bool = False

    # --- score ---
    score: Optional[List[int]] = None  # [team_a_score, team_b_score]

    # --- lifecycle timestamps ---
    created_at: Optional[datetime] = None
    cancelled_at: Optional[datetime] = None
    cancelled_reason: Optional[str] = None
    confirmed_at: Optional[datetime] = None
    scores_computed_at: Optional[datetime] = None

    # --- cancellation policy ---
    cancel_hours_before: Optional[int] = None

    # --- scheduling ---
    tasks_scheduled: Optional[List[str]] = None

    # --- payout ---
    paid_out_at: Optional[datetime] = None
    payout_id: Optional[str] = None

    # --- ratings summary (embedded on the match doc) ---
    ratings_summary: Optional[Dict[str, Any]] = None

    # ---- field mapping: Firestore camelCase -> Python snake_case ----
    _FIELD_MAP: Dict[str, str] = field(default=None, init=False, repr=False)

    # map of firestore key -> dataclass attribute
    _FIRESTORE_TO_ATTR: Dict[str, str] = field(default=None, init=False, repr=False)

    @classmethod
    def _field_mapping(cls) -> Dict[str, str]:
        """Return {firestoreKey: python_attr} mapping."""
        return {
            "dateTime": "date_time",
            "duration": "duration",
            "minPlayers": "min_players",
            "maxPlayers": "max_players",
            "organizerId": "organizer_id",
            "sportCenterId": "sport_center_id",
            "sportCenter": "sport_center",
            "sportCenterSubLocation": "sport_center_sub_location",
            "price": "price",
            "isManualPayment": "is_manual_payment",
            "isTest": "is_test",
            "isPrivate": "is_private",
            "going": "going",
            "goingPlayers": "going_players",
            "waitList": "wait_list",
            "teams": "teams",
            "hasManualTeams": "has_manual_teams",
            "score": "score",
            "createdAt": "created_at",
            "cancelledAt": "cancelled_at",
            "cancelledReason": "cancelled_reason",
            "confirmedAt": "confirmed_at",
            "scoresComputedAt": "scores_computed_at",
            "cancelHoursBefore": "cancel_hours_before",
            "tasksScheduled": "tasks_scheduled",
            "paid_out_at": "paid_out_at",
            "payout_id": "payout_id",
            "ratings": "ratings_summary",
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any], doc_id: str) -> Match:
        """Create a Match from a Firestore document dict."""
        kwargs: Dict[str, Any] = {"id": doc_id}
        mapping = cls._field_mapping()
        for firestore_key, attr_name in mapping.items():
            if firestore_key in data and data[firestore_key] is not None:
                kwargs[attr_name] = data[firestore_key]
        return cls(**kwargs)

    @classmethod
    def from_doc(cls, doc) -> Optional[Match]:
        """Create a Match from a Firestore DocumentSnapshot."""
        if not doc.exists:
            return None
        return cls.from_dict(doc.to_dict(), doc.id)

    @classmethod
    def get_by_id(cls, match_id: str, db, is_test: bool = False) -> Optional[Match]:
        """Fetch a Match from Firestore by document ID."""
        coll = "matches_test" if is_test else "matches"
        doc = db.collection(coll).document(match_id).get()
        return cls.from_doc(doc)

    # ---- helpers ----

    def get_team_players(self) -> Tuple[List[str], List[str]]:
        """Return (team_a, team_b) based on manual vs balanced teams."""
        if not self.teams:
            return [], []
        logic = "manual" if self.has_manual_teams else "balanced"
        team_data = self.teams.get(logic, {}).get("players", {})
        return team_data.get("a", []), team_data.get("b", [])

    def get_score_delta(self) -> Optional[int]:
        """Return score[0] - score[1], or None if no score."""
        if not self.score or len(self.score) != 2:
            return None
        return self.score[0] - self.score[1]

    def get_win_draw_loss(self) -> Tuple[List[str], List[str], List[str]]:
        """Return (winners, drawers, losers) as lists of user IDs."""
        delta = self.get_score_delta()
        if delta is None:
            return [], [], []

        team_a, team_b = self.get_team_players()
        if delta > 0:
            return team_a, [], team_b
        elif delta == 0:
            return [], team_a + team_b, []
        else:
            return team_b, [], team_a

    def is_rated(self) -> bool:
        if self.scores_computed_at is not None:
            return True
        if self.ratings_summary and self.ratings_summary.get("computed_at"):
            return True
        return False

    def is_cancelled(self) -> bool:
        return self.cancelled_at is not None

    def going_user_ids(self) -> List[str]:
        """Return list of user IDs from the going map."""
        if not self.going:
            return []
        return list(self.going.keys())

    def describe(self) -> str:
        """Human-readable one-liner: 'Match @ Venue · Mon 05 Jan 14:00 · 60min'."""
        parts: List[str] = []
        venue = (self.sport_center or {}).get("name", "")
        city = (self.sport_center or {}).get("city", "")
        if venue and city:
            parts.append("{}, {}".format(venue, city))
        elif venue or city:
            parts.append(venue or city)
        if self.date_time:
            parts.append(self.date_time.strftime("%a %d %b %H:%M"))
        if self.duration:
            parts.append("{}min".format(self.duration))
        if parts:
            return "Match · " + " · ".join(parts)
        return "Nutmeg Match"

    # ---- Firestore write helpers ----

    def is_full(self) -> bool:
        return len(self.going) >= (self.max_players or 0)

    def has_waitlist(self) -> bool:
        return len(self.wait_list) > 0

    def validate_can_join(self, user_id: str) -> None:
        """Raise if user cannot join the match directly."""
        if user_id in self.going:
            raise Exception("User already going")
        if self.is_full():
            raise Exception("Match is full")
        if self.has_waitlist() and user_id not in self.wait_list:
            raise Exception("There are users in the waitlist. Join the waitlist instead")

    def validate_can_join_waitlist(self, user_id: str) -> None:
        """Raise if user cannot join the waitlist."""
        if user_id in self.going:
            raise Exception("User is already going to this match")

    def validate_can_promote(self, user_id: str) -> None:
        """Raise if user cannot be promoted from waitlist."""
        if user_id not in self.wait_list:
            raise Exception("User is not in the waitlist")
        if self.is_full():
            raise Exception("Match is full")

    def is_in_waitlist(self, user_id: str) -> bool:
        return user_id in self.wait_list

    def going_update(self, user_id: str, timestamp: datetime,
                     payment_intent: Optional[str] = None) -> Dict[str, Any]:
        """Return the Firestore merge-set dict to add a user to going."""
        going_entry: Dict[str, Any] = {"createdAt": timestamp}
        if payment_intent is not None:
            going_entry["payment_intent"] = payment_intent
        return {
            "going": {user_id: going_entry},
            "goingPlayers": fb_firestore.ArrayUnion([user_id]),
        }

    @staticmethod
    def waitlist_add_update(user_id: str, timestamp: datetime) -> Dict[str, Any]:
        """Return the Firestore merge-set dict to add a user to the waitlist."""
        return {"waitList": {user_id: {"createdAt": timestamp}}}

    @staticmethod
    def waitlist_remove_update(user_id: str) -> Dict[str, Any]:
        """Return the Firestore update dict to remove a user from the waitlist."""
        return {"waitList." + user_id: fb_firestore.DELETE_FIELD}

    @staticmethod
    def joined_transaction_log(user_id: str, timestamp: datetime,
                               payment_intent: Optional[str] = None) -> Dict[str, Any]:
        log: Dict[str, Any] = {
            "type": "joined",
            "userId": user_id,
            "createdAt": timestamp,
        }
        if payment_intent is not None:
            log["paymentIntent"] = payment_intent
        return log

    @staticmethod
    def promoted_transaction_log(user_id: str, timestamp: datetime) -> Dict[str, Any]:
        return {
            "type": "promoted_from_waitlist",
            "userId": user_id,
            "createdAt": timestamp,
        }


if __name__ == "__main__":
    import argparse

    import firebase_admin
    from firebase_admin import firestore

    parser = argparse.ArgumentParser(description="Fetch and print a Match document")
    parser.add_argument("match_id", help="Firestore document ID of the match")
    args = parser.parse_args()

    firebase_admin.initialize_app()
    db = firestore.client()

    match = Match.get_by_id(args.match_id, db)
    if not match:
        print(f"Match {args.match_id} not found")
        exit(1)

    print(f"Match: {match.id}")
    print(f"  date_time:       {match.date_time}")
    print(f"  duration:        {match.duration} min")
    print(f"  organizer_id:    {match.organizer_id}")
    print(f"  max_players:     {match.max_players}")
    print(f"  min_players:     {match.min_players}")
    print(f"  sport_center_id: {match.sport_center_id}")
    print(f"  is_test:         {match.is_test}")
    print(f"  is_private:      {match.is_private}")
    print(f"  score:           {match.score}")
    print(f"  has_manual_teams:{match.has_manual_teams}")
    print(f"  going:           {match.going_user_ids()}")
    print(f"  scores_computed: {match.scores_computed_at}")
    print(f"  cancelled_at:    {match.cancelled_at}")
    team_a, team_b = match.get_team_players()
    print(f"  team_a:          {team_a}")
    print(f"  team_b:          {team_b}")

    winners, drawers, losers = match.get_win_draw_loss()
    print(f"  winners:         {winners}")
    print(f"  drawers:         {drawers}")
    print(f"  losers:          {losers}")
