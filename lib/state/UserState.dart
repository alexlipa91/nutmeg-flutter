import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nutmeg/utils/LocationUtils.dart';

import '../controller/SportCentersController.dart';
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

  Future<void> fetchSportCenters() async {
    _sportCenters = await SportCentersController
        .getUserSportCenters(currentUserId!);
    notifyListeners();
  }

  List<SportCenter>? getSportCenters() => _sportCenters;

  // user location
  LocationInfo? _locationInfo;

  Future<void> setLocationInfo(Position? position) async {
    if (position != null)
      _locationInfo = await getLocationInfo(position.latitude, position.longitude);
  }

  String getCountry() => _locationInfo?.country ?? "NL";
  String getCity() => _locationInfo?.city ?? "Amsterdam";
}

class LocationInfo {

  // these are city coordinates
  double lat;
  double lng;
  String? country;
  String? city;

  LocationInfo(this.country, this.city, this.lat, this.lng);
}