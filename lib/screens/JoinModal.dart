import 'package:flutter/material.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
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

import '../state/MatchesState.dart';
import '../state/UserState.dart';
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
      BuildContext context, int basePrice, int userFee) {
    int creditsUsed = 0;

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
          formatCurrency(basePrice),
          style: TextPalette.h3,
          textAlign: TextAlign.end,
        ))
      ]),
      if (userFee > 0)
        Row(
        children: [
          // adding this here as a trick to align the rows
          Container(height: 24, width: 24),
          SizedBox(width: 10),
          Text(
              AppLocalizations.of(context)!.serviceFee,
              style: TextPalette.bodyText),
          Expanded(
              child: Text(formatCurrency(userFee),
            style: TextPalette.bodyText,
            textAlign: TextAlign.end,
          ))
        ],
      ),
      if (creditsUsed > 0)
        Row(
          children: [
            // adding this here as a trick to align the rows
            Container(height: 24, width: 24),
            SizedBox(width: 10),
            Text('Credits', style: TextPalette.bodyText),
            Expanded(
                child: Text(
              "- " + formatCurrency(creditsUsed),
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
          formatCurrency(basePrice + userFee - creditsUsed),
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
      if (match!.price == null) {
        await CloudFunctionsClient().post("matches/$matchId/users/add", {
          "user_id": userState.currentUserId!
        });
        await context.read<MatchesState>().fetchMatch(matchId);
        await PaymentDetailsDescription.communicateSuccessToUser(context, matchId);
        await context.read<MatchesState>().fetchMatches("GOING", context);

        return;
      }

      await GenericInfoModal(
          title: AppLocalizations.of(context)!.joinThisMatchTitle,
          description: AppLocalizations.of(context)!.joinMatchInfo,
          content: getModalDescriptionArea(context,
            match.price!.basePrice,
            match.price!.userFee),
          action: Row(children: [
            Expanded(
                child:
                // (false)
                //     ? PayWithCreditsButton(
                //         match: match,)
                //     :
          PayWithMoneyButton(matchId: matchId))
          ])).show(context);
    }
  };
}
