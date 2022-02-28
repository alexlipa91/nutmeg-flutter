import 'dart:math';

import 'package:nutmeg/controller/CloudFunctionsUtils.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/Model.dart';

import '../state/MatchesState.dart';
import '../state/UserState.dart';
import 'UserController.dart';

class PaymentController {

  static Future<String> createCheckout(String userId, String matchId,
      int creditsUsed, testMode) async {
    var result = await CloudFunctionsUtils.callFunction("create_stripe_checkout",
        {
          'match_id': matchId,
          'user_id': userId,
          'credits_used': creditsUsed,
          'test_mode': testMode
        });
    return result["url"];
  }

  static Future<PaymentRecap> generatePaymentRecap(
      MatchesState matchesState, String matchId, UserState userState) async {
    var m = await MatchesController.refresh(matchesState, userState, matchId);
    var u = await UserController.refreshCurrentUser(userState);

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
