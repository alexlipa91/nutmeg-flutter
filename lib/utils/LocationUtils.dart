import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/ApiKey.dart';

import '../api/CloudFunctionsUtils.dart';

String buildMapUrl(double lat, double lng) => "https://maps.googleapis.com/maps/api/staticmap?center=" +
    lat.toString() +
    "," +
    lng.toString() +
    "&key=$placesApiKey" +
    "&zoom=16&size=600x300&markers=color:red%7C" +
    lat.toString() +
    "," +
    lng.toString();

Future<LocationInfo> getLocationInfo(double lat, double lng) async {
  // uncomment to get amsterdam
  // lat = 52.3676; lng = 4.9041;
  var url = "https://maps.googleapis.com/maps/api/geocode/json?" +
      "latlng=${lat.toString()},${lng.toString()}" +
      "&key=$placesApiKey" +
      "&result_type=locality";

  var response = await http.get(Uri.parse(url));

  var resp = jsonDecode(response.body);

  var addressComponents = resp["results"][0]["address_components"];

  var city;
  var country;

  try {
    addressComponents.forEach((a) {
      if (a["types"].contains("locality"))
        city = a["long_name"];
      else if (a["types"].contains("country"))
        country = a["short_name"];
    });
  } catch (e, st) {
    print(e);
    print(st);
  }

  var location = resp["results"][0]["geometry"]["location"];

  return LocationInfo(country, city, location["lat"], location["lng"]);
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
Future<List<PredictionResult>> getPlacePrediction(String query, String userCountry) async {
  Map<String, dynamic> data = await CloudFunctionsClient()
      .callFunction(
      "get_location_predictions_from_query",
      {"query" : query, 'country': userCountry})
      ?? {};

  List predictions = data["predictions"] ?? [];
  print(predictions);

  List<PredictionResult> results = [];

  predictions.forEach((element) {
    var e = Map<String, dynamic>.from(element);
    results.add(PredictionResult(e["description"],
        List<PredictionMatch>.from(
            e["matched_substrings"].map((m) =>
                PredictionMatch(m["offset"], m["length"]))),
        e["place_id"]));
  });

  return results;
}

// check if lat/lng is within center and 20 km
bool isWithinRadius(double lat, double lng, double centerLat, double centerLng) {
  var d = Geolocator.distanceBetween(lat, lng, centerLat, centerLng);
  return d < 20 * 1000;
}



var blacklistedCountriesForPayments = ["CH", "BR"];
