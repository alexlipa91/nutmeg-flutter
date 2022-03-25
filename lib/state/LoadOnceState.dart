import 'package:flutter/cupertino.dart';
import 'package:nutmeg/db/SportCentersFirestore.dart';

import '../model/Sport.dart';
import '../model/SportCenter.dart';


class LoadOnceState extends ChangeNotifier {
  Map<String, SportCenter> _sportCenters = Map();
  List<Sport> _sports = [Sport("5v5"), Sport("6v6")];
  List<String> joinedGifs;

  void setSportCenter(String sportCenterId, SportCenter sportCenter) {
    _sportCenters[sportCenterId] = sportCenter;
    notifyListeners();
  }

  SportCenter getSportCenter(String id) => _sportCenters[id];

  List<Sport> getSports() => _sports.toList();

  Future<List<SportCenter>> fetchSportCenters() async {
    var sportCenters = await SportCentersFirestore.getSportCenters();
    sportCenters.forEach((e) {
      _sportCenters[e.placeId] = e;
    });
    return sportCenters;
  }

  List<SportCenter> getSportCenters() => _sportCenters.values.toList();

  String getRandomGif() {
    joinedGifs..shuffle();
    return joinedGifs.first;
  }
}
