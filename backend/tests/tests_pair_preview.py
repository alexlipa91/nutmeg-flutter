import unittest
from datetime import datetime, timezone
from unittest import mock

from src import match_preview, player_form
from src.models._matches import Match
from src.pair_stats import pair_results_for_match, pairs_from_lineup, pair_key


def make_match(score=(3, 1), a=("u1", "u2", "guest_x"), b=("u3", "u4"), max_players=5):
    going = {u: {} for u in list(a) + list(b)}
    return Match.from_dict(
        {
            "dateTime": datetime(2026, 11, 7, 19, 0, tzinfo=timezone.utc),
            "going": going,
            "maxPlayers": max_players,
            "score": list(score) if score else None,
            "sportCenter": {"name": "Camp Nou Court"},
            "teams": {"balanced": {"players": {"a": list(a), "b": list(b)}}},
        },
        "m1",
    )


class PairStatsTests(unittest.TestCase):
    def test_results_win(self):
        r = pair_results_for_match(make_match(score=(3, 1)))
        p = r[pair_key("u1", "u2")]
        self.assertEqual((p["together"], p["together_wins"]), (1, 1))
        o = r[pair_key("u1", "u3")]
        self.assertEqual(o["against"], 1)
        # u1 < u3 so u1 is "lo" and won
        self.assertEqual((o["lo_wins_against"], o["hi_wins_against"]), (1, 0))

    def test_results_loss_and_draw(self):
        r = pair_results_for_match(make_match(score=(0, 2)))
        self.assertEqual(r[pair_key("u1", "u2")]["together_losses"], 1)
        self.assertEqual(r[pair_key("u3", "u4")]["together_wins"], 1)
        r = pair_results_for_match(make_match(score=(1, 1)))
        self.assertEqual(r[pair_key("u1", "u2")]["together_draws"], 1)
        self.assertEqual(r[pair_key("u1", "u3")]["draws_against"], 1)

    def test_guests_and_no_score_skipped(self):
        r = pair_results_for_match(make_match())
        self.assertFalse(any("guest_x" in k for k in r))
        self.assertEqual(pair_results_for_match(make_match(score=None)), {})

    def test_min_games_filter(self):
        stats = {
            ("u1", "u2"): {"together": 5, "together_wins": 4},
            ("u1", "u3"): {"against": 2},
            ("u3", "u4"): {"together": 2},
        }
        tm, op = pairs_from_lineup(stats, ["u1", "u2"], ["u3", "u4"], min_games=3)
        self.assertEqual([p["users"] for p in tm], [["u1", "u2"]])
        self.assertEqual(op, [])


USERS = {
    "u1": {"name": "Marco Rossi", "avg_score": 3.4, "potm_count": 2},
    "u2": {"name": "Luca Bianchi", "avg_score": 2.9},
    "guest_x": {"name": "Guest"},
    "u3": {"name": "Sara Vila", "avg_score": 3.0},
    "u4": {"name": "Dani Pons", "avg_score": 2.4},
}
STATS = {("u1", "u2"): {"together": 9, "together_wins": 7, "together_draws": 1,
                        "together_losses": 1}}


