import 'package:flutter/cupertino.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/model/LocationInfo.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/state/MatchState.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';
import 'package:nutmeg/utils/LocationUtils.dart';

final logger = CrashlyticsLogger("MatchesState");

class MatchesState extends ChangeNotifier {
  UserState? userState;

  // device location
  LocationInfo? _deviceLocationInfo;

  MatchesState() {}

  // match details
  Map<String, MatchState> _matches = Map();

  List<String>? _pastMatchesIds;
  List<String>? _upcomingMatchesIds;
  List<String>? _goingMatchesIds;
  List<String>? _myOrganizedMatchesIds;

  List<MatchState>? getPastMatches() {
    return _pastMatchesIds
        ?.map((e) => _matches[e])
        .where((e) => e != null)
        .map((e) => e!)
        .toList();
  }

  List<MatchState>? getUpcomingMatches() {
    return _upcomingMatchesIds
        ?.map((e) => _matches[e])
        .where((e) => e != null)
        .map((e) => e!)
        .toList();
  }

  List<MatchState>? getGoingMatches() {
    return _goingMatchesIds
        ?.map((e) => _matches[e])
        .where((e) => e != null)
        .map((e) => e!)
        .toList();
  }

  List<MatchState>? getMyOrganizedMatches() {
    return _myOrganizedMatchesIds
        ?.map((e) => _matches[e])
        .where((e) => e != null)
        .map((e) => e!)
        .toList();
  }

  void addToGoingMatches(String matchId) {
    _goingMatchesIds?.add(matchId);
    notifyListeners();
  }

  MatchState getMatch(String matchId) {
    if (!_matches.containsKey(matchId)) {
      _matches[matchId] = MatchState(matchId, userState);
    }
    return _matches[matchId]!;
  }

  Set<String> getSportCenters() => _matches.values
      .where((m) => m.match!.sportCenterId != null)
      .map((e) => e.match!.sportCenterId!)
      .toSet();

  LocationInfo? get locationInfo => _deviceLocationInfo;

  void setLocationInfo(LocationInfo locationInfo) {
    _deviceLocationInfo = locationInfo;
    notifyListeners();
  }

  void updateMatchStateBasedOnUser(UserState newUserState) {
    if (newUserState.haveUserChanged()) {
      logger.info("updating matches state based on user because user changed");
      _pastMatchesIds = null;
      _upcomingMatchesIds = null;
      _goingMatchesIds = null;
      _myOrganizedMatchesIds = null;
      notifyListeners();

      fetchGoingMatches();
      fetchUpcomingMatches();
      fetchPastMatches();
      fetchMyOrganizedMatches();
    }

    userState = newUserState;
  }

  Match? deserializeMatch(MapEntry<String, dynamic> element) {
    try {
      return Match.fromJson(
          Map<String, dynamic>.from(element.value), element.key);
    } catch (e, s) {
      logger.severe(
          "Failed to deserialize match ${element.key.toString()}", e, s);
      return null;
    }
  }

  void notifyListeners() {
    logger.info("MatchesState notifying listeners");
    super.notifyListeners();
  }

  Future<void> fetchLocation() async {
    var location = await getLocationFromIP();
    _deviceLocationInfo =
        location ?? LocationInfo("ES", "Barcelona", 41.385063, 2.173404);
    notifyListeners();
  }

  Future<void> fetchGoingMatches() async {
    if (userState?.getLoggedUserId() == null) return;

    var resp = await CloudFunctionsClient()
        .get("v2/matches/user", args: {"when": "future"});
    Map<String, dynamic> data =
        (resp == null) ? Map() : Map<String, dynamic>.from(resp);

    List<String> matches = [];

    // filter tests and get sportcenters to download
    data.entries
        .map((element) => deserializeMatch(element))
        .where((e) => e != null)
        .where((e) => (e!.isTest || userState!.isTestMode))
        .forEach((m) {
      _matches[m!.documentId] = MatchState.fromMatch(m, userState!);
      matches.add(m.documentId);
    });

    _goingMatchesIds = matches;

    notifyListeners();
  }

  Future<void> fetchUpcomingMatches() async {
    var locationForQuery =
        userState?.getLoggedUserDetails()?.location ?? _deviceLocationInfo;
    // still loading location so we don't query
    if (locationForQuery == null) return;

    var resp = await CloudFunctionsClient().get("v2/matches", args: {
      "when": "future",
      "location": "${locationForQuery.city},${locationForQuery.country}"
    });
    Map<String, dynamic> data =
        (resp == null) ? Map() : Map<String, dynamic>.from(resp);

    List<String> matches = [];

    // filter tests and get sportcenters to download
    data.entries
        .map((element) => deserializeMatch(element))
        .where((e) => e != null)
        .where((e) => (e!.isTest || userState!.isTestMode))
        .forEach((m) {
      _matches[m!.documentId] = MatchState.fromMatch(m, userState!);
      matches.add(m.documentId);
    });

    _upcomingMatchesIds = matches;

    notifyListeners();
  }

  Future<void> fetchPastMatches() async {
    if (userState?.getLoggedUserId() == null) return;

    var resp = await CloudFunctionsClient()
        .get("v2/matches/user", args: {"when": "past"});
    Map<String, dynamic> data =
        (resp == null) ? Map() : Map<String, dynamic>.from(resp);

    List<String> matches = [];

    // filter tests and get sportcenters to download
    data.entries
        .map((element) => deserializeMatch(element))
        .where((e) => e != null)
        .where((e) => (e!.isTest || userState!.isTestMode))
        .forEach((m) {
      _matches[m!.documentId] = MatchState.fromMatch(m, userState!);
      matches.add(m.documentId);
    });

    _pastMatchesIds = matches;

    notifyListeners();
  }

  Future<void> fetchMyOrganizedMatches() async {
    if (userState?.getLoggedUserId() == null) return;

    var resp = await CloudFunctionsClient().get("v2/matches/organizer");
    Map<String, dynamic> data =
        (resp == null) ? Map() : Map<String, dynamic>.from(resp);

    List<String> matches = [];

    // filter tests and get sportcenters to download
    data.entries
        .map((element) => deserializeMatch(element))
        .where((e) => e != null)
        .where((e) => (e!.isTest || userState!.isTestMode))
        .forEach((m) {
      _matches[m!.documentId] = MatchState.fromMatch(m, userState!);
      matches.add(m.documentId);
    });

    _myOrganizedMatchesIds = matches;

    notifyListeners();
  }

  Future<String> createMatch(Match match) async {
    var resp = await CloudFunctionsClient().post("matches", match.toJson());
    var id = resp!["id"];
    match.documentId = id;
    _matches[id] = MatchState.fromMatch(match, userState!);
    _myOrganizedMatchesIds?.add(id);
    notifyListeners();
    return id;
  }

  Future<void> refreshState() async {
    logger.info("refreshing matches state");
    var futures = [
      fetchGoingMatches(),
      fetchUpcomingMatches(),
      fetchPastMatches(),
      fetchMyOrganizedMatches(),
    ];
    await Future.wait(futures);
    logger.info(
        "refreshing matches state done: fetched ${_pastMatchesIds?.length} past, ${_upcomingMatchesIds?.length} upcoming, ${_goingMatchesIds?.length} going, ${_myOrganizedMatchesIds?.length} organized matches");
  }

  void clear() {
    _pastMatchesIds = null;
    _upcomingMatchesIds = null;
    _goingMatchesIds = null;
    _myOrganizedMatchesIds = null;
    notifyListeners();
  }
}
