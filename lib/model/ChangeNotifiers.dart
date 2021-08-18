import 'package:flutter/cupertino.dart';
import 'package:nutmeg/db/MatchesFirestore.dart';
import 'package:nutmeg/db/UserFirestore.dart';
import 'Model.dart';

class MatchesChangeNotifier extends ChangeNotifier {

  List<Match> _matches;

  refresh() async {
    _matches = await MatchesFirestore.fetchMatches();
    notifyListeners();
  }

  List<Match> getMatches() => _matches;

  // fixme ugly
  Match getMatch(String matchId) => _matches.firstWhere((e) => e.documentId == matchId);

  joinMatch(Match m, UserDetails u) async {
    await MatchesFirestore.joinMatch(u, m);
    await refresh();
  }
}

class UserChangeNotifier extends ChangeNotifier {

  // todo should this be somewhere else?
  static Future<UserDetails> getSpecificUserDetails(String uid) => UserFirestore.getSpecificUserDetails(uid);

  UserDetails _userDetails;

  UserDetails getUserDetails() => _userDetails;

  Future<void> loginWithGoogle() async {
    _userDetails = await UserFirestore.loginWithGoogle();
    notifyListeners();
  }

  bool isLoggedIn() => _userDetails != null && _userDetails.firebaseUser != null;

  void logout() async {
    await UserFirestore.logout();
    _userDetails.firebaseUser = null;
    notifyListeners();
  }
}