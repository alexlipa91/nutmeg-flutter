import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/controller/PaymentController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/screens/PaymentPage.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/Buttons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'Login.dart';

var formatCurrency = NumberFormat.simpleCurrency(name: "EUR");

Future<void> showWaitingModal(BuildContext context, Future future) {
  var futureWithPop = () async {
    await future;
    Navigator.pop(context);
  };

  return showModalBottomSheet(
      context: context,
      builder: (context) => FutureBuilder<void>(
          future: futureWithPop(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              throw snapshot.stackTrace;
            }

            return Container(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black)),
              ),
            );
          }));
}

class BottomBar extends StatelessWidget {
  final Match match;

  const BottomBar({Key key, this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("user det: " + context.watch<UserChangeNotifier>().getUserDetails().toString());

    var userSub = (context.watch<UserChangeNotifier>().isLoggedIn())
        ? match.getUserSub(context.watch<UserChangeNotifier>().getUserDetails())
        : null;
    var isGoing = userSub != null && userSub.status == SubscriptionStatus.going;

    return Container(
        height: 100,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      (isGoing)
                          ? "You are going!"
                          : match.getSpotsLeft().toString() + " spots left",
                      style: TextPalette.h2),
                ],
              ),
              (isGoing)
                  ? RoundedButton("LEAVE GAME", () async {
                      var hasUserConfirmed = await showModalBottomSheet(
                          context: context,
                          builder: (context) =>
                              LeaveMatchConfirmation(match, userSub));
                      if (hasUserConfirmed != null && hasUserConfirmed) {
                        // actually leave
                        Future<void> Function() updateState = () async {
                          await MatchesController.leaveMatch(match, context.read<UserChangeNotifier>().getUserDetails());
                          await context.read<MatchesChangeNotifier>().refresh();
                          await context.read<UserChangeNotifier>().refresh();
                        };

                        await showWaitingModal(context, updateState());
                      }
                    })
                  : RoundedButton("JOIN GAME", () async {
                      if (!context.read<UserChangeNotifier>().isLoggedIn()) {
                        bool couldLogIn = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Login()))
                            .then((isLoginSuccessfull) => isLoginSuccessfull);

                        if (!couldLogIn) {
                          CoolAlert.show(
                              context: context,
                              type: CoolAlertType.error,
                              text: "Could not login");
                          Navigator.pop(context);
                          return;
                        }
                      }

                      PaymentOutcome value = await showModalBottomSheet(
                          isScrollControlled: true,
                          context: context,
                          builder: (context) =>
                              PrepaymentBottomBar(match: match));
                      print("done, setting state " + value.status.toString());
                      if (value != null && value.status == Status.success) {
                        // update all states
                        Future<Null> Function() updateState = () async {
                          await MatchesController.joinMatch(
                              match,
                              context
                                  .read<UserChangeNotifier>()
                                  .getUserDetails(),
                              value.recap);
                          await context.read<MatchesChangeNotifier>().refresh();
                          await context.read<UserChangeNotifier>().refresh();
                        };

                        await showWaitingModal(context, updateState());

                        await showModalBottomSheet(
                            context: context,
                            builder: (context) =>
                                PostPaymentBottomBar(match: match));
                      } else if (value != null &&
                          value.status == Status.paymentFailed) {
                        CoolAlert.show(
                            context: context,
                            type: CoolAlertType.error,
                            text: "Payment failed");
                      }
                    })
            ],
          ),
        ));
  }
}

class PrepaymentBottomBar extends StatelessWidget {
  final Match match;

