import 'package:flutter/cupertino.dart';

import '../model/Model.dart';import "package:collection/collection.dart";


enum MatchStatusForUser {
  join,             // user can join the match
  leave,            // user can leave the match
  full,             // match is full
  to_rate,          // match is in the past, within rating window and user still has players to rate
  no_more_to_rate,  // match is in the past, within rating window and user has rated everyone
  rated,            // match is in the past and after rating window (man of the match is available)
  canceled          // canceled
}


class MatchesState extends ChangeNotifier {
  Map<String, Match> _matches;
  Map<String, MatchStatusForUser> _matchesStatus;

  void setMatches(List<Match> newMatches) {
    _matches = newMatches.groupListsBy((e) => e.documentId)
        .map((key, value) => MapEntry(key, value.first));
    notifyListeners();
  }

  void setMatchStatus(String matchId, MatchStatusForUser matchStatus) {
    if (_matchesStatus == null) {
      _matchesStatus = Map();
    }

    _matchesStatus[matchId] = matchStatus;
    notifyListeners();
  }

  List<Match> getMatches() {
    if (_matches == null) {
      return null;
    }
    return _matches.values.toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  List<Match> getMatchesInFuture() => getMatches()
      .where((m) => m.dateTime.isAfter(DateTime.now()))
      .toList();

  int getNumPlayedByUser(String userId) => _matches.values
      .where((m) => m.cancelledAt == null
      && m.dateTime.isBefore(DateTime.now())
      && m.going.containsKey(userId))
      .length;

  Match getMatch(String matchId) => (_matches == null) ? null : _matches[matchId];

  MatchStatusForUser getMatchStatus(String matchId) {
    if (_matchesStatus == null) {
      _matchesStatus = Map();
    }
    return _matchesStatus[matchId];
  }

  void setMatch(Match m) {
    _matches[m.documentId] = m;
    notifyListeners();
  }
}
