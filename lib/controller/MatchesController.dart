import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutmeg/controller/SubscriptionsController.dart';
import 'package:nutmeg/db/MatchesFirestore.dart';
import 'package:nutmeg/db/SubscriptionsFirestore.dart';
import 'package:nutmeg/db/UserFirestore.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';

import 'UserController.dart';

class MatchesController {

  static Future<void> refresh(MatchesState matchesState, String matchId) async {
    var match = await getMatch(matchId);
    matchesState.setMatch(match);
  }

  static Future<void> refreshAll(MatchesState matchesState) async {
    var matches = await getMatches();
    matchesState.setMatches(matches);
  }

  static Future<void> joinMatch(MatchesState matchesState, String matchId,
      UserState userState, PaymentRecap paymentStatus) async {
    await UserController.refresh(userState);
    await refresh(matchesState, matchId);

    var userDetails = userState.getUserDetails();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      var currentUserSub =
          await SubscriptionsController.getMatchSubscriptionsLatestStatePerUser(
              userDetails.getUid(), matchId);

      if (currentUserSub != null &&
          currentUserSub.status == SubscriptionStatus.going) {
        throw new Exception("Already going");
      } else {
        var sub = new Subscription(
            userDetails.getUid(),
            SubscriptionStatus.going,
            paymentStatus.finalPriceToPayInCents,
            paymentStatus.creditsInCentsUsed,
            0);
        await SubscriptionsDb.addSubscription(matchId, sub);
      }

      if (paymentStatus.couponApplied != null) {
        userDetails.usedCoupons.add(paymentStatus.couponApplied.id);
      }

      if (paymentStatus.creditsInCentsUsed > 0) {
        userDetails.creditsInCents =
            userDetails.creditsInCents - paymentStatus.creditsInCentsUsed;
      }
      await UserFirestore.storeUserDetails(userDetails);
    });

    await UserController.refresh(userState);
    await refresh(matchesState, matchId);
  }

  static leaveMatch(
      MatchesState matchesState, String matchId, UserState userState) async {
    await UserController.refresh(userState);
    await refresh(matchesState, matchId);

    var userDetails = userState.getUserDetails();
    var match = matchesState.getMatch(matchId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      var issueRefund = match.dateTime.difference(DateTime.now()).inHours >= 24;
      var currentUserSub =
          await SubscriptionsController.getMatchSubscriptionsLatestStatePerUser(
              userDetails.getUid(), matchId);

      var newSub;
      if (currentUserSub.status != SubscriptionStatus.going) {
        throw new Exception("Already not going");
      } else {
        var refundInCents = (issueRefund) ? match.pricePerPersonInCents : 0;

        newSub = new Subscription(
            userDetails.getUid(),
            (refundInCents == 0)
                ? SubscriptionStatus.canceled
                : SubscriptionStatus.refunded,
            0,
            0,
            refundInCents);

        if (refundInCents != 0) {
          userDetails.creditsInCents =
              userDetails.creditsInCents + refundInCents;
        }
      }

      // update db
      await UserFirestore.storeUserDetails(userDetails);
      await SubscriptionsDb.addSubscription(matchId, newSub);
    });

    // refresh state
    await UserController.refresh(userState);
    await refresh(matchesState, matchId);
  }

  static Future<Match> getMatch(String matchId) async {
    var match = await MatchesFirestore.fetchMatch(matchId);
    match.subscriptions =
        await SubscriptionsController.getMatchSubscriptionsLatestState(matchId) ??
            [];
    return match;
  }

  static Future<List<Match>> getMatches() async {
    var ids = await MatchesFirestore.fetchMatchesId();

    // add subs
    var addSubsFutures = ids.map((m) => getMatch(m));
    return await Future.wait(addSubsFutures);
  }

  static int numPlayedByUser(MatchesState matchesState, String userId) =>
      matchesState.getMatches()
          .where((m) =>
              m.status == MatchStatus.played &&
              m.subscriptions
                  .where((sub) =>
                      sub.status == SubscriptionStatus.going &&
                      sub.userId == userId)
                  .isNotEmpty)
          .length;
}
