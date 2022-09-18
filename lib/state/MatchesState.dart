import 'package:flutter/cupertino.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/model/MatchRatings.dart';
import 'package:nutmeg/model/UserDetails.dart';


class MatchesState extends ChangeNotifier {

  // match details (do not initialize this map so that we can differentiate when no data has been fetched, i.e. map is null)
  Map<String, Match>? _matches;

  // ratings per match
  Map<String, MatchRatings> _ratingsPerMatch = Map();

  MatchRatings? getRatings(String matchId) => _ratingsPerMatch[matchId];

  void addRating(String matchId, String gives, String receives, double score) {
    _ratingsPerMatch[matchId]?.add(receives, gives, score.toInt());
    notifyListeners();
  }

  List<Match>? getMatches() {
    if (_matches == null)
      return null;
    return _matches!.values.toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  List<Match> getMatchesInFuture() {
    var matches = getMatches() ?? List<Match>.empty();
    var res = matches.where((m) {
      return m.dateTime.isAfter(DateTime.now());
    }).toList();
    return res;
  }

  Match? getMatch(String matchId) =>
      (_matches == null) ? null : _matches![matchId];

  void setMatch(Match m) {
    if (_matches == null)
      _matches = Map();
    _matches![m.documentId] = m;
    notifyListeners();
  }

  Future<List<Match>> fetchMatches() async {
    var resp = await CloudFunctionsClient().callFunction("get_all_matches_v2", {});
    Map<String, dynamic> data =
    (resp == null) ? Map() : Map<String, dynamic>.from(resp);

    List<Match> matches = data.entries
        .map((e) {
      try {
        return Match.fromJson(Map<String, dynamic>.from(e.value), e.key);
      } catch (e, s) {
        print("Failed to deserialize match");
        print(e);
        print(s);
        return null;
      }
    }).where((e) => e != null).map((e) => e!).toList();

    _matches = Map.fromEntries(matches.map((e) => MapEntry((e.documentId), e)));
    notifyListeners();

    return matches;
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
    var match = _matches![matchId];
    var matchRatings = _ratingsPerMatch[matchId];

    if (match == null)
      throw Exception("Match $matchId not found");

    if (matchRatings == null)
      return null;

    var toVote = (match.going ?? {}) .keys.toSet();
    toVote.remove(ud.documentId);
    matchRatings.ratingsReceived.forEach((receiver, given) {
      if (given.keys.contains(ud.documentId)) {
        toVote.remove(receiver);
      }
    });
    return toVote.toList();
  }
}