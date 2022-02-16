import 'package:flutter/material.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/screens/JoinModal.dart';
import 'package:nutmeg/screens/LeaveMatchModal.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/Buttons.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:provider/provider.dart';


class BottomBarMatch extends StatelessWidget {
  final Match match;

  const BottomBarMatch({Key key, this.match}) : super(key: key);

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

                            await GenericInfoModal.withBottom(
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
                                          formatCurrency(
                                                  match.pricePerPersonInCents) +
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
                                      Expanded(
                                          child:
                                              LeaveMatchButton(match: match)),
                                    ],
                                  )
                                ])).show(context);
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
