import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/state/MatchesState.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../controller/MatchesController.dart';
import '../model/PaymentRecap.dart';
import '../state/UserState.dart';
import 'package:auto_route/auto_route.dart';

import '../utils/InfoModals.dart';
import 'PaymentDetailsDescription.dart';

class PayWithMoneyButton extends StatelessWidget {

  final String matchId;
  final PaymentRecap paymentRecap;

  const PayWithMoneyButton(
      {Key? key, required this.matchId, required this.paymentRecap})
      : super(key: key);

  @override
  Widget build(BuildContext context) => GenericButtonWithLoader(
        AppLocalizations.of(context)!.continueToPayment,
        (BuildContext context) async {
          context.read<GenericButtonWithLoaderState>().change(true);

          var userState = context.read<UserState>();
          var match = context.read<MatchesState>().getMatch(matchId);
          var url =
              "https://europe-central2-nutmeg-9099c.cloudfunctions.net/go_to_stripe_checkout_v2?"
              "is_test=${match?.isTest}&user_id=${userState.currentUserId}&match_id=$matchId";

          if (kIsWeb) url = "$url&is_web=true";

          if (kIsWeb)
            await launchUrl(Uri.parse(url), webOnlyWindowName: "_self");
          else {
            bool? success = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Payment(matchId: matchId)),
            );
            if (success != null && success) {
              Navigator.pop(context);
              PaymentDetailsDescription.communicateSuccessToUser(context, match!);
              MatchesController.refresh(context, match.documentId);
            } else {
              GenericInfoModal(
                  title: "Payment Failed!", description: "Please try again")
                  .show(context);
            }
          }
        },
        Primary(),
      );
}

class Payment extends StatelessWidget {
  final String matchId;

  const Payment({Key? key, @PathParam('id') required this.matchId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var userState = context.read<UserState>();
    var match = context.read<MatchesState>().getMatch(matchId);
    var url = "https://nutmeg-9099c.ew.r.appspot.com/payments/checkout?"
        "is_test=${match?.isTest}&user_id=${userState.currentUserId}&match_id=$matchId";

    return SafeArea(
      child: Scaffold(
        body: WebViewWidget(
          controller: WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setBackgroundColor(const Color(0x00000000))
            ..setNavigationDelegate(
              NavigationDelegate(
                onNavigationRequest: (NavigationRequest request) {
                  if (request.url == "https://www.success.com/")
                    Navigator.pop(context, true);
                  else if (request.url == "https://www.cancel.com/")
                    Navigator.pop(context, false);
                  return NavigationDecision.navigate;
                },
              ),
            )
            ..loadRequest(Uri.parse(url)),
        ),
      ),
    );
  }
}
