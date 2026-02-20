import 'package:flutter/material.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/config/app_config.dart';
import 'package:nutmeg/l10n/app_localizations.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/ModalBottomSheet.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows the "How Pay with Nutmeg works" modal.
/// When [stripeEnabled] is true the CTA opens the Stripe dashboard instead of
/// starting the setup flow.
void showStripeHowItWorksModal(BuildContext context,
    {bool stripeEnabled = false, String? userId}) {
  ModalBottomSheet.showNutmegModalBottomSheet(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(AppLocalizations.of(context)!.howPayWithNutmegWorks,
            style: TextPalette.h2),
        SizedBox(height: 20),
        _stepRow("1", AppLocalizations.of(context)!.stripeStep1),
        SizedBox(height: 14),
        _stepRow("2", AppLocalizations.of(context)!.stripeStep2),
        SizedBox(height: 14),
        _stepRow("3", AppLocalizations.of(context)!.stripeStep3),
        SizedBox(height: 14),
        _stepRow("4", AppLocalizations.of(context)!.stripeStep4),
        SizedBox(height: 16),
        _infoRow(AppLocalizations.of(context)!.stripeInfoRefund),
        SizedBox(height: 10),
        _infoRow(AppLocalizations.of(context)!.stripeInfoFee),
        SizedBox(height: 24),
        Row(children: [
          Expanded(
              child: GenericButtonWithLoader(
                  stripeEnabled
                      ? AppLocalizations.of(context)!.goToStripeDashboardButton
                      : AppLocalizations.of(context)!.setupStripeIntegration,
                  (_) async {
            if (stripeEnabled && userId != null) {
              var url = CloudFunctionsClient().getUrl(
                  "stripe/account?is_test=${AppConfig.testMode}&user_id=$userId");
              launchUrl(Uri.parse(url),
                  mode: LaunchMode.externalApplication);
            } else {
              await completeAccountAction(context, AppConfig.testMode);
            }
            Navigator.pop(context);
          }, Primary()))
        ]),
      ],
    ),
  );
}

Widget _stepRow(String number, String text) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Palette.primary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(number, style: TextPalette.getH3(Palette.white)),
        ),
      ),
      SizedBox(width: 12),
      Expanded(
        child: Text(text, style: TextPalette.bodyText),
      ),
    ],
  );
}

Widget _infoRow(String text) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 24,
        height: 24,
        child: Center(
          child: Icon(Icons.info_outline, color: Palette.greyLight, size: 22),
        ),
      ),
      SizedBox(width: 12),
      Expanded(
        child: Text(text, style: TextPalette.bodyText),
      ),
    ],
  );
}

/// Inline widget showing Stripe setup status with tap to open modal or continue setup.
/// Use this in any page where the user needs to set up Stripe.
class StripeSetupBanner extends StatelessWidget {
  final bool hasAccount;
  final String? message;

  const StripeSetupBanner({
    Key? key,
    required this.hasAccount,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: hasAccount
          ? () => completeAccountAction(context, AppConfig.testMode)
          : () => showStripeHowItWorksModal(context),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Palette.greyLightest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Palette.greyLight),
        ),
        child: Row(
          children: [
            Icon(Icons.credit_card_outlined,
                color: Palette.greyLight, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.payWithNutmegTitle,
                      style: TextPalette.getH3(Palette.greyDark)),
                  SizedBox(height: 4),
                  if (hasAccount)
                    Text(
                        AppLocalizations.of(context)!.stripeSetupInProgress,
                        style: TextPalette.getBodyText(Palette.primary))
                  else
                    Text(
                        message ??
                            AppLocalizations.of(context)!
                                .payWithNutmegNotConfigured,
                        style: TextPalette.getBodyText(Palette.greyDark)),
                ],
              ),
            ),
            SizedBox(width: 8),
            if (hasAccount)
              Icon(Icons.arrow_forward, color: Palette.primary, size: 20)
            else
              Icon(Icons.info_outline, color: Palette.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
