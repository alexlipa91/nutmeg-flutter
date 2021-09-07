import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/controller/PaymentController.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/screens/PaymentPage.dart';
import 'package:nutmeg/screens/UserPage.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/Buttons.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

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
    var userSub = (context.watch<UserState>().isLoggedIn())
        ? match.getUserSub(context.watch<UserState>().getUserDetails())
        : null;
    var isGoing = userSub != null && userSub.status == SubscriptionStatus.going;

    return InfoContainer(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    (isGoing)
                        ? "You are going!"
                        : match.getSpotsLeft().toString() + " spots left",
                    style: TextPalette.h2),
                SizedBox(height: 20),
                Text(
                    (isGoing)
                        ? match.numPlayersGoing().toString() + " going"
                        : formatCurrency.format(match.pricePerPersonInCents / 100),
                    style: TextPalette.bodyText),
              ],
            ),
            (isGoing)
                ? RoundedButtonLight("LEAVE GAME", () async {
                    await showModalBottomSheet(
                        context: context,
                        builder: (context) =>
                            LeaveMatchConfirmation(match, userSub));
                  })
                : (!match.isFull())
                    ? JoinGameButton(match)
                    : Container()
          ],
        ));
  }
}

class PrepaymentBottomBar extends StatelessWidget {
  final Match match;
  final PaymentRecap recap;

  const PrepaymentBottomBar({Key key, this.match, this.recap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
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
                    PaymentDetailsDescription(paymentRecap: recap),
                    Divider(),
                    Row(
                      children: [
                        Expanded(
                            child: (recap.finalPriceToPayInCents == 0)
                                ? PaymentConfirmationWithCreditsButton(
                                    match, recap)
                                : PaymentConfirmationButton(match, recap))
                      ],
                    )
                  ],
                ))));
  }
}

class PaymentDetailsDescription extends StatelessWidget {
  final PaymentRecap paymentRecap;

  const PaymentDetailsDescription({Key key, this.paymentRecap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          CircleAvatar(
              backgroundImage: NetworkImage(
                  context.watch<UserState>().getUserDetails().getPhotoUrl()),
              radius: 15),
          SizedBox(width: 10),
          Text("1x player", style: TextPalette.h3),
          Expanded(
              child: Text(
            formatCurrency.format(paymentRecap.matchPriceInCents / 100),
            style: TextPalette.h3,
            textAlign: TextAlign.end,
          ))
        ]),
        if (paymentRecap.creditsInCentsUsed != 0)
          Row(
            children: [
              // adding this here as a trick to align the rows
              CircleAvatar(backgroundColor: Colors.transparent, radius: 15),
              SizedBox(width: 10),
              Text('Credits', style: TextPalette.bodyText),
              Expanded(
                  child: Text(
                "- " +
                    formatCurrency
                        .format(paymentRecap.creditsInCentsUsed / 100),
                style: TextPalette.bodyText,
                textAlign: TextAlign.end,
              ))
            ],
          ),
        Divider(),
        if (paymentRecap.finalPriceToPayInCents() !=
            paymentRecap.matchPriceInCents)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Subtotal", style: TextPalette.h3),
                Text(
                  formatCurrency
                      .format(paymentRecap.finalPriceToPayInCents() / 100),
                  style: TextPalette.h3,
                )
              ],
            ),
          )
      ],
    );
    // : Row(
    //   children: [
    //     Column(
    //       children: [
    //         CircleAvatar(
    //             backgroundImage: NetworkImage(context
    //                 .watch<UserState>()
    //                 .getUserDetails()
    //                 .getPhotoUrl()),
    //             radius: 15),
    //       ],
    //     ),
    //     Column(
    //       children: [
    //         Row(
    //           children: [
    //             Text("1x player", style: TextPalette.h3),
    //             Expanded(
    //                 child: Text(
    //               formatCurrency
    //                   .format(paymentRecap.matchPriceInCents / 100),
    //               style: (paymentRecap.couponApplied != null)
    //                   ? TextPalette.h3WithBar
    //                   : TextPalette.h3,
    //               textAlign: TextAlign.end,
    //             ))
    //           ],
    //         ),
    //         // if (paymentRecap.couponApplied != null)
    //         //   Padding(
    //         //     padding: EdgeInsets.symmetric(vertical: 5),
    //         //     child: Row(
    //         //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //         //         children: [
    //         //           Padding(
    //         //             padding: EdgeInsets.only(left: 45),
    //         //             child: Text(paymentRecap.couponApplied.description,
    //         //                 style: TextPalette.h3),
    //         //           ),
    //         //           Text(
    //         //             formatCurrency
    //         //                 .format(paymentRecap.getPriceAfterCoupon() / 100),
    //         //             style: TextPalette.linkStyle,
    //         //           )
    //         //         ]),
    //         //   ),
    //         // if (paymentRecap.creditsInCentsUsed > 0)
    //         //   Padding(
    //         //     padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
    //         //     child: Column(
    //         //         crossAxisAlignment: CrossAxisAlignment.start,
    //         //         children: [
    //         //           Text(
    //         //               "Using " +
    //         //                   formatCurrency.format(
    //         //                       paymentRecap.creditsInCentsUsed / 100) +
    //         //                   " credits from your balance.",
    //         //               style: TextPalette.h3),
    //         //           SizedBox(height: 10),
    //         //           Text(
    //         //               (paymentRecap.finalPriceToPayInCents == 0)
    //         //                   ? "You don't have to pay anything now."
    //         //                   : "You have to pay " +
    //         //                   formatCurrency.format(
    //         //                       paymentRecap.finalPriceToPayInCents /
    //         //                           100) +
    //         //                   ".",
    //         //               style: TextPalette.h3),
    //         //         ]),
    //         //   ),
    //       ],
    //     )
    //   ],
    // ),
  }
}

