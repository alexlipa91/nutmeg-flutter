import 'package:flutter/material.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/ModalPaymentDescriptionArea.dart';
import 'package:provider/provider.dart';

import '../state/MatchesState.dart';
import 'Launch.dart';
import 'UserPage.dart';

class LeaveButton extends StatelessWidget {
  final String matchId;

  const LeaveButton({Key key, this.matchId}) : super(key: key);

  @override
  Widget build(BuildContext context) => GenericButtonWithLoader(
        "LEAVE MATCH",
        (BuildContext context) async {
          var match = context.read<MatchesState>().getMatch(matchId);

          await GenericInfoModal(
              title: "Leave this match?",
              description: "We will refund you in credits that you can use in your next matches.",
              content:
              ModalPaymentDescriptionArea(
                rows: [],
                finalRow: Row(
                  children: [
                    Text("Credits refund", style: TextPalette.h3),
                    Expanded(
                        child: Text(
                          formatCurrency(match.pricePerPersonInCents) + " euro",
                          style: TextPalette.h3,
                          textAlign: TextAlign.end,
                        ))
                  ],
                ),
              ), action: Row(children: [Expanded(child: ConfirmLeaveMatchButton(match: match))])
              ).show(context);
        },
        Secondary(),
      );
}

class ConfirmLeaveMatchButton extends StatelessWidget {
  final Match match;

  const ConfirmLeaveMatchButton({Key key, this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) => GenericButtonWithLoader(
        "CONFIRM",
        (BuildContext context) async {
          context.read<GenericButtonWithLoaderState>().change(true);

          await MatchesController.leaveMatch(context,
              match.documentId);
          Navigator.of(context).pop(true);

          GenericInfoModal(
              title: formatCurrency(match.pricePerPersonInCents) +
                  " credits were added to your account",
              description:
                  "You can find your credits in your account page. Next time you join a game they will be automatically used.",
              action: InkWell(
                  onTap: () async {
                    await UserController.refreshCurrentUser(navigatorKey.currentContext);
                    Navigator.pushReplacement(navigatorKey.currentContext,
                        MaterialPageRoute(builder: (context) => UserPage()));
                  },
                  child:
                      Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text("GO TO MY ACCOUNT", style: TextPalette.linkStyle)))).show(context);
        },
        Primary(),
      );
}
