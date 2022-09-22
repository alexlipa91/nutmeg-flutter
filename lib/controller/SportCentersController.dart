import 'package:flutter/cupertino.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:provider/provider.dart';

import '../model/SportCenter.dart';
import '../state/LoadOnceState.dart';


class SportCentersController {

  static Future<SavedSportCenter> refresh(BuildContext context, String sportCenterId) async {
    var sportCentersState = context.read<LoadOnceState>();

    var data = await CloudFunctionsClient().callFunction("get_sportcenter",
        {"id" : sportCenterId});

    var sportCenter = SavedSportCenter.fromJson(data, sportCenterId);
    sportCentersState.setSportCenter(sportCenterId, sportCenter);

    return sportCenter;
  }

  static Future<List<Map<String, dynamic>>> getPlacePrediction(String query) async {
    Map<String, dynamic> data = await CloudFunctionsClient()
        .callFunction("get_location_predictions_from_query", {"query" : query})
        ?? {};

    return List<Map<String, dynamic>>.from(data["predictions"] ?? []);
  }

  static Future<List<SportCenter>> getUserSportCenters(String uid) async {
    Map<String, dynamic> data = await CloudFunctionsClient()
        .callFunction("get_user_sportcenters", {"user_id" : uid})
        ?? {};

    return data.entries.map((e) => SportCenter.fromJson(e.value, e.key))
        .toList();
  }
}
