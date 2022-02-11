import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';

import 'UserController.dart';

class PaymentController {
  static Future<String> createCheckout(
      String stripePriceId, String userId, String matchId, testMode) async {
    HttpsCallable callable =
        FirebaseFunctions.instanceFor(region: "europe-central2")
            .httpsCallable('create_stripe_checkout');
    final results = await callable({
      'price_id': stripePriceId,
      'match_id': matchId,
      'user_id': userId,
      'test_mode': testMode
    });
    return results.data["url"];
  }

  static Future<PaymentRecap> generatePaymentRecap(
      MatchesState matchesState, String matchId, UserState userState) async {
    var m = await MatchesController.refresh(matchesState, matchId);
    var u = await UserController.refresh(userState);

    int creditsUsed;
    if (u.creditsInCents > 0) {
      // can use
      creditsUsed = min(m.pricePerPersonInCents, u.creditsInCents);
    } else {
      creditsUsed = 0;
    }

    var result = PaymentRecap(m.pricePerPersonInCents, creditsUsed);

    return result;
  }
}
