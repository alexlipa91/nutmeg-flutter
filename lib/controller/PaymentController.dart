import 'dart:math';

import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';


class PaymentController {

  static Future<PaymentRecap> generatePaymentRecap(MatchesState matchesState, String matchId, UserState userState) async {
    var m = await MatchesController.refresh(matchesState, matchId);
    var u = await UserController.refresh(userState);

    var creditsUsed;
    if (u.creditsInCents > 0) { // can use
      creditsUsed = min(m.pricePerPersonInCents, u.creditsInCents);
    } else {
      creditsUsed = 0;
    }

    var result = PaymentRecap(m.pricePerPersonInCents, creditsUsed);

    return result;
  }
}
