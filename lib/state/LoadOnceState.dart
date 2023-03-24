import 'package:universal_io/io.dart';

import 'package:flutter/cupertino.dart';
import 'package:nutmeg/db/SportCentersFirestore.dart';

import '../model/Sport.dart';
import '../model/SportCenter.dart';


class LoadOnceState extends ChangeNotifier {
  static String localeStr = const String.fromEnvironment("LOCALE", defaultValue: "");

  Locale locale = Locale((localeStr == "") ? Platform.localeName : localeStr);
  
  Map<String, SavedSportCenter> _sportCenters = Map();
  List<Sport> _sports = [Sport("5v5"), Sport("6v6")];
  late List<String> joinedGifs;

  void setSportCenter(String sportCenterId, SavedSportCenter sportCenter) {
    _sportCenters[sportCenterId] = sportCenter;
    notifyListeners();
  }

  SavedSportCenter? getSportCenter(String id) => _sportCenters[id];

  List<Sport> getSports() => _sports.toList();

  Future<List<SavedSportCenter>> fetchSportCenters() async {
    var sportCenters = await SportCentersFirestore.getSportCenters();
    sportCenters.forEach((e) {
      _sportCenters[e.placeId] = e;
    });
    return sportCenters;
  }

  List<SavedSportCenter> getSportCenters() => _sportCenters.values.toList();

  String getRandomGif() {
    joinedGifs..shuffle();
    return joinedGifs.first;
  }

  void setLocale(String locale) {
    this.locale = Locale(locale);
    notifyListeners();
  }
}
