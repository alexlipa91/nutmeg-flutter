import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../model/PaymentRecap.dart';
import '../state/UserState.dart';

import '../utils/UiUtils.dart';

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

          var url = "https://nutmeg-9099c.ew.r.appspot.com/payments/checkout?"
              "user_id=${userState.currentUserId}&match_id=$matchId&v=2";

          var uri = Uri.parse(url);

          if (kIsWeb)
            await launchUrl(uri, webOnlyWindowName: "_self");
          else
            await launchUrl(uri);
        },
        Primary(),
      );
}

// class Payment extends StatelessWidget {
//   final String matchId;
//   final String url;
//
//   const Payment({Key? key, required this.matchId, required this.url})
//       : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Palette.primary,
//       body: SafeArea(
//         bottom: false,
//         child: WebViewWidget(
//           controller: WebViewController()
//             ..setJavaScriptMode(JavaScriptMode.unrestricted)
//             ..setBackgroundColor(const Color(0x00000000))
//             ..setNavigationDelegate(
//               NavigationDelegate(
//                 onNavigationRequest: (NavigationRequest request) {
//                   if (request.url == "https://web.nutmegapp.com/match/$matchId?payment_outcome=success")
//                     Navigator.pop(context, true);
//                   else if (request.url == "https://web.nutmegapp.com/match/$matchId?payment_outcome=cancel")
//                     Navigator.pop(context, false);
//                   return NavigationDecision.navigate;
//                 },
//               ),
//             )
//             ..loadRequest(Uri.parse(url)),
//         ),
//       ),
//     );
//   }
// }
