import 'package:flutter/material.dart';
import 'package:nutmeg/screens/Login.dart';
import 'package:nutmeg/screens/PaymentDetailsDescription.dart';
import 'package:nutmeg/state/MatchState.dart';
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
        null,
        Disabled(),
      );
}

class JoinButton extends StatelessWidget {
  final String matchId;

  const JoinButton({Key? key, required this.matchId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var matchState = context.read<MatchState>();
    var userState = context.read<UserState>();
    var matchesState = context.read<MatchesState>();

    return GenericButtonWithLoader(
      AppLocalizations.of(context)!.joinButtonText,
      (BuildContext context) async {
        var loaderState = context.read<GenericButtonWithLoaderState>();
        loaderState.change(true);
        await JoinModal.onJoinGameAction(context, userState, matchState, matchesState);
        // loaderState.change(false);
      },
      Primary(),
    );
  }
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
          child:
              UserAvatar(15, context.read<UserState>().getLoggedUserDetails()),
        ),
        SizedBox(width: 10),
        Text("1x ${AppLocalizations.of(context)!.player}",
            style: TextPalette.h3),
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
            Text(AppLocalizations.of(context)!.serviceFee,
                style: TextPalette.bodyText),
            Expanded(
                child: Text(
              formatCurrency(userFee),
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
        Text(AppLocalizations.of(context)!.subtotal, style: TextPalette.h3),
        Text(
          formatCurrency(basePrice + userFee - creditsUsed),
          style: TextPalette.h3,
        )
      ],
    );

    return ModalPaymentDescriptionArea(
        rows: List<Widget>.from(widgets), finalRow: finalRow);
  }

  static var onJoinGameAction = (BuildContext context, UserState userState,
      MatchState matchState, MatchesState matchesState) async {
    var userState = context.read<UserState>();
    var match = matchState.match;
    var matchId = matchState.matchId;

    if (!userState.isLoggedIn())
      await Navigator.push(
          context, MaterialPageRoute(builder: (context) => Login()));

    if (userState.isLoggedIn()) {
      // Free match or manual payment: join directly
      if (match!.price == null || match.isManualPayment) {
        await matchState.addLoggedInUserToMatch();
        matchesState.addToGoingMatches(matchId!);
        await PaymentDetailsDescription.communicateSuccessToUser(context, matchId);
        return;
      }

      // Stripe payment flow
      await GenericInfoModal(
          title: AppLocalizations.of(context)!.joinThisMatchTitle,
          description: AppLocalizations.of(context)!.joinMatchInfo,
          content: getModalDescriptionArea(
              context, match.price!.basePrice, match.price!.userFee),
          action: Row(children: [
            Expanded(
                child:
                    // (false)
                    //     ? PayWithCreditsButton(
                    //         match: match,)
                    //     :
                    PayWithMoneyButton(matchId: matchId!))
          ])).show(context);
    }
  };
}
