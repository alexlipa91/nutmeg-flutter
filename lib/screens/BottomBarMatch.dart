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

  const BottomBarMatch({Key key, this.match}) : super(key: key);

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
          child: Padding(
            padding: EdgeInsets.all(16.0),
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
                  child: button,
                  // Text("try"),
                  // Column(
                  //   crossAxisAlignment: CrossAxisAlignment.stretch,
                  //   children: [button],
                  // ),
                )
              ],
            ),
          ),
        )
      ],
    );
  }
}
