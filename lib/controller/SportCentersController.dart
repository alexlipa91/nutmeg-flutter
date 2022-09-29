import 'package:flutter/cupertino.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:provider/provider.dart';

import '../model/Match.dart';
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

    List predictions = data["predictions"] ?? [];

    List<Map<String, dynamic>> results = [];

    predictions.forEach((element) {
      results.add(Map<String, dynamic>.from(element));
    });

    return results;
  }

  static Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    Map<String, dynamic> data = await CloudFunctionsClient()
        .callFunction("get_placeid_info", {"place_id" : placeId})
        ?? {};

    return data;
  }

  static Future<List<SportCenter>> getUserSportCenters(String uid) async {
    Map<String, dynamic> data = await CloudFunctionsClient()
        .callFunction("get_user_sportcenters", {"user_id" : uid})
        ?? {};

    return data.entries.map((e) => SportCenter.fromJson(e.value, e.key))
        .toList();
  }

  static SportCenter? getSportCenter(BuildContext context, Match? match) {
    return (match == null)
        ? null
        : match.sportCenter ??
        context.watch<LoadOnceState>().getSportCenter(match.sportCenterId!);
  }
}
