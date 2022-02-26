import 'package:flutter/material.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/screens/JoinModal.dart';
import 'package:nutmeg/screens/LeaveMatchModal.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';


class BottomBarMatch extends StatelessWidget {
  final Match match;
  final double extraBottomPadding;

  const BottomBarMatch({Key key, this.match, this.extraBottomPadding}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var userState = context.watch<UserState>();
    var isGoing =
        userState.isLoggedIn() && match.isUserGoing(userState.getUserDetails());

    var button = (isGoing) ? LeaveButton(match: match)
        : (!match.isFull())
        ? JoinButton(match: match)
        : GenericButtonWithLoader("JOIN MATCH", null, Disabled());

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Palette.white,
            boxShadow: [
              BoxShadow(
                color: Palette.black.withOpacity(0.1), spreadRadius: 0,
                blurRadius: 20, offset: Offset(0, 10),
              )
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0,
                bottom: 16.0 + extraBottomPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          (isGoing)
                              ? "You are in!"
                              : (match.getSpotsLeft() == 0)
                                  ? "Match Full"
                                  : match.getSpotsLeft().toString() + " spots left",
                          style: TextPalette.h2),
                      SizedBox(height: 4,),
                      Text(
                          (isGoing)
                              ? match.numPlayersGoing().toString() + " going"
                              : (match.getSpotsLeft() == 0)
                                  ? "Find another match"
                                  : formatCurrency(match.pricePerPersonInCents),
                          style: TextPalette.bodyText),
                    ],
                  ),
                ),
                Container(
                  child: button
                )
              ],
            ),
          ),
        )
      ],
    );
  }
}
