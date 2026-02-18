import 'package:flutter/material.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/config/app_config.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/StripeSetupWidget.dart';
import 'package:provider/provider.dart';
import 'package:nutmeg/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/UserState.dart';

class PayThroughNutmegRow extends StatelessWidget {
  const PayThroughNutmegRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!ConfigsUtils.allowNutmegManagedPayments) {
      return Row(
        children: [
          Icon(Icons.credit_card_outlined, color: Palette.greyLight, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.payWithNutmegTitle,
                    style: TextPalette.getH3(Palette.greyDark)),
                SizedBox(height: 4),
                Text(AppLocalizations.of(context)!.comingSoon,
                    style: TextPalette.getBodyText(Palette.greyDark)),
              ],
            ),
          ),
        ],
      );
    }

    var userDetails = context.watch<UserState>().getLoggedUserDetails();
    var stripeInfo = userDetails?.getStripeInfo(AppConfig.testMode);
    var stripeEnabled = stripeInfo?.chargesEnabled ?? false;
    var hasAccount = stripeInfo?.connectedAccountId != null;

    var userId = userDetails?.documentId;

    return InkWell(
      onTap: stripeEnabled
          ? () {
              var url = CloudFunctionsClient().getUrl(
                  "stripe/account?is_test=${AppConfig.testMode}&user_id=$userId");
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            }
          : hasAccount
              ? () => completeAccountAction(context, AppConfig.testMode)
              : () => showStripeHowItWorksModal(context),
      child: Row(
        children: [
          Icon(
              stripeEnabled
                  ? Icons.credit_card_outlined
                  : Icons.warning_amber_rounded,
              color: stripeEnabled ? Palette.primary : Palette.darkWarning,
              size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.payWithNutmegTitle,
                    style: TextPalette.getH3(
                        stripeEnabled ? Palette.black : Palette.greyDark)),
                SizedBox(height: 4),
                if (stripeEnabled)
                  Text(AppLocalizations.of(context)!.stripeIntegrationActive,
                      style: TextPalette.getBodyText(Palette.green))
                else if (hasAccount)
                  Text(AppLocalizations.of(context)!.stripeSetupInProgress,
                      style: TextPalette.getBodyText(Palette.darkWarning))
                else
                  Text(
                      AppLocalizations.of(context)!.payWithNutmegNotConfigured,
                      style: TextPalette.getBodyText(Palette.darkWarning)),
              ],
            ),
          ),
          SizedBox(width: 8),
          if (stripeEnabled)
            Icon(Icons.open_in_new, color: Palette.primary, size: 20)
          else
            Icon(Icons.arrow_forward, color: Palette.darkWarning, size: 20),
        ],
      ),
    );
  }
}
