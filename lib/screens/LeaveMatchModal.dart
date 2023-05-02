import 'package:flutter/material.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/ModalPaymentDescriptionArea.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../state/MatchesState.dart';

class LeaveButton extends StatelessWidget {
  final String matchId;

  const LeaveButton({Key? key, required this.matchId}) : super(key: key);

  @override
  Widget build(BuildContext context) => GenericButtonWithLoader(
        "LEAVE MATCH",
        (BuildContext context) async {
          var match = context.read<MatchesState>().getMatch(matchId);
          // fixme make it parametric
          var leaveMatchText;
          if (match!.price != null) {
            leaveMatchText = AppLocalizations.of(context)!.leaveMatchInfo;
            if (match.price!.userFee > 0) {
              leaveMatchText = leaveMatchText +
                  "\n" +
                  AppLocalizations.of(context)!
                      .leaveMatchServiceFeeInfo(formatCurrency(match.price!.userFee));
            }
          } else {
            leaveMatchText =
                AppLocalizations.of(context)!.leaveMatchNoMoneyInfo;
          }

          await GenericInfoModal(
              title: AppLocalizations.of(context)!.leaveThisMatchTitle,
              description: leaveMatchText,
              content: match.price != null
                  ? ModalPaymentDescriptionArea(
                      rows: [],
                      finalRow: Row(
                        children: [
                          Text(
                              ConfigsUtils.removeCreditsFunctionality()
                                  ? "Refund"
                                  : "Credits refund",
                              style: TextPalette.h3),
                          Expanded(
                              child: Text(
                            formatCurrency(match.price!.basePrice) + " euro",
                            style: TextPalette.h3,
                            textAlign: TextAlign.end,
                          ))
                        ],
                      ),
                    )
                  : null,
              action: Row(children: [
                Expanded(child: ConfirmLeaveMatchButton(match: match))
              ])).show(context);
        },
        Secondary(),
      );
}

class LeaveButtonDisabled extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GenericButtonWithLoader(
        "LEAVE MATCH",
        null,
        Disabled(),
      );
}

class ConfirmLeaveMatchButton extends StatelessWidget {
  final Match match;
  final int fee = 50;

  const ConfirmLeaveMatchButton({Key? key, required this.match})
      : super(key: key);

  @override
  Widget build(BuildContext context) => GenericButtonWithLoader(
        "CONFIRM",
        (BuildContext context) async {
          context.read<GenericButtonWithLoaderState>().change(true);

          await MatchesController.leaveMatch(context, match.documentId);
          Navigator.of(context).pop(true);

          GenericInfoModal(
                  title: match.price != null
                      ? ConfigsUtils.removeCreditsFunctionality()
                          ? "A refund of ${formatCurrency(match.price!.basePrice)} "
                              "was issued "
                          : formatCurrency(match.price!.basePrice) +
                              " credits were added to your account"
                      : "You left the match",
                  description: match.price != null
                      ? (ConfigsUtils.removeCreditsFunctionality()
                          ? "You will receive the money in 3 to 5 business days on the payment method you used."
                          : "You can find your credits in your account page. Next time you join a game they will be automatically used.")
                      : "",
                  action: match.price != null
                      ? InkWell(
                          onTap: () async {
                            context.read<UserState>().fetchLoggedUserDetails();
                            // Navigator.pushReplacement(navigatorKey.currentContext,
                            //     MaterialPageRoute(builder: (context) => UserPage()));
                          },
                          child: ConfigsUtils.removeCreditsFunctionality()
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text("GO TO MY ACCOUNT",
                                      style: TextPalette.linkStyle)))
                      : null)
              .show(context);
        },
        Primary(),
      );
}
