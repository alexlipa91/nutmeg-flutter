import 'dart:math';

import 'package:nutmeg/db/CouponsFirestore.dart';
import 'package:nutmeg/model/Model.dart';


class PaymentController {

  static Future<PaymentRecap> generatePaymentRecap(Match m, UserDetails u) async {
    var result = PaymentRecap();
    result.matchPriceInCents = m.pricePerPersonInCents;
    result.finalPriceToPayInCents = m.pricePerPersonInCents;
    result.creditsInCentsUsed = 0;

    // check if coupon is applicable
    // todo assume only one for now
    var availableCoupons = await CouponsFirestore.getCoupons();
    Coupon coupon = availableCoupons.first;

    if (u.usedCoupons.where((c) => c == coupon.id).isEmpty) { // can use
      result.couponApplied = coupon;
      result.finalPriceToPayInCents -= ((coupon.percentage / 100) * result.finalPriceToPayInCents).toInt();
    }

    if (u.creditsInCents > 0) { // can use
      var toUse = min(result.finalPriceToPayInCents, u.creditsInCents);
      result.creditsInCentsUsed = toUse;
      result.finalPriceToPayInCents -= toUse;
    }

    return result;
  }
}
