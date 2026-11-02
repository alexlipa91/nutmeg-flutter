import unittest

from src import player_traits


class PlayerTraitsTests(unittest.TestCase):
    def test_votes_and_raters_of_a_player_in_a_match(self):
        skills = {
            "p": {"a": ["fast", "shooter"], "b": ["fast"], "c": []},
            "q": {"a": ["strong"]},
        }
        votes, raters = player_traits.trait_votes_for("p", skills)
        self.assertEqual(votes, {"fast": 2, "shooter": 1})
        # c picked nothing for them but still sent their traits
        self.assertEqual(raters, 3)
        self.assertEqual(player_traits.trait_votes_for("nobody", skills), ({}, 0))
        self.assertEqual(player_traits.trait_votes_for("p", {}), ({}, 0))

    def test_unknown_traits_are_not_counted(self):
        votes, _ = player_traits.trait_votes_for("p", {"p": {"a": ["flying", "fast"]}})
        self.assertEqual(votes, {"fast": 1})

    def test_too_few_raters_show_nothing(self):
        self.assertEqual(player_traits.attribute_values({"fast": 4}, 4), {})

    def test_attribute_values(self):
        values = player_traits.attribute_values({"fast": 3}, 6)
        # share (3 + 1) / (6 + 5) = 36% -> 45 + 54 * 0.727 = 84
        self.assertEqual(values["PAC"], 84)
        # nobody gave it: 1 / 11 = 9% -> 45 + 54 * 0.18 = 55
        self.assertEqual(values["SHO"], 55)

    def test_top_of_the_scale(self):
        self.assertEqual(player_traits.attribute_values({"strong": 20}, 20)["PHY"], 99)

    def test_goalkeeping_only_for_those_given_it(self):
        self.assertNotIn("GK", player_traits.attribute_values({"fast": 3}, 6))
        # 1 of 6 is 17%, enough
        self.assertIn("GK", player_traits.attribute_values({"great_in_goal": 1}, 6))


if __name__ == "__main__":
    unittest.main()
