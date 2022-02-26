import 'package:flutter/cupertino.dart';
import 'Model.dart';
import "package:collection/collection.dart";


class MatchesState extends ChangeNotifier {
  Map<String, Match> _matches;

  void setMatches(List<Match> newMatches) {
    _matches = newMatches.groupListsBy((e) => e.documentId)
        .map((key, value) => MapEntry(key, value.first));
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
  bool isTestMode = false;

  UserDetails getUserDetails() => _userDetails;

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
