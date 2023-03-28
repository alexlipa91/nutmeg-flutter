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

          var url = "https://nutmeg-9099c.ew.r.appspot.com/payments/checkout?"
              "user_id=${userState.currentUserId}&match_id=$matchId";

          if (kIsWeb)
            await launchUrl(Uri.parse(url), webOnlyWindowName: "_self");
          else {
            bool? success = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Payment(matchId: matchId, url: url)),
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
  final String url;

  const Payment({Key? key, required this.matchId, required this.url})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: WebViewWidget(
          controller: WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setBackgroundColor(const Color(0x00000000))
            ..setNavigationDelegate(
              NavigationDelegate(
                onNavigationRequest: (NavigationRequest request) {
                  if (request.url == "https://web.nutmegapp.com/match/$matchId?payment_outcome=success")
                    Navigator.pop(context, true);
                  else if (request.url == "https://web.nutmegapp.com/match/$matchId?payment_outcome=cancel")
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
