import 'package:flutter/cupertino.dart';
import "package:collection/collection.dart";

import '../model/Sport.dart';
import '../model/SportCenter.dart';


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
