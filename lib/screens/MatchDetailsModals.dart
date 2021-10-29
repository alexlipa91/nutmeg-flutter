import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/controller/PaymentController.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/screens/Launch.dart';
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InfoContainer(
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
                        : formatCurrency
                            .format(match.pricePerPersonInCents / 100),
                    style: TextPalette.bodyText),
              ],
            ),
            (isGoing)
                ? RoundedButtonLight("LEAVE GAME", () async {
                    var hoursToGame =
                        match.dateTime.difference(DateTime.now()).inHours;

                    await GenericInfoModal.withBottom(
                        title: "Leaving this game?",
                        body: "You joined this game: " +
                            getFormattedDate(userSub.createdAt.toDate()) +
                            ".\n" +
                            ((hoursToGame < 24)
                                ? "You will not receive a refund since the game is in less than 24 hours."
                                : "We will refund you in credits that you can use in your next games."),
                        bottomWidget: Column(children: [
                          Divider(),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 10.0),
                            child: Row(
                              children: [
                                Text("Credits refund", style: TextPalette.h3),
                                Expanded(
                                    child: Text(
                                  formatCurrency.format(
                                          match.pricePerPersonInCents / 100) +
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
                        ])).show(context);
                  })
                : (!match.isFull())
                    ? JoinGameButton(match: match)
                    : RoundedButton("JOIN", null)
          ],
        ))
      ],
    );
  }
}

class PaymentDetailsDescription extends StatelessWidget {
  final Match match;

  const PaymentDetailsDescription({Key key, this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var matchesState = context.read<MatchesState>();
    var userState = context.read<UserState>();

    return FutureBuilder<PaymentRecap>(
        future: PaymentController.generatePaymentRecap(
            matchesState, match.documentId, userState),
        builder: (context, snapshot) {
          var extraCreditsUsed =
              snapshot.data != null && snapshot.data.creditsInCentsUsed != 0;

          return Column(
            children: [
              Row(children: [
                CircleAvatar(
                    backgroundImage: NetworkImage(context
                        .watch<UserState>()
                        .getUserDetails()
                        .getPhotoUrl()),
                    radius: 15),
                SizedBox(width: 10),
                Text("1x player", style: TextPalette.h3),
                Expanded(
                    child: Text(
                  formatCurrency.format(match.pricePerPersonInCents / 100),
                  style: TextPalette.h3,
                  textAlign: TextAlign.end,
                ))
              ]),
              if (extraCreditsUsed)
                Row(
                  children: [
                    // adding this here as a trick to align the rows
                    CircleAvatar(
                        backgroundColor: Colors.transparent, radius: 15),
                    SizedBox(width: 10),
                    Text('Credits', style: TextPalette.bodyText),
                    Expanded(
                        child: Text(
                      "- " +
                          formatCurrency
                              .format(snapshot.data.creditsInCentsUsed / 100),
                      style: TextPalette.bodyText,
                      textAlign: TextAlign.end,
                    ))
                  ],
                ),
              if (extraCreditsUsed) Divider(),
              if (extraCreditsUsed)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Subtotal", style: TextPalette.h3),
                      Text(
                        formatCurrency.format(
                            snapshot.data.finalPriceToPayInCents() / 100),
                        style: TextPalette.h3,
                      )
                    ],
                  ),
                ),
              Divider(),
              Row(
                children: [
                  Expanded(
                      child: (snapshot.data == null)
                          ? ButtonWithLoader("", () {})
                          : (snapshot.data.onlyCreditsUsed())
                              ? PaymentConfirmationWithCreditsButton(
                                  match, snapshot.data)
                              : PaymentConfirmationButton(match, snapshot.data))
                ],
              )
            ],
          );
        });
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
    await Future.delayed(Duration(milliseconds: 500));
    Navigator.of(context).pop(true);

    GenericInfoModal.withBottom(
        title: formatCurrency.format(match.pricePerPersonInCents / 100) +
            " credits were added to your account",
        body:
            "You can find your credits in your account page. Next time you join a game they will be automatically used.",
        bottomWidget: Padding(
          padding: EdgeInsets.symmetric(vertical: 15),
          child: InkWell(
              onTap: () {
                Navigator.pushReplacement(navigatorKey.currentContext,
                    MaterialPageRoute(builder: (context) => UserPage()));
              },
              child: Text("GO TO MY ACCOUNT", style: TextPalette.linkStyle)),
        )).show(context);
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

    await Future.delayed(Duration(milliseconds: 500));

    Navigator.pop(context, true);

    await communicateSuccessToUser(context, match.documentId);
  }
}

