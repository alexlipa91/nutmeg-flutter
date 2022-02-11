import 'package:flutter/material.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/screens/JoinModal.dart';
import 'package:nutmeg/screens/LeaveMatchModal.dart';
import 'package:nutmeg/screens/PayWithCreditsModal.dart';
import 'package:nutmeg/screens/PayWithMoneyModal.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/Buttons.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:provider/provider.dart';


class BottomBar extends StatelessWidget {
  final Match match;

  const BottomBar({Key key, this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var userState = context.watch<UserState>();

    var isGoing =
        userState.isLoggedIn() && match.isUserGoing(userState.getUserDetails());

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InfoContainer(
            child: Padding(
          padding: EdgeInsets.only(bottom: 20),
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
                          : (match.getSpotsLeft() == 0)
                              ? "Match Full"
                              : match.getSpotsLeft().toString() + " spots left",
                      style: TextPalette.h2),
                  SizedBox(height: 20),
                  Text(
                      (isGoing)
                          ? match.numPlayersGoing().toString() + " going"
                          : (match.getSpotsLeft() == 0)
                              ? "Find another game"
                              : formatCurrency(match.pricePerPersonInCents),
                      style: TextPalette.bodyText),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    (isGoing)
                        ? RoundedButtonLight("LEAVE GAME", () async {
                            var hoursToGame = match.dateTime
                                .difference(DateTime.now())
                                .inHours;

                            var userSub = match.going
                                .where((e) =>
                                    e.userId ==
                                    userState.getUserDetails().documentId)
                                .first;

                            var success = await GenericInfoModal.withBottom(
                                title: "Leaving this game?",
                                body: "You joined this game: " +
                                    getFormattedDate(userSub.createdAt) +
                                    ".\n" +
                                    ((hoursToGame < 24)
                                        ? "You will not receive a refund since the game is in less than 24 hours."
                                        : "We will refund you in credits that you can use in your next games."),
                                bottomWidget: Column(children: [
                                  Divider(),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 10.0),
                                    child: Row(
                                      children: [
                                        Text("Credits refund",
                                            style: TextPalette.h3),
                                        Expanded(
                                            child: Text(
                                          formatCurrency(match.pricePerPersonInCents) +
                                              " euro",
                                          style: TextPalette.h3,
                                          textAlign: TextAlign.end,
                                        ))
                                      ],
                                    ),
                                  ),
                                  Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(child: LeaveMatchButton(match: match)
                                          ),
                                    ],
                                  )
                                ])).show(context);

                            if (success != null && success == false) {
                              UiUtils.showGenericErrorModal(context);
                            }
                          })
                        : (!match.isFull())
                            ? JoinButton(match: match)
                            : RoundedButtonOff("JOIN GAME", null),
                  ],
                ),
              )
            ],
          ),
        ))
      ],
    );
  }
}

class PaymentDetailsDescription extends StatelessWidget {
  final Match match;
  final PaymentRecap paymentRecap;

  const PaymentDetailsDescription({Key key, this.match, this.paymentRecap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var matchesState = context.read<MatchesState>();
    var userState = context.read<UserState>();

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
            formatCurrency(match.pricePerPersonInCents),
            style: TextPalette.h3,
            textAlign: TextAlign.end,
          ))
        ]),
        if (paymentRecap.creditsInCentsUsed > 0)
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
                    formatCurrency(paymentRecap.creditsInCentsUsed),
                style: TextPalette.bodyText,
                textAlign: TextAlign.end,
              ))
            ],
          ),
        if (paymentRecap.creditsInCentsUsed > 0) Divider(),
        if (paymentRecap.creditsInCentsUsed > 0)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Subtotal", style: TextPalette.h3),
                Text(
                  formatCurrency(paymentRecap.finalPriceToPayInCents()),
                  style: TextPalette.h3,
                )
              ],
            ),
          ),
        Divider(),
        Row(
          children: [
            Expanded(
                child:
    (paymentRecap.finalPriceToPayInCents() == 0)
                            ? PayWithCreditsButton(
                                match: match, paymentRecap: paymentRecap)
                            :
                    PayWithMoneyButton(match: match)
                )
          ],
        )
      ],
    );
  }
}

