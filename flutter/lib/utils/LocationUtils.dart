import 'package:flutter/material.dart';
import 'package:nutmeg/model/LocationInfo.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';
import 'package:provider/provider.dart';
import '../api/CloudFunctionsUtils.dart';
import '../config/app_config.dart';
import '../state/LoadOnceState.dart';

final logger = CrashlyticsLogger('LocationUtils');

const placesApiKey = AppConfig.googleApiKey;

String buildMapUrl(double lat, double lng) =>
    "https://maps.googleapis.com/maps/api/staticmap?center=" +
    lat.toString() +
    "," +
    lng.toString() +
    "&key=$placesApiKey" +
    "&zoom=16&size=600x300&markers=color:red%7C" +
    lat.toString() +
    "," +
    lng.toString();

class PredictionMatch {
  int offset;
  int length;

  PredictionMatch(this.offset, this.length);
}

class PredictionResult {
  String description;
  List<PredictionMatch> matches;
  String placeId;

  PredictionResult(this.description, this.matches, this.placeId);
}

// this needs to happen server side because placesApi doesn't work with CORS
Future<List<PredictionResult>> getPlacePrediction(String query) async {
  Map<String, dynamic> data = await CloudFunctionsClient()
          .get("locations/predictions", args: {"query": query}) ??
      {};

  List predictions = data["predictions"] ?? [];

  List<PredictionResult> results = [];

  predictions.forEach((element) {
    var e = Map<String, dynamic>.from(element);
    results.add(PredictionResult(
        e["description"],
        List<PredictionMatch>.from(e["matched_substrings"]
            .map((m) => PredictionMatch(m["offset"], m["length"]))),
        e["place_id"]));
  });

  return results;
}

Future<List<PredictionResult>> getCitiesPrediction(String query) async {
  Map<String, dynamic> data = await CloudFunctionsClient()
          .get("locations/cities", args: {"query": query}) ??
      {};
  List predictions = data["predictions"] ?? [];

  List<PredictionResult> results = [];

  predictions.forEach((element) {
    var e = Map<String, dynamic>.from(element);
    results.add(PredictionResult(
        e["description"],
        List<PredictionMatch>.from(e["matched_substrings"]
            .map((m) => PredictionMatch(m["offset"], m["length"]))),
        e["place_id"]));
  });

  return results;
}

Future<LocationInfo?> getLocationFromIP() async {
  try {
    var data = await CloudFunctionsClient().get("locations/ip");
    if (data != null) {
      return LocationInfo(
          data['country'], data['city'], data['lat'], data['lng']);
    }
    return null;
  } catch (e, s) {
    logger.severe("Error getting location from IP", e, s);
    return null;
  }
}

Locale getLanguageLocaleWatch(BuildContext context) {
  var userSpecific =
      context.watch<UserState>().getLoggedUserDetails()?.language;
  if (userSpecific != null) return Locale(userSpecific);
  return context.watch<LoadOnceState>().locale;
}

Locale getLanguageLocaleRead(BuildContext context) {
  var userSpecific = context.read<UserState>().getLoggedUserDetails()?.language;
  if (userSpecific != null) return Locale(userSpecific);
  return context.read<LoadOnceState>().locale;
}