Future<void> communicateSuccessToUser(
    BuildContext context, String matchId) async {
  await GenericInfoModal.withBottom(
    title: "You are going to this game",
    body: "You have successfully paid and joined this game",
    bottomWidget: InkWell(
      onTap: () async => await DynamicLinks.shareMatchFunction(matchId),
      child: Row(
        children: [
          ShareButton(matchId: matchId),
          SizedBox(width: 20),
          Text("SHARE", style: TextPalette.linkStyle)
        ],
      ),
    ),
  ).show(context);
}

class PaymentConfirmationButton extends AbstractButtonWithLoader {
  final Match match;
  final PaymentRecap paymentRecap;

  // fixme do not animate for now but we still need this controller
  static RoundedLoadingButtonController payConfirmController =
      RoundedLoadingButtonController();

  PaymentConfirmationButton(this.match, this.paymentRecap)
      : super(
            text: "CONTINUE TO PAYMENT",
            controller: payConfirmController,
            shouldAnimate: false);

  Future<void> onSuccess(BuildContext context) async {
    Navigator.pop(context, true);
    await communicateSuccessToUser(context, match.documentId);
  }

  // fixme deal better with this
  Future<void> onPaymentSuccessButJoinFailure(BuildContext context) async {
    // controller.error();
    // await Future.delayed(Duration(seconds: 1));

    Navigator.pop(context, true);

    GenericInfoModal(
            title: "Something went wrong!",
            body: "Please contact us for support")
        .show(context);
  }

  Future<void> onPaymentFailure(BuildContext context) async {
    // controller.error();
    // await Future.delayed(Duration(seconds: 1));

    Navigator.pop(context);

    GenericInfoModal(
            title: "Payment Failed!",
            body: "Please try again or contact us for support")
        .show(context);
  }

  @override
  Future<void> onPressed(BuildContext context) async {
    payConfirmController.start();

    var userDetails = context.read<UserState>().getUserDetails();

    var customerId = await Server().createCustomer(userDetails.name, userDetails.email);
    var sessionId = await Server().createCheckout(customerId, 1000);

    Status status = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CheckoutPage(sessionId, paymentRecap, match)));

    switch (status) {
      case Status.success:
        await onSuccess(context);
        break;
      case Status.paymentSuccessButJoinFailed:
        await onPaymentSuccessButJoinFailure(context);
        break;
      default:
        await onPaymentFailure(context);
        break;
    }
  }
}

class JoinGameButton extends StatelessWidget {
  final Match match;

  const JoinGameButton({Key key, this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
        children: [Container(width: 200, child: JoinGameButtonNoSize(match))]);
  }
}

class JoinGameButtonNoSize extends AbstractButtonWithLoader {
  final Match match;

  // fixme do not animate for now but we still need this controller
  static RoundedLoadingButtonController joinController =
      RoundedLoadingButtonController();

  JoinGameButtonNoSize(this.match)
      : super(
            text: 'JOIN GAME',
            controller: joinController,
            shouldAnimate: false);

  @override
  Future<void> onPressed(BuildContext context) async =>
      onJoinGameAction(context, match);
}

onJoinGameAction(BuildContext context, Match match) async {
  var userState = context.read<UserState>();

  if (!userState.isLoggedIn()) {
    try {
      AfterLoginCommunication communication = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => Login()));
      if (communication != null) {
        await GenericInfoModal(title: "Welcome", body: communication.text)
            .show(context);
      }
    } catch (e) {
      CoolAlert.show(
          context: context, type: CoolAlertType.error, text: "Could not login");
      Navigator.pop(context);
      return;
    }
  }

  GenericInfoModal.withBottom(
      title: "Jon this game",
      body:
          "You can cancel up to 24h before the game starting time to get a full refund in credits to use on your next game.\nIf you cancel after this time you won't get a refund.",
      bottomWidget: Column(
        children: [
          Divider(),
          PaymentDetailsDescription(match: match),
        ],
      )).show(context);
}