  const PrepaymentBottomBar({Key key, this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var userDetails = context.read<UserChangeNotifier>().getUserDetails();

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        // fixme why not having borders?
        decoration: BoxDecoration(
          color: Palette.white,
          borderRadius: BorderRadius.only(topRight: Radius.circular(10)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: FutureBuilder<PaymentRecap>(
            future: PaymentController.generatePaymentRecap(match, userDetails),
            builder: (context, snapshot) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                      padding: EdgeInsets.only(bottom: 20.0),
                      child: Text("Join this game", style: TextPalette.h2)),
                  Text(
                    "You can cancel up to 24h before the game starting time to get a full refund in credits to use on your next game.\nIf you cancel after this time you won't get a refund.",
                    style: TextPalette.bodyText,
                  ),
                  Divider(),
                  Row(
                    children: [
                      CircleAvatar(
                          backgroundImage: NetworkImage(context
                              .watch<UserChangeNotifier>()
                              .getUserDetails()
                              .getPhotoUrl()),
                          radius: 15),
                      SizedBox(width: 15),
                      Text("1x player", style: TextPalette.h3),
                      Expanded(
                          child: Text(
                        match.getFormattedPrice(),
                        style: (snapshot.hasData && snapshot.data != null && snapshot.data.couponApplied != null)
                            ? TextPalette.h3WithBar
                            : TextPalette.h3,
                        textAlign: TextAlign.end,
                      ))
                    ],
                  ),
                  if (snapshot.hasData &&
                      snapshot.data != null &&
                      snapshot.data.couponApplied != null)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 45),
                              child: Text(
                                  snapshot.data.couponApplied.description,
                                  style: TextPalette.h3),
                            ),
                            Text(
                              formatCurrency.format(
                                  snapshot.data.getPriceAfterCoupon() / 100),
                              style: TextPalette.linkStyle,
                            )
                          ]),
                    ),
                  Divider(),
                  if (snapshot.hasData &&
                      snapshot.data != null &&
                      snapshot.data.creditsInCentsUsed > 0)
                    Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "Using " +
                                    formatCurrency.format(
                                        snapshot.data.creditsInCentsUsed /
                                            100) +
                                    " credits from your balance.",
                                style: TextPalette.h3),
                            SizedBox(height: 10),
                            Text(
                                (snapshot.data.finalPriceToPayInCents == 0)
                                    ? "You don't have to pay anything now."
                                    : "You have to pay " +
                                        formatCurrency.format(snapshot
                                                .data.finalPriceToPayInCents /
                                            100) +
                                        ".",
                                style: TextPalette.h3),
                          ]),
                    ),
                  Divider(),
                  if (snapshot.connectionState == ConnectionState.done)
                    Row(
                      children: [
                        Expanded(
                          child: RoundedButton(
                              (snapshot.data.finalPriceToPayInCents == 0)
                                  ? "PAY WITH CREDITS"
                                  : "CONTINUE TO PAYMENT", () async {
                            PaymentOutcome status;

                            if (snapshot.data.finalPriceToPayInCents == 0) {
                              status =
                                  PaymentOutcome(Status.success, snapshot.data);
                            } else {
                              // final stripeCustomerId = await context
                              //     .read<UserChangeNotifier>()
                              //     .getOrCreateStripeId();
                              // print("stripeCustomerId " + stripeCustomerId);
                              // final sessionId = await Server()
                              //     .createCheckout(stripeCustomerId, finalPrice);
                              // print("sessId " + sessionId);
                              //
                              // var value = await Navigator.of(context).push(
                              //     MaterialPageRoute(
                              //         builder: (_) => CheckoutPage(
                              //             sessionId: sessionId,
                              //             couponUsed: snapshot.data.id)));

                              status = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          SuccessfulPaymentSimulator(
                                            match: match,
                                            paymentRecap: snapshot.data,
                                          )));
                            }
                            print("status is " + status.status.toString());
                            Navigator.of(context).pop(status);
                          }),
                        )
                      ],
                    )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class PostPaymentBottomBar extends StatelessWidget {
  final Match match;
  final PaymentOutcome paymentOutcome;

  const PostPaymentBottomBar({Key key, this.match, this.paymentOutcome}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // fixme why not having borders?
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.only(topRight: Radius.circular(10)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
                padding: EdgeInsets.only(bottom: 20.0),
                child:
                    Text("You are going to this game", style: TextPalette.h2)),
            Padding(
              padding: EdgeInsets.only(bottom: 20.0),
              child: Text(
                "You have successfully paid and joined this game.",
                style: TextPalette.bodyText,
              ),
            ),
            InkWell(
              child: Row(
                children: [
                  Icon(Icons.share, color: Palette.primary),
                  SizedBox(width: 20),
                  Text("SHARE", style: TextPalette.linkStyle)
                ],
              ),
              onTap: () => CoolAlert.show(
                  context: context,
                  type: CoolAlertType.info,
                  text: "Implement this"),
            ),
          ],
        ),
      ),
    );
  }
}

// widget to show when user is leaving
class LeaveMatchConfirmation extends StatelessWidget {
  final Match match;
  final Subscription latestUserSub;

  LeaveMatchConfirmation(this.match, this.latestUserSub);

  @override
  Widget build(BuildContext context) {
    var hoursToGame = match.dateTime.difference(DateTime.now()).inHours;

    return Container(
      // fixme why not having borders?
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.only(topRight: Radius.circular(10)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
                padding: EdgeInsets.only(bottom: 20.0),
                child: Text("Leaving this game?", style: TextPalette.h2)),
            Text(
              "You joined this game on " +
                  getFormattedDate(latestUserSub.createdAt.toDate()) +
                  ".",
              style: TextPalette.bodyText,
            ),
            Text(
              (hoursToGame < 24)
                  ? "You will not receive a refund since the game is in less than 24 hours."
                  : "We will refund you in credits that you can use in your next games.",
              style: TextPalette.bodyText,
            ),
            Divider(),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                children: [
                  Text("Credits refund", style: TextPalette.h3),
                  Expanded(
                      child: Text(
                    formatCurrency.format(match.pricePerPersonInCents / 100) +
                        " euro",
                    style: TextPalette.h3,
                    textAlign: TextAlign.end,
                  ))
                ],
              ),
            ),
            Divider(),
            Row(
              children: [
                Expanded(
                  child: RoundedButton("CONFIRM", () async {
                    Navigator.of(context).pop(true);
                  }),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

// class DiscountCodeChangeNotifier extends ChangeNotifier {
//   DiscountCodeChangeNotifier(int priceInCents) {
//     initialPrice = priceInCents;
//     discountedPrice = priceInCents;
//   }
//
//   int initialPrice;
//   String code;
//   int discountPercentage = 0;
//   int discountedPrice;
//
//   Future<bool> apply(Set<String> usedCoupons) async {
//     try {
//       var percentage = await CouponsFirestore.getCouponDiscount(code);
//       var hasBeenUsed = usedCoupons.contains(code);
//
//       if (percentage > 0 && !hasBeenUsed) {
//         // todo add logic to check if user is eligible
//         discountPercentage = percentage;
//         discountedPrice -= initialPrice * discountPercentage ~/ 100;
//         notifyListeners();
//         return true;
//       }
//       return false;
//     } catch (e) {
//       return false;
//     }
//   }
// }
