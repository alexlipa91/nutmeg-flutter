import 'package:flutter/material.dart';
import 'package:nutmeg/controller/PaymentController.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/ModalPaymentDescriptionArea.dart';
import 'package:provider/provider.dart';

import '../model/PaymentRecap.dart';
import '../state/MatchesState.dart';
import '../state/UserState.dart';
import 'PayWithCreditsModal.dart';
import 'PayWithMoneyModal.dart';

class JoinButtonDisabled extends StatelessWidget {

  @override
  Widget build(BuildContext context) => GenericButtonWithLoader(
    "JOIN MATCH", null, Disabled(),
  );
}

class JoinButton extends StatelessWidget {
  final String matchId;

  const JoinButton({Key? key, required this.matchId}) : super(key: key);

  @override
  Widget build(BuildContext context) => GenericButtonWithLoader(
        "JOIN MATCH",
        (BuildContext context) async {
          context.read<GenericButtonWithLoaderState>().change(true);
          await JoinModal.onJoinGameAction(context, matchId);
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
                  context.read<UserState>().getLoggedUserDetails()!.getPhotoUrl()!),
              radius: 15),
        ),
        SizedBox(width: 10),
        Text("1x player", style: TextPalette.h3),
        Expanded(
            child: Text(
          formatCurrency(paymentRecap.matchPriceInCents - paymentRecap.fee),
          style: TextPalette.h3,
          textAlign: TextAlign.end,
        ))
      ]),
      Row(
        children: [
          // adding this here as a trick to align the rows
          Container(height: 24, width: 24),
          SizedBox(width: 10),
          Text('Service Fee', style: TextPalette.bodyText),
          Expanded(
              child: Text(formatCurrency(paymentRecap.fee),
            style: TextPalette.bodyText,
            textAlign: TextAlign.end,
          ))
        ],
      ),
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

  static var onJoinGameAction = (BuildContext context, String matchId) async {
    var userState = context.read<UserState>();
    var match = context.read<MatchesState>().getMatch(matchId);

    if (!userState.isLoggedIn()) {
      // AfterLoginCommunication communication = await Navigator.push(
      //     context, MaterialPageRoute(builder: (context) => Login()));
      // if (communication != null) {
      //   await GenericInfoModal(title: "Welcome", description: communication.text)
      //       .show(context);
      // }
    }

    if (userState.isLoggedIn()) {
      var paymentRecap = await PaymentController.generatePaymentRecap(
          context, match!.documentId);

      await GenericInfoModal(
          title: "Join this match",
          description:
              "If you leave the match you will get a refund in credits.",
          content: getModalDescriptionArea(context, paymentRecap),
          action: Row(children: [
            Expanded(
                child: (paymentRecap.finalPriceToPayInCents() == 0)
                    ? PayWithCreditsButton(
                        matchId: matchId, paymentRecap: paymentRecap)
                    : PayWithMoneyButton(
                        matchId: matchId, paymentRecap: paymentRecap))
          ])).show(context);
    }
  };
}
