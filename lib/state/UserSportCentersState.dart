import 'package:flutter/cupertino.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';

import '../controller/SportCentersController.dart';
import '../model/SportCenter.dart';


class UserSportCentersState extends ChangeNotifier {

  List<SportCenter>? _sportCenters;

  void fetchSportCenters(String userId) async {
    _sportCenters = await SportCentersController.getUserSportCenters(userId);
    notifyListeners();
  }

  List<SportCenter>? getSportCenters() => _sportCenters;

  void addSportCenter(String uid, SportCenter sportCenter) {
    _sportCenters!.add(sportCenter);

    CloudFunctionsClient().callFunction("add_user_sportcenter", {
      "user_id": uid,
      "sport_center": sportCenter.toJson()
    });

    notifyListeners();
  }
}