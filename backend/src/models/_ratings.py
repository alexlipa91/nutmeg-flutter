"""
Typed model for the Ratings Firestore subcollection document.
Lives at: matches/{matchId}/ratings/data
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

from google.cloud.firestore_v1.client import Client


def ratings_ref(match_id: str, db: Client):
    """Return a DocumentReference for matches/{matchId}/ratings/data."""
    return db.collection("matches").document(match_id).collection("ratings").document("data")


@dataclass
class Ratings:
    """Typed representation of a match's ratings document."""

    # document id (same as the parent match id)
    match_id: str

    # --- raw votes (written incrementally as users vote) ---
    # scores[rated_user_id][rater_user_id] = score (int)
    scores: Dict[str, Dict[str, int]] = field(default_factory=dict)

    # skills[rated_user_id][rater_user_id] = list of skill tags
    skills: Dict[str, Dict[str, List[str]]] = field(default_factory=dict)

    # award_votes[voter_user_id][award_id] = voted_for_user_id
    award_votes: Dict[str, Dict[str, str]] = field(default_factory=dict)

    # --- computed fields (written by freeze_match_stats) ---
    # final_scores[user_id] = averaged score (float)
    final_scores: Dict[str, float] = field(default_factory=dict)

    # final_potms: list of player-of-the-match user ids
    final_potms: List[str] = field(default_factory=list)

    # final_awards[award_id] = winning user_id (or dict)
    final_awards: Dict[str, Any] = field(default_factory=dict)

    # awards[award_id] = {"userId": str, "votedBy": {voter_id: ...}}
    # (legacy/aggregated awards data)
    awards: Dict[str, Any] = field(default_factory=dict)

    # set when ratings could not be computed (e.g. not enough voters)
    ratings_not_computed_reason: Optional[str] = None

    # ---- Firestore mapping ----

    @classmethod
    def _field_mapping(cls) -> Dict[str, str]:
        """Return {firestoreKey: python_attr} mapping."""
        return {
            "scores": "scores",
            "skills": "skills",
            "awardVotes": "award_votes",
            "finalScores": "final_scores",
            "finalPotms": "final_potms",
            "finalAwards": "final_awards",
            "awards": "awards",
            "ratings_not_computed_reason": "ratings_not_computed_reason",
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any], match_id: str) -> Ratings:
        """Create a Ratings from a Firestore document dict."""
        kwargs: Dict[str, Any] = {"match_id": match_id}
        mapping = cls._field_mapping()
        for firestore_key, attr_name in mapping.items():
            if firestore_key in data and data[firestore_key] is not None:
                kwargs[attr_name] = data[firestore_key]
        return cls(**kwargs)

    @classmethod
    def from_doc(cls, doc, match_id: str) -> Optional[Ratings]:
        """Create a Ratings from a Firestore DocumentSnapshot."""
        if not doc.exists:
            return None
        return cls.from_dict(doc.to_dict(), match_id)

    @classmethod
    def get_by_match_id(cls, match_id: str, db: Client) -> Optional[Ratings]:
        """Fetch a Ratings document from Firestore."""
        doc = ratings_ref(match_id, db).get()
        return cls.from_doc(doc, match_id)

    # ---- helpers ----

    def num_voters(self) -> int:
        """Return the number of distinct users who gave at least one score."""
        voters = set()
        for raters in self.scores.values():
            voters.update(raters.keys())
        return len(voters)

    def get_scores_for_user(self, user_id: str) -> Dict[str, int]:
        """Return {rater_id: score} for a given rated user."""
        return self.scores.get(user_id, {})

    def get_ratings_given_by(self, user_id: str) -> Dict[str, int]:
        """Return {rated_user_id: score} for ratings given BY this user."""
        given: Dict[str, int] = {}
        for rated_user_id, raters in self.scores.items():
            if user_id in raters:
                given[rated_user_id] = raters[user_id]
        return given

    def is_computed(self) -> bool:
        """Return True if final scores have been computed."""
        return bool(self.final_scores)

    # ---- write operations ----

    @staticmethod
    def add_scores(match_id: str, rater_id: str, scores: Dict[str, int], db: Client) -> None:
        """Add scores from one rater to multiple rated users.

        scores: {rated_user_id: score}
        """
        update: Dict[str, Any] = {"scores": {}}
        for rated_user_id, score in scores.items():
            update["scores"][rated_user_id] = {rater_id: score}
        ratings_ref(match_id, db).set(update, merge=True)

    @staticmethod
    def add_award_votes(match_id: str, voter_id: str, votes: Dict[str, str], db: Client) -> None:
        """Add award votes from one voter.

        votes: {award_id: voted_for_user_id}
        """
        ratings_ref(match_id, db).set(
            {"awardVotes": {voter_id: votes}},
            merge=True,
        )

    @staticmethod
    def _write_match_summary(match_id: str, summary: Dict[str, Any], db: Client) -> None:
        """Write ratings summary to the main match document."""
        db.collection("matches").document(match_id).update({"ratings": summary})

    @staticmethod
    def store_final_results(
        match_id: str,
        user_scores: Dict[str, float],
        potms: List[str],
        award_votes: Dict[str, Any],
        db: Client,
    ) -> None:
        """Write computed final scores, POTMs, and awards."""
        # TODO drop it once all clients move to use match
        ratings_ref(match_id, db).update({
            "finalScores": user_scores,
            "finalPotms": potms,
            "finalAwards": award_votes,
        })
        # also store summary on the main match doc for fast reads
        Ratings._write_match_summary(match_id, {
            "finalScores": user_scores,
            "finalPotms": potms,
            "finalAwards": award_votes,
        }, db)

    @staticmethod
    def set_not_computed_reason(match_id: str, reason: str, db: Client) -> None:
        """Mark ratings as not computable with a reason."""
        # TODO drop it once all clients move to use match
        ratings_ref(match_id, db).set(
            {"ratings_not_computed_reason": reason},
            merge=True,
        )
        # also store summary on the main match doc for fast reads
        Ratings._write_match_summary(match_id, {
            "ratings_not_computed_reason": reason,
        }, db)


if __name__ == "__main__":
    import argparse

    import firebase_admin
    from firebase_admin import firestore

    parser = argparse.ArgumentParser(description="Fetch and print a Ratings document")
    parser.add_argument("match_id", help="Firestore match document ID")
    args = parser.parse_args()

    firebase_admin.initialize_app()
    db = firestore.client()

    ratings = Ratings.get_by_match_id(args.match_id, db)
    if not ratings:
        print(f"No ratings for match {args.match_id}")
        exit(1)

    print(f"Ratings for match: {ratings.match_id}")
    print(f"  voters:          {ratings.num_voters()}")
    print(f"  scores:          {len(ratings.scores)} users rated")
    print(f"  skills:          {len(ratings.skills)} users with skills")
    print(f"  award_votes:     {len(ratings.award_votes)} voters")
    print(f"  final_scores:    {ratings.final_scores}")
    print(f"  final_potms:     {ratings.final_potms}")
    print(f"  final_awards:    {ratings.final_awards}")
    print(f"  not_computed:    {ratings.ratings_not_computed_reason}")
    print(f"  is_computed:     {ratings.is_computed()}")
