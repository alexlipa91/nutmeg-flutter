import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tuple/tuple.dart';

import '../api/CloudFunctionsUtils.dart';
import '../state/LoadOnceState.dart';

final logger = Logger('LocationUtils');

const placesApiKey = String.fromEnvironment('GOOGLE_API_KEY');

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

Future<LocationInfo?> fetchLocationInfo(double lat, double lng) async {
  // uncomment to get amsterdam
  // lat = 52.3676; lng = 4.9041;
  try {
    var resp = await CloudFunctionsClient()
        .get("locations/coordinates", args: {"lat": lat, "lng": lng});
    return LocationInfo.fromJson(Map<String, dynamic>.from(resp!));
  } catch (e) {
    print("failed to fetch location");
    return null;
  }
}

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

Future<Tuple2<double, double>?> getLocationFromIP() async {
  try {
    final response = await http.get(Uri.parse('https://ipapi.co/json/'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Tuple2(data['latitude'], data['longitude']);
    }
  } catch (e) {
    logger.warning('Error getting location from IP: $e');
  }
  return null;
}

var blacklistedCountriesForPayments = ["CH", "BR"];

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
