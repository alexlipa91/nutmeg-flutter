import 'package:flutter/material.dart';
import 'package:nutmeg/config/app_config.dart';
import 'package:nutmeg/state/MatchState.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/ModalPaymentDescriptionArea.dart';
import 'package:provider/provider.dart';
import 'package:nutmeg/l10n/app_localizations.dart';

class LeaveButton extends StatelessWidget {
  final String matchId;

  const LeaveButton({Key? key, required this.matchId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GenericButtonWithLoader(
      AppLocalizations.of(context)!.leaveButtonText,
      (BuildContext context) async {
        var state = context.read<MatchState>();
        var match = state.match;
        var paidThroughNutmeg = match!.price != null && !match.isManualPayment;
        // fixme make it parametric
        var leaveMatchText;
        if (paidThroughNutmeg) {
          leaveMatchText = AppLocalizations.of(context)!.leaveMatchInfo;
          if (match.price!.userFee > 0) {
            leaveMatchText = leaveMatchText +
                "\n" +
                AppLocalizations.of(context)!.leaveMatchServiceFeeInfo(
                    formatCurrency(match.price!.userFee));
          }
        } else {
          leaveMatchText = AppLocalizations.of(context)!.leaveMatchNoMoneyInfo;
        }

        await GenericInfoModal(
            title: AppLocalizations.of(context)!.leaveThisMatchTitle,
            description: leaveMatchText,
            content: paidThroughNutmeg
                ? ModalPaymentDescriptionArea(
                    rows: [],
                    finalRow: Row(
                      children: [
                        Text(
                            AppLocalizations.of(context)!
                                .leaveMatchRefundTitle,
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
              Expanded(child: ConfirmLeaveMatchButton(matchState: state))
            ])).show(context);
      },
      Secondary(),
    );
  }
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
  final MatchState matchState;
  final int fee = AppConfig.nutmegFeeCents;

  const ConfirmLeaveMatchButton({Key? key, required this.matchState})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var match = matchState.match!;

    var paidThroughNutmeg = match.price != null && !match.isManualPayment;

    return GenericButtonWithLoader(
      AppLocalizations.of(context)!.confirmButtonText,
      (BuildContext context) async {
        context.read<GenericButtonWithLoaderState>().change(true);

        await matchState.removeLoggedInUserFromMatch();
        Navigator.of(context).pop(true);

        if (match.price != null) {
          GenericInfoModal(
                  title: paidThroughNutmeg
                      ? "A refund of ${formatCurrency(match.price!.basePrice)} "
                          "was issued "
                      : AppLocalizations.of(context)!.leftMatchTitle,
                  description: paidThroughNutmeg
                      ? "You will receive the money in 3 to 5 business days on the payment method you used."
                      : AppLocalizations.of(context)!
                            .leftMatchContactOrganizerForRefund,
                  action: null)
              .show(context);
        }
      },
      Primary(),
    );
  }
}
