import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutmeg/controller/PaymentController.dart';
import 'package:nutmeg/db/SubscriptionsFirestore.dart';
import 'package:nutmeg/db/UserFirestore.dart';
import 'package:nutmeg/model/Model.dart';

class MatchesController {
  static Future<void> joinMatch(
      Match m, UserDetails u, PaymentRecap paymentStatus) async {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      var currentUserSub =
          await SubscriptionsDb.getMatchSubscriptionsLatestStatePerUser(
              u, m.documentId);

      if (currentUserSub != null &&
          currentUserSub.status == SubscriptionStatus.going) {
        throw new Exception("Already going");
      } else {
        var sub = new Subscription(
            u.getUid(),
            SubscriptionStatus.going,
            paymentStatus.finalPriceToPayInCents,
            paymentStatus.creditsInCentsUsed,
            0);
        await SubscriptionsDb.addSubscription(m.documentId, sub);
      }

      if (paymentStatus.couponApplied != null) {
        u.usedCoupons.add(paymentStatus.couponApplied.id);
        await UserFirestore.storeUserDetails(u);
      }

      if (paymentStatus.creditsInCentsUsed > 0) {
        u.creditsInCents = u.creditsInCents - paymentStatus.creditsInCentsUsed;
        await UserFirestore.storeUserDetails(u);
      }
    });
  }

  static leaveMatch(Match m, UserDetails u) async {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      var issueRefund = m.dateTime.difference(DateTime.now()).inHours >= 24;
      var currentUserSub =
          await SubscriptionsDb.getMatchSubscriptionsLatestStatePerUser(
              u, m.documentId);

      if (currentUserSub.status != SubscriptionStatus.going) {
        throw new Exception("Already not going");
      } else {
        var refundInCents = (issueRefund) ? m.pricePerPersonInCents : 0;

        var sub = new Subscription(
            u.getUid(),
            (refundInCents == 0)
                ? SubscriptionStatus.canceled
                : SubscriptionStatus.refunded,
            0,
            0,
            refundInCents);
        await SubscriptionsDb.addSubscription(m.documentId, sub);

        if (refundInCents != 0) {
          u.creditsInCents = u.creditsInCents + refundInCents;
          await UserFirestore.storeUserDetails(u);
        }
      }
    });
  }
}