class PreviewTests(unittest.TestCase):
    def facts(self):
        return match_preview.build_facts(make_match(score=None), USERS, STATS)

    def test_facts_shape(self):
        f = self.facts()
        self.assertEqual(f["venue"], "Camp Nou Court")
        self.assertEqual(f["team_a"]["players"][0]["name"], "Marco")
        self.assertEqual(f["pairs_together"][0]["wins"], 7)
        # guests get the default rating
        self.assertIn(2.5, [p["rating"] for p in f["team_a"]["players"]])
        # no ids or full names leak into the facts
        blob = str(f)
        self.assertNotIn("u1", blob)
        self.assertNotIn("Rossi", blob)

    def test_rating_gap(self):
        even = {u: {"name": u, "avg_score": 3.0} for u in USERS}
        f = match_preview.build_facts(make_match(score=None), even, {})
        self.assertTrue(f["evenly_matched"])
        self.assertEqual(f["rating_gap"], 0.0)
        # fixture ratings: sides average 2.93 vs 2.70
        f = self.facts()
        self.assertFalse(f["evenly_matched"])
        self.assertEqual(f["rating_gap"], 0.23)

    def test_same_first_name_disambiguated(self):
        users = {**USERS, "u4": {"name": "Marco Pons", "avg_score": 2.4}}
        f = match_preview.build_facts(make_match(score=None), users, {})
        names = [p["name"] for t in ("team_a", "team_b") for p in f[t]["players"]]
        self.assertIn("Marco R.", names)
        self.assertIn("Marco P.", names)

    def test_no_teams_returns_none(self):
        m = make_match(score=None)
        m.teams = None
        self.assertIsNone(match_preview.build_facts(m, USERS, {}))

    def test_teams_key(self):
        k = match_preview.teams_key(["u1", "u2"], ["u3", "u4"])
        # order of players and of the two sides is irrelevant
        self.assertEqual(k, match_preview.teams_key(["u4", "u3"], ["u2", "u1"]))
        # moving a player changes it
        self.assertNotEqual(k, match_preview.teams_key(["u1", "u3"], ["u2", "u4"]))

    def test_stale_manual_split_falls_back_to_balanced(self):
        m = make_match(score=None)
        m.has_manual_teams = True
        # manual split from before a player left: does not cover everyone
        m.teams["manual"] = {"players": {"a": ["u1"], "b": ["u3"]}}
        self.assertEqual(match_preview.lineup_teams(m)[0], ["u1", "u2", "guest_x"])
        # a valid manual split wins
        m.teams["manual"] = {"players": {"a": ["u1", "u3", "guest_x"], "b": ["u2", "u4"]}}
        self.assertEqual(match_preview.lineup_teams(m)[0], ["u1", "u3", "guest_x"])

    def test_lineup_ready(self):
        self.assertTrue(match_preview.lineup_ready(make_match(score=None)))
        # not full
        self.assertFalse(
            match_preview.lineup_ready(make_match(score=None, max_players=6))
        )
        # teams do not cover everyone going (stale teams)
        m = make_match(score=None)
        m.going["u9"] = {}
        m.max_players = 6
        self.assertFalse(match_preview.lineup_ready(m))
        # no teams
        m = make_match(score=None)
        m.teams = None
        self.assertFalse(match_preview.lineup_ready(m))

    def test_gemini_parses_structured_json(self):
        resp = mock.Mock()
        resp.json.return_value = {"candidates": [{"content": {"parts": [
            {"text": '{"headline": " Big one ", "body": "Text."}'}]}}]}
        with mock.patch("src.match_preview.requests.post", return_value=resp) as post:
            out = match_preview.gemini_preview(self.facts(), "es", "KEY")
        self.assertEqual(out, {"headline": "Big one", "body": "Text."})
        _, kwargs = post.call_args
        self.assertEqual(kwargs["headers"], {"x-goog-api-key": "KEY"})
        self.assertIn("Spanish", kwargs["json"]["systemInstruction"]["parts"][0]["text"])
        self.assertNotIn("Rossi", str(kwargs["json"]))


if __name__ == "__main__":
    unittest.main()


class FormTests(unittest.TestCase):
    def test_result_for_user(self):
        m = make_match(score=(3, 1))
        self.assertEqual(player_form.result_for_user(m, "u1"), "w")
        self.assertEqual(player_form.result_for_user(m, "u3"), "l")
        self.assertEqual(player_form.result_for_user(make_match(score=(2, 2)), "u1"), "d")
        self.assertIsNone(player_form.result_for_user(m, "stranger"))

    def test_notable_form_only_when_extreme_and_enough_games(self):
        nf = player_form.notable_form
        self.assertEqual(nf(list("wwwdw"))["wins"], 4)
        self.assertIsNone(nf(list("lllll")))  # bad form is never surfaced
        self.assertIsNone(nf(list("wwdll")))  # unremarkable
        self.assertIsNone(nf(list("wwww")))  # fewer than 5 games

    def test_only_the_best_form_is_kept(self):
        results = {"u1": list("wwwwd"), "u2": list("wwwww"), "u3": list("lllll")}
        with mock.patch("src.player_form.recent_results", side_effect=lambda db, u: results[u]):
            out = player_form.forms_for_players(None, ["u1", "u2", "u3", "guest_x"])
        self.assertEqual(list(out), ["u2"])
        self.assertEqual(out["u2"]["wins"], 5)
        with mock.patch("src.player_form.recent_results", return_value=list("wdlwl")):
            self.assertEqual(player_form.forms_for_players(None, ["u1"]), {})

    def test_facts_include_form_only_when_notable(self):
        m = make_match(score=None)
        f = match_preview.build_facts(m, USERS, {})
        self.assertNotIn("players_in_form", f)
        forms = {"u1": player_form.notable_form(list("wwwwd")), "u3": None}
        forms = {u: v for u, v in forms.items() if v}
        f = match_preview.build_facts(m, USERS, {}, forms=forms)
        self.assertEqual(f["players_in_form"][0]["name"], "Marco")
        self.assertEqual(f["players_in_form"][0]["wins"], 4)
        self.assertNotIn("u1", str(f))


