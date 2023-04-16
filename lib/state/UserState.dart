import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/utils/LocationUtils.dart';

import '../model/SportCenter.dart';
import '../model/UserDetails.dart';


class UserState extends ChangeNotifier {
  // hold current user id
  String? currentUserId;
  bool _isTestMode = false;

  // holds state for all users' data (both logged in user and others)
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
    _sportCenters = null;
    notifyListeners();
  }

  // user sport centers
  List<SportCenter>? _sportCenters;

  Future<UserDetails?> fetchLoggedUserDetails() async {
    // use this to navigate as another user for testing
    // return fetchUserDetails("bQHD0EM265V6GuSZuy1uQPHzb602");

    User? u = await FirebaseAuth.instance.authStateChanges().first;

    if (u == null) {
      return null;
    }

    return fetchUserDetails(u.uid);
  }

  Future<UserDetails?> fetchUserDetails(String uid) async {
    var resp = await CloudFunctionsClient().get("users/$uid");

    var ud = (resp == null) ? null : UserDetails.fromJson(resp, uid);
    if (ud != null)
      setUserDetail(ud);

    return ud;
  }

  Future<void> editUser(Map<String, dynamic> data) async {
    await CloudFunctionsClient().post("users/${currentUserId!}", data);
    await fetchLoggedUserDetails();
  }

  Future<void> storeUserToken(String? token) async {
    if (token == null) {
      return;
    }
    CloudFunctionsClient().post("users/${currentUserId!}/tokens", {
      "token": token
    });
  }

  Future<List<SportCenter>> fetchLoggedUserSportCenters() async {
    Map<String, dynamic> data = await CloudFunctionsClient()
        .callFunction("get_user_sportcenters", {"user_id" : currentUserId!})
        ?? {};

    _sportCenters = data.entries.map((e) => SportCenter
        .fromJson(Map<String, dynamic>.from(e.value), e.key))
        .toList();

    notifyListeners();
    return _sportCenters!;
  }

  List<SportCenter>? getSportCenters() => _sportCenters;

  // user location
  late LocationInfo _deviceLocationInfo;

  Future<void> setLocationInfo(Position? position) async {
    if (position != null)
      _deviceLocationInfo = await fetchLocationInfo(position.latitude, position.longitude);
    else
      _deviceLocationInfo = LocationInfo("NL", "Amsterdam", 52.3676, 4.9041);
  }

  LocationInfo getLocationInfo() =>
      _usersDetails[currentUserId]?.location ?? _deviceLocationInfo;
}

class LocationInfo {

  // these are city coordinates:
  double lat;
  double lng;
  String country;
  String city;

  LocationInfo(this.country, this.city, this.lat, this.lng);

  LocationInfo.fromJson(Map<String, dynamic> json):
      country = json["country"],
      city = json["city"],
      lat = json["lat"],
      lng = json["lng"];

  Map<String, dynamic> toJson() => {
    "country": country,
    "city": city,
    "lat": lat,
    "lng": lng
  };

  String getText() => "$city, $country";
}