import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import '../model/SportCenter.dart';


class SportCentersController {

  static Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    Map<String, dynamic> data = await CloudFunctionsClient()
        .callFunction("get_placeid_info", {"place_id" : placeId})
        ?? {};

    return data;
  }

  static Future<List<SportCenter>> getSavedSportCenters() async {
    Map<String, dynamic> data = await CloudFunctionsClient()
        .callFunction("get_sportcenters", {})
        ?? {};

    return data.entries.map((e) => SportCenter
        .fromJson(Map<String, dynamic>.from(e.value), e.key))
        .toList();
  }

  static Future<List<SportCenter>> getUserSportCenters(String uid) async {
    Map<String, dynamic> data = await CloudFunctionsClient()
        .callFunction("get_user_sportcenters", {"user_id" : uid})
        ?? {};

    return data.entries.map((e) => SportCenter
        .fromJson(Map<String, dynamic>.from(e.value), e.key))
        .toList();
  }

  static Future<void> addSportCenterFromPlace(
      String userId,
      SportCenter sportCenter) async {
    await CloudFunctionsClient().callFunction("add_user_sportcenter_from_place_id", {
      "place_id": sportCenter.placeId,
      "additional_info": sportCenter.toJson(),
      "user_id": userId
    });
  }
}
