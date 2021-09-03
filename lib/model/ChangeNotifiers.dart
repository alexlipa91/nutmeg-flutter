import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:nutmeg/db/MatchesFirestore.dart';
import 'package:nutmeg/db/SportCentersFirestore.dart';
import 'package:nutmeg/db/UserFirestore.dart';
import 'package:nutmeg/screens/PaymentPage.dart';
import 'Model.dart';


class MatchesChangeNotifier extends ChangeNotifier {
  List<Match> _matches = [];

  refresh() async {
    _matches = await Future.delayed(Duration(milliseconds: 200), () => MatchesFirestore.fetchMatches());
    notifyListeners();
  }

  List<Match> getMatches() => _matches..sort((a, b) => b.dateTime.compareTo(a.dateTime));

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
}

class SportCentersChangeNotifier extends ChangeNotifier {
  Map<String, SportCenter> _sportCenters;

  refresh() async {
    _sportCenters = Map.fromEntries(
        (await SportCentersFirestore.getSportCenters())
            .map((e) => MapEntry(e.placeId, e)));
    notifyListeners();
  }

  // fixme break with exception here
  SportCenter getSportCenter(String id) => _sportCenters[id];

  List<SportCenter> getSportCenters() => _sportCenters.values.toList();
}

class UserChangeNotifier extends ChangeNotifier {

  // todo should this be somewhere else?
  static Future<UserDetails> getSpecificUserDetails(String uid) =>
      UserFirestore.getSpecificUserDetails(uid);

  UserDetails _userDetails;

  UserDetails getUserDetails() => _userDetails;

  refresh() async {
    _userDetails = await UserFirestore.getSpecificUserDetails(_userDetails.getUid());
    notifyListeners();
  }

  Future<void> loginWithGoogle() async {
    _userDetails = await UserFirestore.loginWithGoogle();
    notifyListeners();
  }

  bool isLoggedIn() => _userDetails != null;

  Future<void> logout() async {
    await UserFirestore.logout();
    _userDetails = null;
    notifyListeners();
  }

  Future<String> getOrCreateStripeId() async {
    if (_userDetails.getStripeId() != null) {
      return _userDetails.getStripeId();
    }

    String stripeId = await Server()
        .createCustomer(_userDetails.email, _userDetails.name);

    _userDetails.setStripeId(stripeId);
    UserFirestore.storeStripeId(_userDetails.getUid(), stripeId);

    return stripeId;
  }

  // fixme separate better user from firebase and from my db
  Future<void> loadUserIfAvailable() async {
    User u = UserFirestore.getCurrentFirestoreUser();

    if (u != null) {
      try {
        var existingUserDetails = await UserFirestore.getSpecificUserDetails(u.uid);
       _userDetails = UserDetails.from(u.uid, existingUserDetails);
        await UserFirestore.storeUserDetails(_userDetails);
      } catch (e) {
        print("Found firebase user but couldn't load details: " + e.toString());
      }
    }
  }

  Future<void> storeUsedCoupon(String id) async {
    _userDetails.usedCoupons.add(id);
    await UserFirestore.storeUserDetails(_userDetails);
  }

  Future<void> useCredits(int creditsToUse) async {
    _userDetails.creditsInCents = _userDetails.creditsInCents - creditsToUse;
    await UserFirestore.storeUserDetails(_userDetails);
  }

  Future<void> emitCreditRefund(int creditRefundInCents) async {
    _userDetails.creditsInCents = _userDetails.creditsInCents + creditRefundInCents;
    await UserFirestore.storeUserDetails(_userDetails);
  }
}
