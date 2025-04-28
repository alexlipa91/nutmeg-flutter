import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:provider/provider.dart';

class MatchesState extends ChangeNotifier {
  final logger = Logger("MatchesState");
  
  // Add UserState as a field
  final UserState userState;

  // Constructor to receive UserState
  MatchesState(this.userState);

  // match details
  Map<String, Match> matchesCache = Map();

  List<String>? _pastMatchesIds;
  List<String>? _upcomingMatchesIds;
  List<String>? _goingMatchesIds;
  List<String>? _myOrganizedMatchesIds;

  // ratings per match
  Map<String, Ratings> _ratingsPerMatch = Map();

  // still to vote per match
  Map<String, Map<String, List<String>>> _stillToVote = Map();

  Ratings? getRatings(String matchId) => _ratingsPerMatch[matchId];

  List<Match>? getMatches() {
    return matchesCache.values.toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  List<Match>? getPastMatches() {
    return _pastMatchesIds
            ?.map((e) => matchesCache[e])
            .where((e) => e != null)
            .map((e) => e!)
            .toList() ??
        [];
  }

  List<Match>? getUpcomingMatches() {
    return _upcomingMatchesIds
            ?.map((e) => matchesCache[e])
            .where((e) => e != null)
            .map((e) => e!)
            .toList() ??
        [];
  }

  List<Match>? getGoingMatches() {
    return _goingMatchesIds
            ?.map((e) => matchesCache[e])
            .where((e) => e != null)
            .map((e) => e!)
            .toList() ??
        [];
  }

  List<Match>? getMyOrganizedMatches() {
    return _myOrganizedMatchesIds
            ?.map((e) => matchesCache[e])
            .where((e) => e != null)
            .map((e) => e!)
            .toList() ??
        [];
  }

  Match? getMatch(String matchId) => matchesCache[matchId];

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

  void _setMatch(Match m) {
    matchesCache[m.documentId] = m;
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

  Set<String> getSportCenters() => matchesCache.values
      .where((m) => m.sportCenterId != null)
      .map((e) => e.sportCenterId!)
      .toSet();

  Future<void> fetchGoingMatches(BuildContext context) async {
    var userState = context.read<UserState>();
    if (userState.currentUserId == null) return;

    Map<String, dynamic> params = {
      "with_user": userState.currentUserId!,
      "when": "future",
      "radius_km": 20,
      "lat": userState.getLocationInfo().lat,
      "lng": userState.getLocationInfo().lng,
      "version": 2,
    };

    var resp = await CloudFunctionsClient().get("matches", args: params);
    Map<String, dynamic> data =
        (resp == null) ? Map() : Map<String, dynamic>.from(resp);

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
          matchesCache[e!.documentId] = e;
          return e;
        })
        .where((e) => (!e.isTest || userState.isTestMode));

    _goingMatchesIds = matches.map((m) => m.documentId).toList();

    notifyListeners();
  }

  Future<void> fetchUpcomingMatches(BuildContext context) async {
    var userState = context.read<UserState>();
    if (userState.currentUserId == null) return;

    Map<String, dynamic> params = {
      "when": "future",
      "radius_km": 20,
      "lat": userState.getLocationInfo().lat,
      "lng": userState.getLocationInfo().lng,
      "version": 2,
    };

    var resp = await CloudFunctionsClient().get("matches", args: params);
    Map<String, dynamic> data =
        (resp == null) ? Map() : Map<String, dynamic>.from(resp);

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
          matchesCache[e!.documentId] = e;
          return e;
        })
        .where((e) => (!e.isTest || userState.isTestMode));

    _upcomingMatchesIds = matches.map((m) => m.documentId).toList();

    notifyListeners();
  }

  Future<void> fetchPastMatches(BuildContext context) async {
    var userState = context.read<UserState>();
    if (userState.currentUserId == null) return;

    Map<String, dynamic> params = {
      "when": "past",
      "with_user": userState.currentUserId!,
      "version": 2,
    };

    var resp = await CloudFunctionsClient().get("matches", args: params);
    Map<String, dynamic> data =
        (resp == null) ? Map() : Map<String, dynamic>.from(resp);

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
          matchesCache[e!.documentId] = e;
          return e;
        })
        .where((e) => (!e.isTest || userState.isTestMode));

    _pastMatchesIds = matches.map((m) => m.documentId).toList();

    notifyListeners();
  }

  Future<void> fetchMyOrganizedMatches(BuildContext context) async {
    var userState = context.read<UserState>();
    if (userState.currentUserId == null) return;

    Map<String, dynamic> params = {
      "organized_by": userState.currentUserId!,
    };

    var resp = await CloudFunctionsClient().get("matches", args: params);
    Map<String, dynamic> data =
        (resp == null) ? Map() : Map<String, dynamic>.from(resp);

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
          matchesCache[e!.documentId] = e;
          return e;
        })
        .where((e) => (!e.isTest || userState.isTestMode));

    _myOrganizedMatchesIds = matches.map((m) => m.documentId).toList();

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

  Future<void> refreshState(BuildContext context) async {
    logger.info("refreshing matches state");
    var futures = [
      fetchGoingMatches(context),
      fetchUpcomingMatches(context),
      fetchPastMatches(context),
      fetchMyOrganizedMatches(context),
    ];
    await Future.wait(futures);
    logger.info("refreshing matches state done: fetched ${_pastMatchesIds?.length} past, ${_upcomingMatchesIds?.length} upcoming, ${_goingMatchesIds?.length} going, ${_myOrganizedMatchesIds?.length} organized matches");
  }

  Future<Match> fetchMatch(String matchId) async {
    var resp = await CloudFunctionsClient()
        .get("matches/$matchId", args: {"version": 2});
    var match = Match.fromJson(resp!, matchId);

    _setMatch(match);

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

  void clear() {
    _pastMatchesIds = null;
    _upcomingMatchesIds = null;
    _goingMatchesIds = null;
    _myOrganizedMatchesIds = null;
    _ratingsPerMatch = Map();
    _stillToVote = Map();
    notifyListeners();
  }
}
