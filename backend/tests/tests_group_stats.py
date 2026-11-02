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

    def test_ranking_wins_count_every_game_ratings_only_rated_ones(self):
        ms = [
            match(1, ["a", "b"], ["c", "d"], (2, 0),
                  scores={"a": 4, "b": 4, "c": 2, "d": 2}),
            match(8, ["a", "b"], ["c", "d"], (0, 3)),  # not rated
        ]
        out = group_stats.monthly_group_stats(ms)
        ranking = out["ranking"]
        self.assertEqual(out["ranking_source"], "month")
        self.assertEqual([r["user_id"] for r in ranking], ["a", "b", "c", "d"])
        a = ranking[0]
        self.assertEqual((a["played"], a["wins"], a["avg_rating"]), (2, 1, 4))
        # 1 win in 2 -> 50, rating 4 -> 75: 0.6 * 50 + 0.4 * 75 = 60 -> 50 + 0.49 * 60
        self.assertEqual(a["score"], 79)
        # 1 win in 2 -> 50, rating 2 -> 25: 0.6 * 50 + 0.4 * 25 = 40 -> 50 + 0.49 * 40
        self.assertEqual(ranking[2]["score"], 70)

    def test_ranking_uses_last_rated_games_when_someone_is_unrated(self):
        # d has no rated game this month, so everyone falls back to history
        ms = [match(1, ["a", "b"], ["c", "d"], (2, 0),
                    scores={"a": 5, "b": 5, "c": 5})]
        history = {"a": {
            "20260101170000": 1.0,  # older than the last 5
            "20260201170000": 4, "20260301170000": 4, "20260401170000": 4,
            "20260501170000": 4, "20260601170000": 4,
            "20261105170000": 1.0,  # after the month: ignored
        }}
        out = group_stats.monthly_group_stats(ms, history=history)
        self.assertEqual(out["ranking_source"], "last_games")
        by = {r["user_id"]: r for r in out["ranking"]}
        self.assertEqual(by["a"]["avg_rating"], 4.0)
        # a: 2 wins in 1 game -> 100, rating 4 -> 75: 0.6 * 100 + 0.4 * 75 = 90
        self.assertEqual(by["a"]["score"], 94)
        # b has no history: neutral 3 -> 50: 0.6 * 100 + 0.4 * 50 = 80
        self.assertEqual((by["b"]["avg_rating"], by["b"]["score"]), (3.0, 89))
        # c and d lost, neutral rating: 0.4 * 50 = 20
        self.assertEqual((by["c"]["score"], by["d"]["score"]), (60, 60))

    def test_ranking_draw_is_half_a_win_and_guests_are_skipped(self):
        ms = [match(1, ["a", "guest_x"], ["b"], (1, 1),
                    scores={"a": 3, "guest_x": 3, "b": 3})]
        ranking = group_stats.monthly_group_stats(ms)["ranking"]
        self.assertEqual(sorted(r["user_id"] for r in ranking), ["a", "b"])
        # a draw -> 50, rating 3 -> 50: 50 -> 50 + 0.49 * 50
        self.assertEqual(ranking[0]["score"], 75)

    def test_best_improver_is_the_biggest_rise_since_last_month(self):
        every = {"a": 3, "b": 3, "c": 3, "d": 3}
        ms = [
            match(1, ["a", "b"], ["c", "d"], (0, 2), month=9, scores=every),
            match(1, ["a", "b"], ["c", "d"], (2, 0), month=10, scores=every),
        ]
        out = group_stats.monthly_group_stats(ms)
        # a and b went from no wins (60) to all wins (89): +29; c and d fell
        self.assertEqual(out["best_improver"]["change"], 29)
        self.assertEqual(out["best_improver"]["previous_score"], 60)
        self.assertEqual(out["best_improver"]["user_id"], "a")
        # every player gets the change since last month
        change = {r["user_id"]: r["change"] for r in out["ranking"]}
        self.assertEqual(change, {"a": 29, "b": 29, "c": -29, "d": -29})
        # nothing to compare with in the first month
        self.assertIsNone(group_stats.monthly_group_stats(ms, "202609")["best_improver"])

    def test_ranking_over_a_year_or_everything(self):
        every = {"a": 3, "b": 3, "c": 3, "d": 3, "e": 3}
        # six games in 2026: a and b win four, c and d win two; e plays one
        ms = [
            match(1, ["a", "b", "e"], ["c", "d"], (2, 0), month=1, scores=every),
            match(1, ["a", "b"], ["c", "d"], (2, 0), month=2, scores=every),
            match(1, ["a", "b"], ["c", "d"], (2, 0), month=3, scores=every),
            match(1, ["a", "b"], ["c", "d"], (2, 0), month=4, scores=every),
            match(1, ["a", "b"], ["c", "d"], (0, 2), month=5, scores=every),
            match(1, ["a", "b"], ["c", "d"], (0, 2), month=6, scores=every),
            Match.from_dict(  # last year
                {"dateTime": datetime(2025, 5, 1, 18, tzinfo=timezone.utc),
                 "going": {"a": {}, "c": {}}, "score": [1, 0],
                 "teams": {"balanced": {"players": {"a": ["a"], "b": ["c"]}}}}, "old"),
        ]
        year = group_stats.monthly_group_stats(ms, "2026")
        self.assertEqual(year["ranking_source"], "period")
        self.assertEqual(year["matches"], 6)
        by = {r["user_id"]: r for r in year["ranking"]}
        # regulars played 6 games, so 4 are needed (30% is less, the floor is 4):
        # e is left out
        self.assertEqual(year["ranking_min_games"], 4)
        self.assertNotIn("e", by)
        # 4 wins in 6 with 5 average games added: 6.5 / 11 = 59%, which is 78 on the
        # 20-70% range; rating 3 is 45 on the 2.0-4.2 range:
        # 0.6 * 78.2 + 0.4 * 45.5 = 65.1 -> 40 + 0.55 * 65.1
        self.assertEqual((by["a"]["played"], by["a"]["wins"], by["a"]["score"]), (6, 4, 76))
        # 2 wins in 6: 4.5 / 11 = 41% -> 41.8: 0.6 * 41.8 + 18.2 = 43.3 -> 64
        self.assertEqual(by["c"]["score"], 64)
        self.assertIsNone(year["best_improver"])
        # no month-over-month change outside the monthly view
        self.assertTrue(all("change" not in r for r in year["ranking"]))
        everything = group_stats.monthly_group_stats(ms, "all")
        self.assertEqual(everything["matches"], 7)
        self.assertEqual({r["user_id"]: r["played"] for r in everything["ranking"]}["a"], 7)

    def test_long_period_score_uses_fixed_ranges(self):
        a = ["a%d" % i for i in range(5)]
        b = ["b%d" % i for i in range(5)]
        scores = {**{u: 4 for u in a}, **{u: 3 for u in b}}
        # the a team wins four games out of six, the b team two
        ms = [match(1, a, b, (2, 0), month=m, scores=scores) for m in (1, 2, 3, 4)]
        ms += [match(1, a, b, (0, 2), month=m, scores=scores) for m in (5, 6)]
        out = group_stats.monthly_group_stats(ms, "all")["ranking"]
        by = {r["user_id"]: r["score"] for r in out}
        # a: 6.5 / 11 = 59% -> 78.2 on 20-70%; rating (24 + 9) / 9 = 3.67 -> 75.8
        # on 2.0-4.2: 0.6 * 78.2 + 0.4 * 75.8 = 77.2 -> 40 + 0.55 * 77.2
        self.assertEqual({by[u] for u in a}, {82})
        # b: 4.5 / 11 = 41% -> 41.8; rating 3.0 -> 45.5: 43.3 -> 64
        self.assertEqual({by[u] for u in b}, {64})
        # the score only depends on the player's own results, not on the others
        self.assertEqual(group_stats.long_period_score(33 / 9, 6.5, 11), 82)

    def test_player_all_time_score_matches_the_all_time_table(self):
        every = {"a": 3, "b": 3, "c": 3, "d": 3, "e": 3}
        ms = [
            match(1, ["a", "b", "e"], ["c", "d"], (2, 0), month=1, scores=every),
            match(1, ["a", "b"], ["c", "d"], (2, 0), month=2, scores=every),
            match(1, ["a", "b"], ["c", "d"], (2, 0), month=3, scores=every),
            match(1, ["a", "b"], ["c", "d"], (2, 0), month=4, scores=every),
            match(1, ["a", "b"], ["c", "d"], (0, 2), month=5, scores=every),
            match(1, ["a", "b"], ["c", "d"], (0, 2), month=6, scores=every),
        ]
        table = {r["user_id"]: r["score"]
                 for r in group_stats.monthly_group_stats(ms, "all")["ranking"]}
        for player in ("a", "c"):
            self.assertEqual(group_stats.player_all_time_score(ms, player), table[player])
        # e played one game: not in the table, so no score
        self.assertIsNone(group_stats.player_all_time_score(ms, "e"))

    def test_one_good_game_does_not_beat_a_long_record(self):
        ms = [match(d, ["long"] + list("bcd"), list("efgh"), (2, 0), month=m,
                    scores={"long": 3.5, "b": 3, "c": 3, "d": 3, "e": 3, "f": 3, "g": 3, "h": 3})
              for m in range(1, 7) for d in (1, 2, 3)]
        # a newcomer wins their only game and gets the best rating
        ms.append(match(4, ["new", "b", "c", "d"], list("efgh"), (2, 0), month=6,
                        scores={"new": 5, "b": 3, "c": 3, "d": 3, "e": 3, "f": 3, "g": 3, "h": 3}))
        ranking = group_stats.monthly_group_stats(ms, "all")["ranking"]
        self.assertNotIn("new", [r["user_id"] for r in ranking])

    def test_ranking_empty_without_games(self):
        self.assertEqual(group_stats.monthly_group_stats([])["ranking"], [])

if __name__ == "__main__":
    unittest.main()
