import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:provider/provider.dart';

class MatchesState extends ChangeNotifier {
  // Add UserState as a field
  final UserState userState;

  // Constructor to receive UserState
  MatchesState(this.userState);

  // match details (do not initialize this map so that we can differentiate when no data has been fetched, i.e. map is null)
  Map<String, Match>? _matchesCache;

  Map<String, List<String>>? _matchesPerTab;

  // ratings per match
  Map<String, Ratings> _ratingsPerMatch = Map();

  // still to vote per match
  Map<String, Map<String, List<String>>> _stillToVote = Map();

  Ratings? getRatings(String matchId) => _ratingsPerMatch[matchId];

  List<Match>? getMatches() {
    if (_matchesPerTab == null) return null;
    return _matchesCache!.values.toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  List<Match>? getMatchesForTab(String tab) {
    if (_matchesPerTab == null ||
        _matchesCache == null ||
        _matchesPerTab![tab] == null) return null;
    return _matchesPerTab![tab]!.map((e) => _matchesCache![e]!).toList();
  }

  Match? getMatch(String matchId) =>
      (_matchesCache == null) ? null : _matchesCache![matchId];

  List<String>? getStillToVote(String matchId, String userId) =>
      _stillToVote[matchId]?[userId];

  void hasVoted(String matchId, String giver, String receiver) {
    var current = _stillToVote[matchId]![giver] ?? [];
    List<String> newList = [];
    current.forEach((u) {
      if (u != receiver) {
        newList.add(u);
      }
    });
    _stillToVote[matchId]![giver] = newList;
    notifyListeners();
  }

  void setMatch(Match m) {
    if (_matchesCache == null) _matchesCache = Map();
    _matchesCache![m.documentId] = m;
    notifyListeners();
  }

  void movePlayerToTeam(
      String matchId, String userId, int teamTargetIndex) async {
    getMatch(matchId)!.manualTeams[teamTargetIndex].add(userId);
    getMatch(matchId)!.manualTeams[(teamTargetIndex + 1) % 2].remove(userId);

    notifyListeners();

    await storeManualTeams(matchId, getMatch(matchId)!.manualTeams);
  }

  Future<void> storeManualTeams(
      String matchId, List<List<String>> teams) async {
    getMatch(matchId)!.manualTeams = teams;
    notifyListeners();

    await editMatch(matchId, {
      "teams.manual.players.a": teams[0],
      "teams.manual.players.b": teams[1],
    });
  }

  Set<String> getSportCenters() => _matchesCache!.values
      .where((m) => m.sportCenterId != null)
      .map((e) => e.sportCenterId!)
      .toSet();

  // depends on which tab
  Future<void> fetchMatches(String tab, BuildContext context) async {
    var userState = context.read<UserState>();
    Map<String, dynamic> params = {};
    switch (tab) {
      case "UPCOMING":
        params["when"] = "future";
        params["radius_km"] = 20;
        break;
      case "GOING":
        // we will filter later on
        if (userState.currentUserId == null) return;
        params["when"] = "future";
        params["with_user"] = userState.currentUserId!;
        break;
      case "PAST":
        if (userState.currentUserId == null) return;
        params["when"] = "past";
        params["with_user"] = userState.currentUserId!;
        break;
      case "MY MATCHES":
        if (userState.currentUserId == null) return;
        params["organized_by"] = userState.currentUserId!;
        break;
    }
    params["lat"] = userState.getLocationInfo().lat;
    params["lng"] = userState.getLocationInfo().lng;
    params["version"] = 2;

    var resp = await CloudFunctionsClient().get("matches", args: params);
    Map<String, dynamic> data =
        (resp == null) ? Map() : Map<String, dynamic>.from(resp);

    if (_matchesCache == null) _matchesCache = Map();

    // filter tests and get sportcenters to download
    Iterable<Match> matches = data.entries
        .map((element) {
          try {
            return Match.fromJson(
                Map<String, dynamic>.from(element.value), element.key);
          } catch (e, s) {
            print("Failed to deserialize match ${element.key.toString()}");
            print(e);
            print(s);
            FirebaseCrashlytics.instance
                .recordError(e, s, reason: 'failed to deserialize a match');
            return null;
          }
        })
        .where((e) => e != null)
        .map((e) {
          _matchesCache![e!.documentId] = e;
          return e;
        })
        .where((e) => (!e.isTest || context.read<UserState>().isTestMode));

    if (_matchesPerTab == null) _matchesPerTab = Map();
    _matchesPerTab![tab] = matches.map((m) => m.documentId).toList();

    notifyListeners();
  }

  Future<Ratings?> fetchRatings(String matchId) async {
    var r = await CloudFunctionsClient().get("matches/$matchId/ratings");
    if (r == null) return null;

    var ratings = Ratings.fromJson(Map<String, dynamic>.from(r));
    this._ratingsPerMatch[matchId] = ratings;
    notifyListeners();

    return ratings;
  }

  Future<List<String>> fetchStillToVote(String matchId, String userId) async {
    var r =
        await CloudFunctionsClient().get("matches/$matchId/ratings/to_vote");
    if (r == null) return [];

    var stillToVote = List<String>.from(r["users"]);
    var current = this._stillToVote[matchId];
    if (current == null) {
      this._stillToVote[matchId] = Map();
    }
    this._stillToVote[matchId]![userId] = stillToVote;

    notifyListeners();

    return stillToVote;
  }

  Future<void> refreshState(BuildContext context, {reset = false}) async {
    if (reset) {
      _matchesPerTab = null;
    }
    await Future.wait(["UPCOMING", "PAST", "GOING", "MY MATCHES"]
        .map((tab) => fetchMatches(tab, context)));
  }

  Future<Match> fetchMatch(String matchId) async {
    var resp = await CloudFunctionsClient()
        .get("matches/$matchId", args: {"version": 2});
    var match = Match.fromJson(resp!, matchId);

    setMatch(match);

    return match;
  }

  Future<void> editMatch(String matchId, Map<String, dynamic> data) async {
    await CloudFunctionsClient().post("matches/$matchId", data = data);
    await fetchMatch(matchId);
  }

  Future<String> createMatch(Match m) async {
    var resp = await CloudFunctionsClient().post("matches", m.toJson());
    var id = resp!["id"];

    await fetchMatch(id);
    return id;
  }
}
