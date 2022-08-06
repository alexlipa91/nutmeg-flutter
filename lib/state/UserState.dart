import 'package:flutter/cupertino.dart';

import '../api/CloudFunctionsUtils.dart';
import '../model/UserDetails.dart';


class UserState extends ChangeNotifier {
  // holds state for all users' data (both logged in user and others)
  String? _currentUserId;

  set currentUserId(String? value) {
    _currentUserId = value;
  }

  bool _isTestMode = false;
  Map<String, UserDetails> _usersDetails = Map();

  String? get currentUserId => _currentUserId;

  UserDetails? getLoggedUserDetails() => _usersDetails[_currentUserId];

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

  UserDetails? getUserDetail(String uid) => _usersDetails[uid];

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

  // stats
  Map<String, List<double>> _usersScores = Map();

  List<double>? getUserScores(String uid) => _usersScores[uid];

  Future<List<double>?> fetchScores(String userId) async{
    if (_usersScores.containsKey(userId))
      return _usersScores[userId];

    var scores = await CloudFunctionsClient()
        .callFunction("get_last_user_scores", {"id": userId});

    List<double> scoresList = [];

    List<Object> o = scores!["scores"];
    o.forEach((e) {
      scoresList.add(e as double);
    });

    _usersScores[userId] = scoresList;
    notifyListeners();
  }
}