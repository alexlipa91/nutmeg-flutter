import 'package:flutter/cupertino.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/model/Match.dart';
import "package:collection/collection.dart";
import 'package:nutmeg/model/MatchRatings.dart';
import 'package:nutmeg/model/UserDetails.dart';


class MatchesState extends ChangeNotifier {

  // match details
  Map<String, Match> _matches = Map();

  // ratings per match
  Map<String, MatchRatings> _ratingsPerMatch = Map();

  void setMatches(List<Match> newMatches) {
    _matches = newMatches.groupListsBy((e) => e.documentId)
        .map((key, value) => MapEntry(key, value.first));
    notifyListeners();
  }

  MatchRatings getRatings(String matchId) => _ratingsPerMatch[matchId];

  void addRating(String matchId, String gives, String receives, double score) {
    _ratingsPerMatch[matchId].add(receives, gives, score.toInt());
    notifyListeners();
  }

  List<Match> getMatches() {
    return _matches.values.toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  List<Match> getMatchesInFuture() => getMatches()
      .where((m) => m.dateTime.isAfter(DateTime.now()))
      .toList();

  Match getMatch(String matchId) => _matches[matchId];

  void setMatch(Match m) {
    _matches[m.documentId] = m;
    notifyListeners();
  }

  Future<MatchRatings> fetchRatings(String matchId) async {
    var r = await CloudFunctionsClient().callFunction("get_ratings_by_match_v2", {
      "match_id": matchId
    });
    _ratingsPerMatch[matchId] = MatchRatings.fromJson(r, matchId);
    return _ratingsPerMatch[matchId];
  }

  MatchStatusForUser getMatchStatusForUser(String matchId, UserDetails ud) {
    var match = _matches[matchId];
    if (match == null) {
      return null;
    }

    MatchStatusForUser matchStatusForUser;

    if (ud != null && match.isUserGoing(ud)) {
      if (match.status == MatchStatus.open || match.status == MatchStatus.cancelled) {
        matchStatusForUser = MatchStatusForUser.canLeave;
      } else if (match.status == MatchStatus.pre_playing) {
        matchStatusForUser = MatchStatusForUser.cannotLeave;
      } else if (match.status == MatchStatus.to_rate) {
        var usersToVote = stillToVote(matchId, ud);

        if (usersToVote == null) {
          return null;
        }

        if (usersToVote.isEmpty) {
          matchStatusForUser = MatchStatusForUser.no_more_to_rate;
        } else {
          matchStatusForUser = MatchStatusForUser.to_rate;
        }
      }
    } else {
      if (match.status == MatchStatus.cancelled || match.status == MatchStatus.full) {
        matchStatusForUser = MatchStatusForUser.cannotJoin;
      } else {
        matchStatusForUser = MatchStatusForUser.canJoin;
      }
    }

    return matchStatusForUser;
  }

  List<String> stillToVote(String matchId, UserDetails ud) {
    var match = _matches[matchId];
    var matchRatings = _ratingsPerMatch[matchId];

    if (match == null || matchRatings == null) {
      return null;
    }

    var toVote = match.going.keys.toSet();
    toVote.remove(ud.documentId);
    matchRatings.ratingsReceived.forEach((receiver, given) {
      if (given.keys.contains(ud.documentId)) {
        toVote.remove(receiver);
      }
    });
    return toVote.toList();
  }
}
