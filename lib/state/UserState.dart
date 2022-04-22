import 'package:flutter/cupertino.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';

import '../model/UserDetails.dart';


class UserState extends ChangeNotifier {
  // holds state for all users' data (both logged in user and others)

  String _currentUserId;

  set currentUserId(String value) {
    _currentUserId = value;
  }

  bool _isTestMode = false;
  Map<String, UserDetails> _usersDetails = Map();

  String _onboardingUrl;
  String _onboardingUrlTest;

  String get currentUserId => _currentUserId;

  UserDetails getLoggedUserDetails() => _usersDetails[_currentUserId];

  void setCurrentUserDetails(UserDetails u) {
    _currentUserId = u.documentId;
    if (u.getIsAdmin() != null && u.getIsAdmin()) {
      _isTestMode = true;
    }
    setUserDetail(u);
  }

  void setUserDetail(UserDetails u) {
    _usersDetails[u.documentId] = u;
    notifyListeners();
  }

  UserDetails getUserDetail(String uid) => _usersDetails[uid];

  bool get isTestMode => _isTestMode;

  void setTestMode(bool value) {
    _isTestMode = value;
    notifyListeners();
  }

  bool isLoggedIn() => _currentUserId != null;

  void logout() {
    _currentUserId = null;
    notifyListeners();
  }

  // url to onboard to stripe connect, for organisers
  Future<void> fetchOnboardingUrl(bool isTest) async {
    var response = await CloudFunctionsClient().callFunction("onboard_account", {
      "user_id": currentUserId,
      "is_test": isTest
    });

    if (isTest)
      _onboardingUrlTest = response["url"] ?? null;
    else
      _onboardingUrl = response["url"] ?? null;

    notifyListeners();
  }

  String getOnboardingUrl(bool isTest) =>
      isTest ? _onboardingUrlTest : _onboardingUrl;

  void setOnboardingUrl(String url) => _onboardingUrl = url;
}