// class LeaveConfirmationButton extends AbstractButtonWithLoader {
//   final Match match;
//
//   static RoundedLoadingButtonController leaveController =
//       RoundedLoadingButtonController();
//
//   LeaveConfirmationButton(this.match)
//       : super(text: "CONFIRM", controller: leaveController);
//
//   @override
//   Future<void> onPressed(BuildContext context) async {
//     try {
//       await MatchesController.leaveMatch(context.read<MatchesState>(),
//           match.documentId, context.read<UserState>());
//     }
//     catch (e, stackTrace) {
//       print(e);
//       print(stackTrace);
//       Navigator.pop(context, false);
//       return;
//     }
//
//     controller.success();
//     await Future.delayed(Duration(milliseconds: 500));
//     Navigator.of(context).pop(true);
//
//     GenericInfoModal.withBottom(
//           title: formatCurrency.format(match.pricePerPersonInCents / 100) +
//               " credits were added to your account",
//           body:
//           "You can find your credits in your account page. Next time you join a game they will be automatically used.",
//           bottomWidget: Padding(
//             padding: EdgeInsets.symmetric(vertical: 15),
//             child: InkWell(
//                 onTap: () {
//                   Navigator.pushReplacement(navigatorKey.currentContext,
//                       MaterialPageRoute(builder: (context) => UserPage()));
//                 },
//                 child: Text("GO TO MY ACCOUNT", style: TextPalette.linkStyle)),
//           )).show(context);
//   }
// }
//
// class PaymentConfirmationWithCreditsButton extends AbstractButtonWithLoader {
//   final Match match;
//   final PaymentRecap paymentRecap;
//
//   static RoundedLoadingButtonController payConfirmController =
//       RoundedLoadingButtonController();
//
//   PaymentConfirmationWithCreditsButton(this.match, this.paymentRecap)
//       : super(text: "PAY WITH CREDITS", controller: payConfirmController);
//
//   @override
//   Future<void> onPressed(BuildContext context) async {
//     // update all states
//     await MatchesController.joinMatch(context.read<MatchesState>(),
//         match.documentId, context.read<UserState>(), paymentRecap);
//
//     await Future.delayed(Duration(milliseconds: 500));
//
//     Navigator.pop(context, true);
//
//     await communicateSuccessToUser(context, match.documentId);
//   }
// }
//
// class PaymentConfirmationButton extends AbstractButtonWithLoader {
//   final Match match;
//   final PaymentRecap paymentRecap;
//
//   // fixme do not animate for now but we still need this controller
//   static RoundedLoadingButtonController payConfirmController =
//       RoundedLoadingButtonController();
//
//   PaymentConfirmationButton(this.match, this.paymentRecap)
//       : super(
//             text: "CONTINUE TO PAYMENT",
//             controller: payConfirmController,
//             shouldAnimate: false);
//
//   @override
//   Future<void> onPressed(BuildContext context) async {
//     payConfirmController.start();
//
//     var userState = context.read<UserState>();
//     var userDetails = userState.getUserDetails();
//
//     var sessionUrl;
//     try {
//       sessionUrl = await PaymentController.createCheckout(
//           match.stripePriceId,
//           userDetails.documentId,
//           match.documentId,
//           match.isTest
//       );
//     } catch (e) {
//       print(e);
//       Navigator.pop(context, false);
//     }
//
//     await launch(sessionUrl, forceSafariVC: false);
//   }
// }

Future<void> communicateSuccessToUser(
    BuildContext context, String matchId) async {
  await showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      isScrollControlled: true,
      context: context,
      builder: (context) => Container(
              child: Padding(
            padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                    radius: 100,
                    backgroundImage: NetworkImage(
                        "https://media.giphy.com/media/X6v9OaUTlnPuOI1r78/giphy.gif")),
                Padding(
                    padding: EdgeInsets.only(top: 30),
                    child: Text("You are in!", style: TextPalette.h1Default)),
                Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text("You have joined the match.",
                        style: TextPalette.bodyText)),
                if (!DeviceInfo().name.contains("ipad"))
                  Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: ShareButton.withText(matchId, Palette.primary))
              ],
            ),
          )));
}
