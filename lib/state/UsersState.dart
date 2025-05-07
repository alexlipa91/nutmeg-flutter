import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';

import '../model/UserDetails.dart';

final logger = CrashlyticsLogger('UsersState');

class UsersState extends ChangeNotifier {
  // holds state for users' data (both logged in user and others)
  Map<String, UserDetails> _usersDetails = Map();

  void _setUserDetail(UserDetails u) {
    _usersDetails[u.documentId] = u;
    notifyListeners();
  }

  UserDetails? getUserDetail(String uid) => _usersDetails[uid];

  Future<void> fetchUserDetails(String uid) async {
    logger.info('Fetching user details for $uid');
    var resp = await CloudFunctionsClient().get("users/$uid");

    var ud = (resp == null) ? null : UserDetails.fromJson(resp, uid);
    if (ud != null) _setUserDetail(ud);
  }
}