class PostPaymentSuccessBottomBar extends StatelessWidget {
  final Match match;
  final PaymentOutcome paymentOutcome;

  const PostPaymentSuccessBottomBar({Key key, this.match, this.paymentOutcome})
      : super(key: key);

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
              onTap: () async =>
                  await DynamicLinks.shareMatchFunction(match.documentId),
              child: Row(
                children: [
                  Icon(Icons.share, color: Palette.primary),
                  SizedBox(width: 20),
                  Text("SHARE", style: TextPalette.linkStyle)
                ],
              ),
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
              "You joined this game: " +
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
                Expanded(child: LeaveConfirmationButton(match)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class LeaveConfirmationButton extends AbstractButtonWithLoader {
  final Match match;

  static RoundedLoadingButtonController leaveController =
      RoundedLoadingButtonController();

  LeaveConfirmationButton(this.match)
      : super(text: "CONFIRM", controller: leaveController);

  @override
  Future<void> onPressed(BuildContext context) async {
    await MatchesController.leaveMatch(context.read<MatchesState>(),
        match.documentId, context.read<UserState>());
    controller.success();
    await Future.delayed(Duration(seconds: 1));
    Navigator.of(context).pop(true);

    await showModalBottomSheet(
        context: context,
        builder: (context) => Container(
              margin: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: Text(
                          formatCurrency
                                  .format(match.pricePerPersonInCents / 100) +
                              " credits were added to your account",
                          style: TextPalette.h3)),
                  Text(
                      "You can find your credits in your account page. Next time you join a game they will be automatically used.",
                      style: TextPalette.bodyText),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: InkWell(
                        onTap: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => UserPage()));
                        },
                        child: Text("GO TO MY ACCOUNT",
                            style: TextPalette.linkStyle)),
                  )
                ],
              ),
            ));
  }
}

class PaymentConfirmationWithCreditsButton extends AbstractButtonWithLoader {
  final Match match;
  final PaymentRecap paymentRecap;

  static RoundedLoadingButtonController payConfirmController =
      RoundedLoadingButtonController();

  PaymentConfirmationWithCreditsButton(this.match, this.paymentRecap)
      : super(text: "PAY WITH CREDITS", controller: payConfirmController);

