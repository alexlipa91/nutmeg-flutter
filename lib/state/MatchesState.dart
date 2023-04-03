import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/model/MatchRatings.dart';
import 'package:nutmeg/model/SportCenter.dart';
import 'package:nutmeg/model/UserDetails.dart';
import 'package:nutmeg/state/LoadOnceState.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:provider/provider.dart';

import '../controller/SportCentersController.dart';
import '../utils/LocationUtils.dart';


class MatchesState extends ChangeNotifier {

  // match details (do not initialize this map so that we can differentiate when no data has been fetched, i.e. map is null)
  Map<String, Match>? _matchesCache;

  Map<String, List<String>>? _matchesPerTab;

  // ratings per match
  Map<String, MatchRatings> _ratingsPerMatch = Map();

  MatchRatings? getRatings(String matchId) => _ratingsPerMatch[matchId];

  void addRating(String matchId, String gives, String receives, double score) {
    _ratingsPerMatch[matchId]?.add(receives, gives, score.toInt());
    notifyListeners();
  }

  List<Match>? getMatches() {
    if (_matchesPerTab == null)
      return null;
    return _matchesCache!.values.toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  List<Match>? getMatchesForTab(String tab) {
    if (_matchesPerTab == null || _matchesCache == null
        || _matchesPerTab![tab] == null)
      return null;
    return _matchesPerTab![tab]!.map((e) => _matchesCache![e]!).toList();
  }

  Match? getMatch(String matchId) =>
      (_matchesCache == null) ? null : _matchesCache![matchId];

  void setMatch(Match m) {
    if (_matchesCache == null)
      _matchesCache = Map();
    _matchesCache![m.documentId] = m;
    notifyListeners();
  }

  Set<String> getSportCenters() => _matchesCache!
      .values.where((m) => m.sportCenterId != null)
      .map((e) => e.sportCenterId!).toSet();

  // depends on which tab
  Future<void> fetchMatches(String tab, BuildContext context) async {
    var userState = context.read<UserState>();
    var params;
    switch (tab) {
      case "UPCOMING":
        params = {"when": "future"};
        break;
      case "GOING":
        // we will filter later on
        if (userState.currentUserId == null)
          return;
        params = {"with_user": userState.currentUserId!};
        break;
      case "PAST":
        if (userState.currentUserId == null)
          return;
        params = {"with_user": userState.currentUserId!};
        break;
      case "MY MATCHES":
        if (userState.currentUserId == null)
          return;
        params = {"organized_by": userState.currentUserId!};
        break;
    }

    var resp = await CloudFunctionsClient().callFunction("get_all_matches_v2", params);
    Map<String, dynamic> data = (resp == null) ? Map() : Map<String, dynamic>.from(resp);

    if (_matchesCache == null)
      _matchesCache = Map();

    // filter tests and get sportcenters to download
    Iterable<Match> matches = data.entries
        .map((element) {
      try {
        return Match.fromJson(Map<String, dynamic>.from(element.value),
            element.key);
      } catch (e, s) {
        print("Failed to deserialize match ${element.key.toString()}");
        print(e);
        print(s);
        FirebaseCrashlytics.instance.recordError(e, s,
            reason: 'failed to deserialize a match'
        );
        return null;
      }
    }).where((e) => e != null).map((e) {
      _matchesCache![e!.documentId] = e;
      return e;
    }).where((e) => (!e.isTest || context.read<UserState>().isTestMode));

    // further filtering client side
    if (tab == "UPCOMING") {
      matches = matches.where((m) => m.status != MatchStatus.unpublished);
      // regional filtering: 20km
      matches = matches.where((m) {
        var sp = getMatchSportCenter(context, m);
        return isWithinRadius(sp.lat, sp.lng, userState.getLat(), userState.getLng());
      });
    }
    if (tab == "GOING")
      matches = matches.where((m) => m.dateTime.isAfter(DateTime.now()));
    if (tab == "PAST")
      matches = matches.where((m) => m.dateTime.isBefore(DateTime.now()));

    if (_matchesPerTab == null)
      _matchesPerTab = Map();
    _matchesPerTab![tab] = matches.map((m) => m.documentId).toList();

    notifyListeners();
  }

  Future<MatchRatings?> fetchRatings(String matchId) async {
    var r = await CloudFunctionsClient().callFunction("get_ratings_by_match_v3", {
      "match_id": matchId
    });
    if (r == null)
      return null;

    _ratingsPerMatch[matchId] = MatchRatings.fromJson(r, matchId);
    return _ratingsPerMatch[matchId];
  }

  List<String>? stillToVote(String matchId, UserDetails ud) {
    var match = _matchesCache![matchId];
    var matchRatings = _ratingsPerMatch[matchId];

    if (match == null)
      throw Exception("Match $matchId not found");

    if (matchRatings == null)
      return null;

    var toVote = match.getGoingUsersByTime().toSet();
    toVote.remove(ud.documentId);
    matchRatings.ratingsReceived.forEach((receiver, given) {
      if (given.keys.contains(ud.documentId)) {
        toVote.remove(receiver);
      }
    });
    return toVote.toList();
  }

  SportCenter getMatchSportCenter(BuildContext context, Match m) =>
      m.sportCenter ??
          context.read<LoadOnceState>().getSportCenter(m.sportCenterId!)!;

  Future<void> refreshState(BuildContext context) async {
    await Future.wait(["UPCOMING", "PAST", "GOING", "MY MATCHES"]
        .map((tab) => fetchMatches(tab, context)
    ));
    await Future.wait(getSportCenters()
        .map((s) => SportCentersController.refresh(context, s)));
  }

  Future<Match> fetchMatch(String matchId) async {
    var resp = await CloudFunctionsClient().get("matches/$matchId");
    var match = Match.fromJson(resp!, matchId);

    setMatch(match);

    return match;
  }

  Future<void> editMatch(String matchId, Map<String, dynamic> data) async {
    await CloudFunctionsClient().callFunction("edit_match",
        {"id": matchId, "data": data});

    var resp = await CloudFunctionsClient().callFunction("get_match_v2",
        {'id': matchId});
    var match = Match.fromJson(resp!, matchId);

    setMatch(match);
  }
}