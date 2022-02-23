import 'package:flutter/material.dart';
import 'package:nutmeg/controller/PaymentController.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/ModalPaymentDescriptionArea.dart';
import 'package:provider/provider.dart';

import 'Login.dart';
import 'PayWithCreditsModal.dart';
import 'PayWithMoneyModal.dart';

class JoinButton extends StatelessWidget {
  final Match match;

  const JoinButton({Key key, this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) => GenericButtonWithLoader(
        "JOIN MATCH",
        (BuildContext context) async {
          context.read<GenericButtonWithLoaderState>().change(true);
          await JoinModal.onJoinGameAction(context, match);
          context.read<GenericButtonWithLoaderState>().change(false);
        },
        Primary(),
      );
}

class JoinModal {
  static Widget getModalDescriptionArea(
      BuildContext context, PaymentRecap paymentRecap) {
    var widgets = [
      Row(children: [
        Container(
          height: 24,
          width: 24,
          child: CircleAvatar(
              backgroundColor: Colors.transparent,
              backgroundImage: NetworkImage(
                  context.read<UserState>().getUserDetails().getPhotoUrl()),
              radius: 15),
        ),
        SizedBox(width: 10),
        Text("1x player", style: TextPalette.h3),
        Expanded(
            child: Text(
          formatCurrency(paymentRecap.matchPriceInCents),
          style: TextPalette.h3,
          textAlign: TextAlign.end,
        ))
      ]),
      if (paymentRecap.creditsInCentsUsed > 0)
        Row(
          children: [
            // adding this here as a trick to align the rows
            Container(height: 24, width: 24),
            SizedBox(width: 10),
            Text('Credits', style: TextPalette.bodyText),
            Expanded(
                child: Text(
              "- " + formatCurrency(paymentRecap.creditsInCentsUsed),
              style: TextPalette.bodyText,
              textAlign: TextAlign.end,
            ))
          ],
        ),
    ];

    var finalRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Subtotal", style: TextPalette.h3),
        Text(
          formatCurrency(paymentRecap.finalPriceToPayInCents()),
          style: TextPalette.h3,
        )
      ],
    );

    return ModalPaymentDescriptionArea(
        rows: List<Widget>.from(widgets), finalRow: finalRow);
  }

  static var onJoinGameAction = (BuildContext context, Match match) async {
    var userState = context.read<UserState>();
    var matchesState = context.read<MatchesState>();

    if (!userState.isLoggedIn()) {
      AfterLoginCommunication communication = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => Login()));
      if (communication != null) {
        await GenericInfoModal(title: "Welcome", description: communication.text)
            .show(context);
      }
    }

    if (userState.isLoggedIn()) {
      var paymentRecap = await PaymentController.generatePaymentRecap(
          matchesState, match.documentId, userState);

      await GenericInfoModal(
          title: "Join this match",
          description:
              "You can cancel up to 24h before the game time to get a full refund in credits to use on your next game.\nAfter that, you won't get a refund.",
          content: getModalDescriptionArea(context, paymentRecap),
          action: Row(children: [
            Expanded(
                child: (paymentRecap.finalPriceToPayInCents() == 0)
                    ? PayWithCreditsButton(
                        match: match, paymentRecap: paymentRecap)
                    : PayWithMoneyButton(
                        match: match, paymentRecap: paymentRecap))
          ])).show(context);
    }
  };
}
