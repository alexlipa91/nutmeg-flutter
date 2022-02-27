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

  UserDetails _userDetails;

  Map<String, List<UserDetails>> _usersStillToRate;

  bool isTestMode = false;

  UserDetails getUserDetails() => _userDetails;

  void setUsersStillToRate(String matchId, List<UserDetails> users) {
    if (_usersStillToRate == null) {
      _usersStillToRate = Map();
    }

    _usersStillToRate[matchId] = users;
    notifyListeners();
  }

  List<UserDetails> getUsersStillToRate(String match) {
    return _usersStillToRate[match];
  }

  void setUserDetails(UserDetails u) {
    _userDetails = u;
    notifyListeners();
  }

  void setTestMode(bool value) {
    isTestMode = value;
    notifyListeners();
  }

  bool isLoggedIn() => _userDetails != null;
}

class UsersState {
  static Map<String, UserDetails> _userDetails;

  static void _init() {
    if (_userDetails == null) {
      _userDetails = Map();
    }
  }

  static UserDetails getUserDetails(String userId) {
    _init();
    return _userDetails[userId];
  }

  static void setUserDetails(String userId, UserDetails userDetails) {
    _init();
    _userDetails[userId] = userDetails;
  }
}
