import 'package:flutter/cupertino.dart';

import '../model/UserDetails.dart';


class UserState extends ChangeNotifier {
  // holds state for all users' data (both logged in user and others)

  String _currentUserId;
  bool _isTestMode = false;
  Map<String, UserDetails> _usersDetails = Map();

  String get currentUserId => _currentUserId;

  UserDetails getLoggedUserDetails() => _usersDetails[_currentUserId];

  void setCurrentUserDetails(UserDetails u) {
    _currentUserId = u.documentId;
    if (u.isAdmin) {
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
}