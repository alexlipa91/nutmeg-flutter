import 'package:flutter/cupertino.dart';
import 'package:nutmeg/db/MatchesFirestore.dart';
import 'package:nutmeg/db/SportCentersFirestore.dart';
import 'package:nutmeg/db/UserFirestore.dart';
import 'package:nutmeg/screens/PaymentPage.dart';
import 'Model.dart';

class MatchesChangeNotifier extends ChangeNotifier {
  List<Match> _matches;

  refresh() async {
    _matches = await MatchesFirestore.fetchMatches();
    notifyListeners();
  }

  List<Match> getMatches() => _matches;

  List<Match> getMatchesInFuture() => _matches
      .where((m) => m.dateTime.difference(DateTime.now()).inHours > 2)
      .toList();

  // fixme ugly
  Match getMatch(String matchId) =>
      _matches.firstWhere((e) => e.documentId == matchId);

  int numPlayedByUser(String userId) => _matches
      .where((m) => m.status == MatchStatus.played && m.subscriptions
          .where((sub) =>
              sub.status == SubscriptionStatus.going && sub.userId == userId)
          .isNotEmpty)
      .length;

  joinMatch(Match m, UserDetails u) async {
    await MatchesFirestore.joinMatch(u, m);
    await refresh();
  }

  leaveMatch(Match m, UserDetails u) async {
    await MatchesFirestore.leaveMatch(u, m);
    await refresh();
  }
}

class SportCentersChangeNotifier extends ChangeNotifier {
  Map<String, SportCenter> _sportCenters;

  refresh() async {
    _sportCenters = Map.fromEntries(
        (await SportCentersFirestore.getSportCenters())
            .map((e) => MapEntry(e.placeId, e)));
    notifyListeners();
  }

  SportCenter getSportCenter(String id) => _sportCenters[id];

  List<SportCenter> getSportCenters() => _sportCenters.values;
}

class UserChangeNotifier extends ChangeNotifier {
  // todo should this be somewhere else?
  static Future<UserDetails> getSpecificUserDetails(String uid) =>
      UserFirestore.getSpecificUserDetails(uid);

  UserDetails _userDetails;

  UserDetails getUserDetails() => _userDetails;

  Future<void> loginWithGoogle() async {
    _userDetails = await UserFirestore.loginWithGoogle();
    notifyListeners();
  }

  bool isLoggedIn() =>
      _userDetails != null && _userDetails.firebaseUser != null;

  void logout() async {
    await UserFirestore.logout();
    _userDetails.firebaseUser = null;
    notifyListeners();
  }

  Future<String> getOrCreateStripeId() async {
    if (_userDetails.getStripeId() != null) {
      return _userDetails.getStripeId();
    }

    String stripeId = await Server()
        .createCustomer(_userDetails.firebaseUser.email, _userDetails.name);

    _userDetails.setStripeId(stripeId);
    UserFirestore.storeStripeId(_userDetails.getUid(), stripeId);

    return stripeId;
  }
}

// class LocationChangeNotifier extends ChangeNotifier {
//   LocationData locationData;
//
//   Future<void> refresh() async {
//     locationData = await LocationUtils.getCurrentLocation();
//   }
//
//   LocationData getLocationData() => locationData;
// }