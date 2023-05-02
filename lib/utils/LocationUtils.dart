import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/ApiKey.dart';
import 'package:provider/provider.dart';

import '../api/CloudFunctionsUtils.dart';
import '../state/LoadOnceState.dart';

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

Future<LocationInfo> fetchLocationInfo(double lat, double lng) async {
  // uncomment to get amsterdam
  // lat = 52.3676; lng = 4.9041;
  var resp = await CloudFunctionsClient()
      .get("locations/coordinates", args: {"lat": lat, "lng": lng});
  return LocationInfo.fromJson(Map<String, dynamic>.from(resp!));
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
Future<List<PredictionResult>> getPlacePrediction(
    String query, String userCountry) async {
  Map<String, dynamic> data = await CloudFunctionsClient().get(
          "locations/predictions",
          args: {"query": query, 'country': userCountry}) ??
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

Future<Position?> determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

// Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
// Location services are not enabled don't continue
// accessing the position and request users of the
// App to enable the location services.
    print('Location services are disabled.');
    return null;
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
// Permissions are denied, next time you could try
// requesting permissions again (this is also where
// Android's shouldShowRequestPermissionRationale
// returned true. According to Android guidelines
// your App should show an explanatory UI now.
      print('Location permissions are denied');
      return null;
    }
  }

  if (permission == LocationPermission.deniedForever) {
// Permissions are denied forever, handle appropriately.
    print(
        'Location permissions are permanently denied, we cannot request permissions.');
    return null;
  }

// When we reach here, permissions are granted and we can
// continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}

var blacklistedCountriesForPayments = ["CH", "BR"];

Locale getLanguageLocale(BuildContext context) {
  var userSpecific = context.watch<UserState>().getLoggedUserDetails()?.language;
  if (userSpecific != null) return Locale(userSpecific);
  return context.watch<LoadOnceState>().locale;
}
