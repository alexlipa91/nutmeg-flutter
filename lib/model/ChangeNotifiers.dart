import 'package:flutter/cupertino.dart';
import 'Model.dart';
import "package:collection/collection.dart";

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

class LoadOnceState extends ChangeNotifier {
  Map<String, SportCenter> _sportCenters;
  Map<String, Sport> _sports;
  List<String> joinedGifs;

  void setSportCenters(List<SportCenter> newSportCenters) {
    _sportCenters = newSportCenters.groupListsBy((e) => e.placeId)
        .map((key, value) => MapEntry(key, value.first));
    notifyListeners();
  }

  void setSports(List<Sport> newSports) {
    _sports = newSports.groupListsBy((e) => e.documentId)
        .map((key, value) => MapEntry(key, value.first));
    notifyListeners();
  }

  // fixme break with exception here
  SportCenter getSportCenter(String id) => _sportCenters[id];

  Sport getSport(String id) => _sports[id];

  List<Sport> getSports() => _sports.values.toList();

  List<SportCenter> getSportCenters() => _sportCenters.values.toList();

  String getRandomGif() {
    joinedGifs..shuffle();
    return joinedGifs.first;
  }
}

class UserState extends ChangeNotifier {
  // holds state for all users' data (both logged in user and others)

  String _currentUserId;
  bool _isTestMode = false;
  Map<String, UserDetails> _usersDetails = Map();

  // fixme maybe move it somewhere else
  Map<String, List<UserDetails>> _usersStillToRate = Map();

  String get currentUserId => _currentUserId;

  UserDetails getLoggedUserDetails() => _usersDetails[_currentUserId];

  void setUsersStillToRate(String matchId, List<UserDetails> users) {
    _usersStillToRate[matchId] = users;
    notifyListeners();
  }

  List<UserDetails> getUsersStillToRate(String match) => _usersStillToRate[match];

  void setCurrentUserDetails(UserDetails u) {
    _currentUserId = u.documentId;
    if (u.isAdmin) {
      _isTestMode = true;
    }
    setUserDetail(u);
  }

  void setUserDetail(UserDetails u) {
    _usersDetails[u.documentId] = u;
    notifyListeners();
  }

  UserDetails getUserDetail(String uid) => _usersDetails[uid];

  bool get isTestMode => _isTestMode;

  void setTestMode(bool value) {
    _isTestMode = value;
    notifyListeners();
  }

  bool isLoggedIn() => _currentUserId != null;

  void logout() {
    _currentUserId = null;
    notifyListeners();
  }
}