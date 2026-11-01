import unittest
from datetime import datetime, timezone

from src import group_stats
from src.models._matches import Match


def match(day, a, b, score, month=10, scores=None, awards=None, guests=()):
    return Match.from_dict(
        {
            "dateTime": datetime(2026, month, day, 18, 0, tzinfo=timezone.utc),
            "going": {u: {} for u in a + b},
            "score": list(score),
            "teams": {"balanced": {"players": {"a": a, "b": b}}},
            "ratings": {"finalScores": scores or {}, "finalAwards": awards or {}},
        },
        "m{}-{}".format(month, day),
    )


class GroupStatsTests(unittest.TestCase):
    def test_wins_losses_and_default_month(self):
        ms = [
            match(1, ["a", "b"], ["c", "d"], (2, 0)),
            match(8, ["a", "c"], ["b", "d"], (1, 1)),
            match(3, ["a", "b"], ["c", "d"], (0, 5), month=9),  # other month
        ]
        out = group_stats.monthly_group_stats(ms)
        self.assertEqual(out["month"], "202610")
        self.assertEqual(out["available_months"], ["202610", "202609"])
        self.assertEqual(out["matches"], 2)
        by = {p["user_id"]: p for p in out["players"]}
        self.assertEqual((by["a"]["wins"], by["a"]["draws"], by["a"]["losses"]), (1, 1, 0))
        self.assertEqual((by["d"]["wins"], by["d"]["draws"], by["d"]["losses"]), (0, 1, 1))
        self.assertEqual(out["highlights"]["most_losses"][0]["user_id"] in ("c", "d"), True)
        # explicit month
        sept = group_stats.monthly_group_stats(ms, "202609")
        self.assertEqual(sept["matches"], 1)
        self.assertEqual(sept["highlights"]["most_wins"][0]["user_id"] in ("c", "d"), True)

    def test_ties_are_all_returned(self):
        ms = [match(1, list("abcde"), list("fghij"), (3, 0))]
        out = group_stats.monthly_group_stats(ms)
        self.assertEqual(
            sorted(e["user_id"] for e in out["highlights"]["most_wins"]), list("abcde")
        )
        self.assertEqual(len(out["highlights"]["most_losses"]), 5)

    def test_guests_and_unfinished_matches_ignored(self):
        ms = [
            match(1, ["a", "guest_x"], ["b"], (1, 0)),
            Match.from_dict(  # no score yet
                {"dateTime": datetime(2026, 10, 9, tzinfo=timezone.utc),
                 "going": {"a": {}, "b": {}},
                 "teams": {"balanced": {"players": {"a": ["a"], "b": ["b"]}}}}, "x"),
        ]
        out = group_stats.monthly_group_stats(ms)
        self.assertEqual(out["matches"], 1)
        self.assertNotIn("guest_x", [p["user_id"] for p in out["players"]])

    def test_best_rating_threshold_adapts(self):
        # only one rated game for everyone -> still ranked
        ms = [match(1, ["a", "b"], ["c"], (1, 0), scores={"a": 4.0, "b": 3.0, "c": 2.0})]
        out = group_stats.monthly_group_stats(ms)
        self.assertEqual(out["highlights"]["best_rating"][0]["user_id"], "a")
        # a has 2 rated games, c has 1: the 2-game rule applies, c excluded
        ms = [
            match(1, ["a", "b"], ["c"], (1, 0), scores={"a": 4.0, "b": 3.0, "c": 5.0}),
            match(8, ["a"], ["b", "c"], (1, 0), scores={"a": 3.0, "b": 3.0}),
        ]
        out = group_stats.monthly_group_stats(ms)
        top = out["highlights"]["best_rating"]
        self.assertEqual([e["user_id"] for e in top], ["a"])
        self.assertEqual(top[0]["avg_rating"], 3.5)

    def test_chemistry_needs_games_and_win_rate(self):
        # a & b: 2/2 together -> chemistry. c & d lose -> no.
        ms = [
            match(1, ["a", "b"], ["c", "d"], (2, 0)),
            match(8, ["a", "b"], ["c", "d"], (3, 1)),
        ]
        ch = group_stats.monthly_group_stats(ms)["highlights"]["chemistry"]
        self.assertEqual(ch["users"], ["a", "b"])
        self.assertEqual((ch["together"], ch["wins"]), (2, 2))
        # a single game together is not enough
        one = group_stats.monthly_group_stats([ms[0]])["highlights"]["chemistry"]
        self.assertIsNone(one)

    def test_repeat_awards(self):
        votes = lambda uid: {"best_goal": {uid: 3, "z": 1}}
        ms = [
            match(1, ["a"], ["b"], (1, 0), awards=votes("a")),
            match(8, ["a"], ["b"], (1, 0), awards=votes("a")),
            match(15, ["a"], ["b"], (1, 0), awards=votes("b")),
        ]
        rep = group_stats.monthly_group_stats(ms)["highlights"]["repeat_awards"]
        self.assertEqual(rep, [{"award": "best_goal", "user_id": "a", "times": 2}])
        # once is not a repeat
        ms = [match(1, ["a"], ["b"], (1, 0), awards=votes("a"))]
        self.assertEqual(group_stats.monthly_group_stats(ms)["highlights"]["repeat_awards"], [])

    def test_player_of_the_month_counts_wins_and_rating(self):
        # a: most wins (2), rating 3.0; b: best rating 4.5 but only 1 win;
        # c: 2 wins, rating 4.0 -> leads wins (tied) and 2nd on rating -> POTM
        ms = [
            match(1, ["a", "c"], ["b", "d"], (2, 0),
                  scores={"a": 3.0, "c": 4.0, "b": 4.5, "d": 2.0}),
            match(8, ["a", "c"], ["b", "d"], (1, 0),
                  scores={"a": 3.0, "c": 4.0, "b": 4.5, "d": 2.0}),
            match(15, ["b", "d"], ["a", "c"], (1, 0),
                  scores={"a": 3.0, "c": 4.0, "b": 4.5, "d": 2.0}),
        ]
        out = group_stats.monthly_group_stats(ms)
        potm = out["player_of_the_month"]
        self.assertEqual(potm["user_id"], "c")
        self.assertTrue(potm["most_wins"])
        self.assertFalse(potm["best_rated"])
        self.assertEqual([r["user_id"] for r in out["runners_up"]][0], "a")
        # a leader on both measures is flagged for both and scores ~2
        both = [match(1, ["x", "y"], ["z"], (1, 0), scores={"x": 5.0, "y": 3.0, "z": 2.0})]
        potm = group_stats.monthly_group_stats(both)["player_of_the_month"]
        self.assertEqual(potm["user_id"], "x")
        self.assertTrue(potm["most_wins"] and potm["best_rated"])
        self.assertEqual(potm["score"], 2.0)

    def test_player_of_the_month_needs_ratings(self):
        out = group_stats.monthly_group_stats([match(1, ["a"], ["b"], (1, 0))])
        self.assertIsNone(out["player_of_the_month"])
        self.assertEqual(out["runners_up"], [])

    def test_most_played_organizer(self):
        now = datetime(2026, 11, 1, tzinfo=timezone.utc)

        def m(org, day, month=10, **kw):
            x = match(day, ["a"], ["b"], (1, 0), month=month)
            x.organizer_id = org
            for k, v in kw.items():
                setattr(x, k, v)
            return x

        ms = [m("o1", 1), m("o2", 2), m("o2", 3), m("o1", 4)]
        # tie on count: the most recent match wins -> o1 (day 4)
        self.assertEqual(group_stats.most_played_organizer(ms, now), "o1")
        ms.append(m("o2", 5))
        self.assertEqual(group_stats.most_played_organizer(ms, now), "o2")
        # cancelled / test matches and missing organizers are ignored
        ms = [m("o1", 1), m("o2", 2, cancelled_at=datetime(2026, 10, 3, tzinfo=timezone.utc)),
              m("o2", 3, is_test=True), m(None, 4)]
        self.assertEqual(group_stats.most_played_organizer(ms, now), "o1")
        self.assertIsNone(group_stats.most_played_organizer([], now))

    def test_most_played_organizer_prefers_recent_group(self):
        now = datetime(2026, 11, 1, tzinfo=timezone.utc)

        def m(org, day, month):
            x = match(day, ["a"], ["b"], (1, 0), month=month)
            x.organizer_id = org
            return x

        # old group: 5 games last spring; new group: 2 games this month
        ms = [m("old", d, 4) for d in range(1, 6)] + [m("new", 5, 10), m("new", 12, 10)]
        self.assertEqual(group_stats.most_played_organizer(ms, now), "new")
        # nothing recent: fall back to all-time
        self.assertEqual(
            group_stats.most_played_organizer([m("old", d, 4) for d in range(1, 4)], now),
            "old",
        )

    def test_empty(self):
        out = group_stats.monthly_group_stats([])
        self.assertIsNone(out["month"])
        self.assertEqual(out["players"], [])


if __name__ == "__main__":
    unittest.main()
