import 'package:flutter/cupertino.dart';
import 'Model.dart';
import "package:collection/collection.dart";


class MatchesState extends ChangeNotifier {
  Map<String, Match> _matches;
  Map<String, String> _images;

  void setMatches(List<Match> newMatches) {
    _matches = newMatches.groupListsBy((e) => e.documentId)
        .map((key, value) => MapEntry(key, value.first));
    notifyListeners();
  }

  List<Match> getMatches() => _matches.values.toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime));

  String getImageUrl(String matchId) => _images[matchId];

  List<Match> getMatchesInFuture() => getMatches()
      .where((m) => m.dateTime.difference(DateTime.now()).inHours > 2)
      .toList();

  Match getMatch(String matchId) =>
      _matches[matchId];

  void setMatch(Match m) {
    _matches[m.documentId] = m;
    notifyListeners();
  }

  void setImages(Map<String, String> images) {
    _images = images;
    notifyListeners();
  }

  Map<String, String> getImages() => _images;
}

class SportCentersState extends ChangeNotifier {
  Map<String, SportCenter> _sportCenters;

  void setSportCenters(List<SportCenter> newSportCenters) {
    _sportCenters = newSportCenters.groupListsBy((e) => e.placeId)
        .map((key, value) => MapEntry(key, value.first));
    notifyListeners();
  }

  // fixme break with exception here
  SportCenter getSportCenter(String id) => _sportCenters[id];

  List<SportCenter> getSportCenters() => _sportCenters.values.toList();
}

class UserState extends ChangeNotifier {

  UserDetails _userDetails;

  UserDetails getUserDetails() => _userDetails;

  void setUserDetails(UserDetails u) {
    _userDetails = u;
    notifyListeners();
  }

  bool isLoggedIn() => _userDetails != null;
}
