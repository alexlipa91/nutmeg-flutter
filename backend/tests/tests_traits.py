import unittest

from src.models._ratings import MAX_TRAITS_PER_PLAYER, Ratings, clean_skills


class TraitsTests(unittest.TestCase):
    PLAYERS = {"me", "a", "b", "c"}

    def test_keeps_valid_traits_of_other_players(self):
        out = clean_skills(
            {"a": ["fast", "shooter"], "b": ["great_in_goal"]}, "me", self.PLAYERS
        )
        self.assertEqual(out, {"a": ["fast", "shooter"], "b": ["great_in_goal"]})

    def test_drops_unknown_traits_repeats_and_extras(self):
        out = clean_skills(
            {"a": ["fast", "fast", "flying", "strong", "dribbler"]}, "me", self.PLAYERS
        )
        self.assertEqual(out, {"a": ["fast", "strong"]})
        self.assertEqual(MAX_TRAITS_PER_PLAYER, 2)

    def test_no_self_votes_and_only_players_of_the_match(self):
        out = clean_skills(
            {"me": ["fast"], "stranger": ["fast"], "a": ["fast"]}, "me", self.PLAYERS
        )
        self.assertEqual(out, {"a": ["fast"]})

    def test_an_empty_list_takes_the_traits_back(self):
        self.assertEqual(clean_skills({"a": []}, "me", self.PLAYERS), {"a": []})

    def test_garbage_is_ignored(self):
        self.assertEqual(clean_skills(None, "me", self.PLAYERS), {})
        self.assertEqual(clean_skills(["fast"], "me", self.PLAYERS), {})
        self.assertEqual(clean_skills({"a": "fast"}, "me", self.PLAYERS), {})

    def test_traits_given_by_a_rater(self):
        ratings = Ratings(
            match_id="m",
            skills={"a": {"me": ["fast"], "x": ["strong"]}, "b": {"x": ["fast"]}},
        )
        self.assertEqual(ratings.get_skills_given_by("me"), {"a": ["fast"]})
        self.assertEqual(ratings.get_skills_given_by("nobody"), {})


if __name__ == "__main__":
    unittest.main()
