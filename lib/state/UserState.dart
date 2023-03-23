import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../api/CloudFunctionsUtils.dart';
import '../controller/SportCentersController.dart';
import '../model/SportCenter.dart';
import '../model/UserDetails.dart';


class UserState extends ChangeNotifier {
  // holds state for all users' data (both logged in user and others)
  String? currentUserId;

  bool _isTestMode = false;
  Map<String, UserDetails> _usersDetails = Map();

  UserDetails? getLoggedUserDetails() => _usersDetails[currentUserId];

  void setCurrentUserDetails(UserDetails u) {
    currentUserId = u.documentId;
    if (u.getIsAdmin()) {
      _isTestMode = true;
    }
    setUserDetail(u);
  }

  void setUserDetail(UserDetails u) {
    _usersDetails[u.documentId] = u;
    notifyListeners();
  }

  UserDetails? getUserDetail(String uid) => _usersDetails[uid];

  bool get isTestMode => _isTestMode;

  void setTestMode(bool value) {
    _isTestMode = value;
    notifyListeners();
  }

  bool isLoggedIn() => currentUserId != null;

  void logout() {
    currentUserId = null;
    notifyListeners();
  }

  // stats
  Map<String, List<double>> _usersScores = Map();

  List<double> getUserScores(String uid) => _usersScores[uid] ?? [];

  Future<List<double>> fetchScores(String userId) async{
    if (_usersScores.containsKey(userId))
      return _usersScores[userId] ?? [];

    var scores = await CloudFunctionsClient()
        .callFunction("get_last_user_scores", {"id": userId});

    List<double> scoresList = [];

    List<dynamic> o = scores!["scores"];
    o.forEach((e) {
      scoresList.add(e as double);
    });

    _usersScores[userId] = scoresList;
    notifyListeners();
    return scoresList;
  }

  // SPORT CENTERS
  List<SportCenter>? _sportCenters;

  Future<void> fetchSportCenters() async {
    _sportCenters = await SportCentersController
        .getUserSportCenters(currentUserId!);
    notifyListeners();
  }

  List<SportCenter>? getSportCenters() => _sportCenters;

  // location
  LocationInfo? _locationInfo;

  Future<void> setLocationInfo(Position? position) async {
    if (position != null)
      _locationInfo = await LocationInfo.init(position);
  }

  String getCountry() => _locationInfo?.country ?? "NL";
  String getCity() => _locationInfo?.city ?? "Amsterdam";
}

class LocationInfo {

  Position position;
  String? country;
  String? city;

  LocationInfo(this.position, this.country, this.city);

  static Future<LocationInfo> init(Position position) async {
    var url = "https://maps.googleapis.com/maps/api/geocode/json?" +
        "latlng=${position.latitude.toString()},${position.longitude.toString()}" +
        "&key=AIzaSyDlU4z5DbXqoafB-T-t2mJ8rGv3Y4rAcWY" +
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
    print("location is $country, $city");

    return LocationInfo(position, country, city);
  }
}