class FakeDoc:
    def __init__(self, data, doc_id=""):
        self._d = data
        self.id = doc_id
        self.exists = data is not None

    def to_dict(self):
        return self._d


class FakeRef:
    def __init__(self, store, path):
        self.store, self.path = store, path

    def collection(self, name):
        return FakeColl(self.store, self.path + "/" + name)

    def get(self):
        return FakeDoc(self.store.get(self.path), self.path.split("/")[-1])

    def set(self, data):
        self.store[self.path] = data


class FakeColl:
    def __init__(self, store, path):
        self.store, self.path = store, path

    def where(self, *args, **kwargs):
        return self  # no match history in the fake db

    def get(self):
        return []

    def document(self, doc_id):
        return FakeRef(self.store, self.path + "/" + doc_id)


class FakeDb:
    def __init__(self):
        self.store = {}

    def collection(self, name):
        return FakeColl(self.store, name)

    def get_all(self, refs):
        return [r.get() for r in refs]


class GetPreviewTests(unittest.TestCase):
    def run_preview(self, db, match_dict, calls):
        db.store["matches/m1"] = match_dict
        with mock.patch.object(match_preview.Secrets, "GEMINI_API_KEY", "KEY"), \
             mock.patch(
                 "src.match_preview.gemini_preview",
                 side_effect=lambda *a, **k: calls.append(1) or {"headline": "H", "body": "B"},
             ):
            return match_preview.get_preview(
                db, "m1", "en", False, lambda u: USERS.get(u, {})
            )

    @staticmethod
    def match_dict(a, b, max_players=5):
        return {
            "going": {u: {} for u in a + b},
            "maxPlayers": max_players,
            "dateTime": datetime(2026, 11, 7, 19, 0, tzinfo=timezone.utc),
            "teams": {"balanced": {"players": {"a": a, "b": b}}},
        }

    def test_generate_once_then_regenerate_only_on_team_change(self):
        db, calls = FakeDb(), []
        base = self.match_dict(["u1", "u2", "guest_x"], ["u3", "u4"])

        out = self.run_preview(db, base, calls)
        self.assertEqual(out, {"headline": "H", "body": "B"})
        self.assertEqual(len(calls), 1)
        self.assertEqual(db.store["matches/m1/ai_previews/en"]["headline"], "H")

        # same teams: served from cache, no new generation
        self.run_preview(db, base, calls)
        self.run_preview(db, base, calls)
        self.assertEqual(len(calls), 1)

        # sides swapped: same composition, still cached
        self.run_preview(db, self.match_dict(["u3", "u4"], ["u1", "u2", "guest_x"]), calls)
        self.assertEqual(len(calls), 1)

        # a player moved between teams: regenerated once
        moved = self.match_dict(["u1", "u3", "guest_x"], ["u2", "u4"])
        self.run_preview(db, moved, calls)
        self.run_preview(db, moved, calls)
        self.assertEqual(len(calls), 2)

    def test_nothing_generated_unless_full_with_matching_teams(self):
        db, calls = FakeDb(), []
        # not full
        d = self.match_dict(["u1", "u2", "guest_x"], ["u3", "u4"], max_players=6)
        self.assertIsNone(self.run_preview(db, d, calls))
        # full but teams are stale: a player joined after teams were computed
        d = self.match_dict(["u1", "u2"], ["u3", "u4"])
        d["going"]["u5"] = {}
        self.assertIsNone(self.run_preview(db, d, calls))
        self.assertEqual(calls, [])
        self.assertNotIn("matches/m1/ai_previews/en", db.store)

    def test_gemini_failure_or_no_key_shows_nothing(self):
        db = FakeDb()
        db.store["matches/m1"] = self.match_dict(["u1", "u2", "guest_x"], ["u3", "u4"])
        with mock.patch.object(match_preview.Secrets, "GEMINI_API_KEY", "KEY"), \
             mock.patch("src.match_preview.gemini_preview", side_effect=RuntimeError("429")):
            out = match_preview.get_preview(db, "m1", "en", False, lambda u: USERS.get(u, {}))
        self.assertIsNone(out)
        self.assertNotIn("matches/m1/ai_previews/en", db.store)  # nothing cached
        with mock.patch.object(match_preview.Secrets, "GEMINI_API_KEY", ""):
            out = match_preview.get_preview(db, "m1", "en", False, lambda u: USERS.get(u, {}))
        self.assertIsNone(out)
