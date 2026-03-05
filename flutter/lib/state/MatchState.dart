import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/config/app_config.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';

final logger = CrashlyticsLogger("MatchState");

class MatchState extends ChangeNotifier {
  final String _matchId;

  UserState? _userState;
  Match? _match;

  MatchState(this._matchId, this._userState);

  MatchState.fromMatch(Match match, UserState userState)
      : _matchId = match.documentId,
        _userState = userState,
        _match = match;

  Ratings? _ratings;
  Match? get match => _match;

  Ratings? get ratings => _ratings;

  String? get matchId => _matchId;

  bool isLoggedUserInMatch() {
    return _match?.isUserGoing(_userState?.getLoggedUserDetails()) ?? false;
  }

  bool isLoggedUserGoing() =>
      _match?.isUserGoing(_userState?.getLoggedUserDetails()) ?? false;

  bool isLoggedUserOrganizer() {
    if (AppConfig.testModeOrganizer) {
      return _match != null;
    }
    return _match?.organizerId != null &&
        _match?.organizerId == _userState?.getLoggedUserId();
  }

  Future<void> addLoggedInUserToMatch() async {
    await CloudFunctionsClient().post("matches/$_matchId/users/add", {
      // FIXME used auth user id
      'user_id': _userState?.getLoggedUserId(),
    });
    await fetchMatch();
  }

  Future<void> addUserToMatch(String userId) async {
    await CloudFunctionsClient().post("matches/$_matchId/users/add", {
      'user_id': userId,
    });
    await fetchMatch();
  }

  Future<void> addGuestToMatch(String guestName) async {
    await CloudFunctionsClient().post("matches/$_matchId/users/add", {
      'guest_name': guestName,
    });
    await fetchMatch();
  }

  Future<void> removeLoggedInUserFromMatch() async {
    await CloudFunctionsClient().post("matches/$_matchId/users/remove", {});
    await fetchMatch();
  }

  bool isLoggedUserInWaitList() {
    return _match?.isUserInWaitList(_userState?.getLoggedUserDetails()) ?? false;
  }

  Future<void> addLoggedInUserToWaitList() async {
    await CloudFunctionsClient().post("matches/$_matchId/waitlist/add", {
      'user_id': _userState?.getLoggedUserId(),
    });
    await fetchMatch();
  }

  Future<void> removeLoggedInUserFromWaitList() async {
    await CloudFunctionsClient().post("matches/$_matchId/waitlist/remove", {});
    await fetchMatch();
  }

  Future<void> promoteUserFromWaitList(String userId) async {
    await CloudFunctionsClient().post("matches/$_matchId/waitlist/promote", {
      'user_id': userId,
    });
    await fetchMatch();
  }

  Future<void> removeUserFromMatch(String userId) async {
    await CloudFunctionsClient().post("matches/$_matchId/users/remove_other", {
      "user_id": userId,
    });
    await fetchMatch();
  }

  Future<void> setManualPaymentStatus(String userId, String status) async {
    await editMatch({"going.$userId.manualPaymentStatus": status});
  }

  Future<void> postUserRatings(Map<String, int> ratings) async {
    await CloudFunctionsClient()
        .post("matches/$_matchId/ratings/add_multi", ratings);
  }

  void saveManualTeams(List<List<String>> manualTeams) async {
    await editMatch({
      "teams.manual.players.a": manualTeams[0],
      "teams.manual.players.b": manualTeams[1],
    });
  }

  void eraseManualTeams() async {
    await editMatch({
      "teams.manual": {},
    });
  }

  List<String> getUsersToRate() {
    return _match!.going.keys
        .where((id) => id != _userState!.getLoggedUserId()!)
        .toList();
  }

  // BACKEND methods
  Future<void> fetchMatch() async {
    logger.info("fetching match $_matchId");
    var resp = await CloudFunctionsClient()
        .get("matches/$_matchId", args: {"version": 2});

    var match = Match.fromJson(resp!, _matchId);

    setMatch(match);
  }

  Future<void> fetchRatings() async {
    // Read from the ratings summary embedded on the match doc (fast path)
    if (_match?.ratingSummary != null) {
      setRatings(_match!.ratingSummary!);
      return;
    }

    // Fallback: call the API for matches not yet backfilled
    // TODO: remove this fallback once all matches have a ratings summary
    var r = await CloudFunctionsClient().get("matches/$matchId/ratings");
    if (r == null) return;

    var ratings = Ratings.fromJson(Map<String, dynamic>.from(r));
    setRatings(ratings);
  }

  // NOTIFIERS

  void notifyListeners() {
    logger.info("MatchState for $_matchId notifying listeners");
    super.notifyListeners();
  }

  void setMatch(Match match) {
    _match = match;
    notifyListeners();
  }

  void setRatings(Ratings ratings) {
    _ratings = ratings;
    notifyListeners();
  }

  Future<void> editMatch(Map<String, dynamic> data) async {
    await CloudFunctionsClient().post("matches/$matchId", data);
    await fetchMatch();
    notifyListeners();
  }
}
