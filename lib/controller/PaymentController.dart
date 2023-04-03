import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:provider/provider.dart';

import '../api/CloudFunctionsUtils.dart';
import '../model/PaymentRecap.dart';
import '../state/UserState.dart';

class PaymentController {

  static var apiClient = CloudFunctionsClient();

  static Future<PaymentRecap> generatePaymentRecap(BuildContext context,
      String matchId) async {
    var m = await MatchesController.refresh(context, matchId);
    var u = (await context.read<UserState>().fetchLoggedUserDetails())!;

    int creditsUsed;

    if ((u.creditsInCents ?? 0) > 0) {
      // can use
      creditsUsed = min(m.pricePerPersonInCents, u.creditsInCents!);
    } else {
      creditsUsed = 0;
    }

    var result = PaymentRecap(m.pricePerPersonInCents, creditsUsed, m.userFee);

    return result;
  }
}
