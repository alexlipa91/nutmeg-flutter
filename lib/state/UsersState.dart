import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';

import '../model/UserDetails.dart';

final logger = CrashlyticsLogger('UsersState');

class UsersState extends ChangeNotifier {
  UserState? _loggedUserState;

  // holds state for not logged in users'
  Map<String, UserDetails> _usersDetails = Map();

  void _setUserDetail(UserDetails u) {
    _usersDetails[u.documentId] = u;
    notifyListeners();
  }

  UserDetails? getUserDetail(String uid) => _usersDetails[uid];

  Future<void> fetchUserDetails(String uid, {bool useCached = true}) async {
    if (_loggedUserState?.getLoggedUserId() == uid) {
      // don't fetch details for logged in user
      return;
    }

    if (useCached && _usersDetails.containsKey(uid)) {
      return;
    }

    logger.info('Fetching user details for $uid');
    var resp = await CloudFunctionsClient().get("users/$uid");

    var ud = (resp == null) ? null : UserDetails.fromJson(resp, uid);
    if (ud != null) _setUserDetail(ud);
  }

  void updateBasedOnLoggedUser(UserState userState) {
    _loggedUserState = userState;

    if (userState.getLoggedUserId() != null) {
      _usersDetails[userState.getLoggedUserId()!] =
          userState.getLoggedUserDetails()!;
    }
  }
}
