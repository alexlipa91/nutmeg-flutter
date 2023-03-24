import 'package:flutter/material.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/controller/PaymentController.dart';
import 'package:nutmeg/screens/Login.dart';
import 'package:nutmeg/screens/PaymentDetailsDescription.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/ModalPaymentDescriptionArea.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../controller/MatchesController.dart';
import '../model/PaymentRecap.dart';
import '../state/MatchesState.dart';
import '../state/UserState.dart';
import 'PayWithCreditsModal.dart';
import 'PayWithMoneyModal.dart';

class JoinButtonDisabled extends StatelessWidget {

  @override
  Widget build(BuildContext context) => GenericButtonWithLoader(
    AppLocalizations.of(context)!.joinButtonText,
    null, Disabled(),
  );
}

class JoinButton extends StatelessWidget {
  final String matchId;

  const JoinButton({Key? key, required this.matchId}) : super(key: key);

  @override
  Widget build(BuildContext context) => GenericButtonWithLoader(
        AppLocalizations.of(context)!.joinButtonText,
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
          child: UserAvatar(15,
              context.read<UserState>().getLoggedUserDetails()),
        ),
        SizedBox(width: 10),
        Text("1x ${AppLocalizations.of(context)!.player}", style: TextPalette.h3),
        Expanded(
            child: Text(
          formatCurrency(paymentRecap.matchPriceInCents - paymentRecap.fee),
          style: TextPalette.h3,
          textAlign: TextAlign.end,
        ))
      ]),
      if (paymentRecap.fee > 0)
        Row(
        children: [
          // adding this here as a trick to align the rows
          Container(height: 24, width: 24),
          SizedBox(width: 10),
          Text(
              AppLocalizations.of(context)!.serviceFee,
              style: TextPalette.bodyText),
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
        Text(
            AppLocalizations.of(context)!.subtotal,
            style: TextPalette.h3),
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

    if (!userState.isLoggedIn())
      await Navigator.push(context,
          MaterialPageRoute(builder: (context) => Login()));

    if (userState.isLoggedIn()) {
      var paymentRecap = await PaymentController.generatePaymentRecap(
          context, match!.documentId);

      if (!match.managePayments) {
        await CloudFunctionsClient().callFunction("add_user_to_match", {
          "match_id": matchId,
          "user_id": userState.currentUserId!
        });
        await MatchesController.refresh(context, matchId);
        await PaymentDetailsDescription.communicateSuccessToUser(context, match);

        return;
      }

      await GenericInfoModal(
          title: AppLocalizations.of(context)!.joinThisMatchTitle,
          description: AppLocalizations.of(context)!.joinMatchInfo,
          content: getModalDescriptionArea(context, paymentRecap),
          action: Row(children: [
            Expanded(
                child: (paymentRecap.finalPriceToPayInCents() == 0)
                    ? PayWithCreditsButton(
                        match: match, paymentRecap: paymentRecap)
                    : PayWithMoneyButton(
                        matchId: matchId, paymentRecap: paymentRecap))
          ])).show(context);
    }
  };
}
