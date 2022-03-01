import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/controller/UserController.dart';

import '../api/CloudFunctionsUtils.dart';
import '../model/PaymentRecap.dart';
import 'UserController.dart';

class PaymentController {

  static var apiClient = CloudFunctionsClient();

  static Future<String> createCheckout(String userId, String matchId,
      int creditsUsed, testMode) async {
    var result = await apiClient.callFunction("create_stripe_checkout",
        {
          'match_id': matchId,
          'user_id': userId,
          'credits_used': creditsUsed,
          'test_mode': testMode
        });
    return result["url"];
  }

  static Future<PaymentRecap> generatePaymentRecap(BuildContext context,
      String matchId) async {
    var m = await MatchesController.refresh(context, matchId);
    var u = await UserController.refreshCurrentUser(context);

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
