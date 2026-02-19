import 'package:flutter/material.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/screens/Login.dart';
import 'package:nutmeg/screens/PaymentDetailsDescription.dart';
import 'package:nutmeg/state/MatchState.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';
import 'package:nutmeg/l10n/app_localizations.dart';

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
        if (context.mounted) loaderState.change(false);
      },
      Primary(),
    );
  }
}

class JoinModal {
  static Widget getModalDescriptionArea(
      BuildContext context, Match match) {
    var totalPrice = match.price!.getTotalPrice();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, color: Palette.greyLighter),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppLocalizations.of(context)!.totalLabel, style: TextPalette.h3),
            Text(formatCurrency(totalPrice), style: TextPalette.h3),
          ],
        ),
      ],
    );
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
      var isOrganizer = match!.organizerId == userState.getLoggedUserId();

      // Free match, manual payment, or organizer: join directly
      if (match.price == null || match.isManualPayment || isOrganizer) {
        await matchState.addLoggedInUserToMatch();
        matchesState.addToGoingMatches(matchId!);
        await PaymentDetailsDescription.communicateSuccessToUser(context, matchId);
        return;
      }

      // Stripe payment flow
      await GenericInfoModal(
          title: AppLocalizations.of(context)!.joinThisMatchTitle,
          description: AppLocalizations.of(context)!.freeCancellationPolicy("24"),
          content: getModalDescriptionArea(context, match),
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