  @override
  Future<void> onPressed(BuildContext context) async {
    // update all states
    await MatchesController.joinMatch(context.read<MatchesState>(),
        match.documentId, context.read<UserState>(), paymentRecap);

    controller.success();
    await Future.delayed(Duration(seconds: 1));

    Navigator.pop(context, true);

    await showModalBottomSheet(
        context: context,
        builder: (context) => PostPaymentSuccessBottomBar(match: match));
  }
}

class PaymentConfirmationButton extends AbstractButtonWithLoader {
  final Match match;
  final PaymentRecap paymentRecap;

  static RoundedLoadingButtonController payConfirmController =
      RoundedLoadingButtonController();

  PaymentConfirmationButton(this.match, this.paymentRecap)
      : super(text: "CONTINUE TO PAYMENT", controller: payConfirmController);

  Future<void> onSuccess(BuildContext context) async {
    controller.success();
    await Future.delayed(Duration(seconds: 1));

    Navigator.pop(context, true);

    await showModalBottomSheet(
        context: context,
        builder: (context) => PostPaymentSuccessBottomBar(match: match));
  }

  // fixme deal better with this
  Future<void> onPaymentSuccessButJoinFailure(BuildContext context) async {
    controller.error();
    await Future.delayed(Duration(seconds: 1));

    Navigator.pop(context, true);

    GenericInfoModal(
            title: "Something went wrong!",
            body: "Please contact us for support")
        .show(context);
  }

  Future<void> onPaymentFailure(BuildContext context) async {
    controller.error();
    await Future.delayed(Duration(seconds: 1));

    Navigator.pop(context);

    GenericInfoModal(
            title: "Something went wrong!",
            body: "Please try again or contact us for support")
        .show(context);
  }

  @override
  Future<void> onPressed(BuildContext context) async {
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

    Status status = await Navigator.push(context,
        MaterialPageRoute(builder: (context) => PaymentSimulator(match)));

    if (status == Status.success) {
      // payment was good
      try {
        await MatchesController.joinMatch(context.read<MatchesState>(),
            match.documentId, context.read<UserState>(), paymentRecap);
      } catch (e) {
        // payment was good but joining the match was not. This shouldn't happen
        await onPaymentSuccessButJoinFailure(context);
      }
      await onSuccess(context);
    } else {
      await onPaymentFailure(context);
    }
  }
}

class JoinGameButton extends AbstractButtonWithLoader {
  final Match match;

  static RoundedLoadingButtonController joinController =
      RoundedLoadingButtonController();

  JoinGameButton(this.match)
      : super(text: 'JOIN GAME', width: 200, controller: joinController);

  @override
  Future<void> onPressed(BuildContext context) async {
    var userState = context.read<UserState>();
    var matchesState = context.read<MatchesState>();

    if (!userState.isLoggedIn()) {
      try {
        AfterLoginCommunication communication = await Navigator.push(
            context, MaterialPageRoute(builder: (context) => Login()));
        await GenericInfoModal(title: "Welcome", body: communication.text)
            .show(context);
      } catch (e) {
        CoolAlert.show(
            context: context,
            type: CoolAlertType.error,
            text: "Could not login");
        Navigator.pop(context);
        return;
      }
    }

    var paymentRecap = await PaymentController.generatePaymentRecap(
        matchesState, match.documentId, userState);

    GenericInfoModal.withBottom(
        title: "JOIN THIS GAME",
        body:
            "You can cancel up to 24h before the game starting time to get a full refund in credits to use on your next game.\nIf you cancel after this time you won't get a refund.",
        bottomWidget: Column(
          children: [
            Divider(),
            PaymentDetailsDescription(paymentRecap: paymentRecap),
            Divider(),
            Row(
              children: [
                Expanded(
                    child: (paymentRecap.finalPriceToPayInCents() == 0)
                        ? PaymentConfirmationWithCreditsButton(
                            match, paymentRecap)
                        : PaymentConfirmationButton(match, paymentRecap))
              ],
            )
          ],
        )).show(context);

    try {
      joinController.stop();
    } catch (e, _) {
      // didnt' find a better way to deal with this. If the button is disposed and this is still runing the stop would fail
    }
  }
}
