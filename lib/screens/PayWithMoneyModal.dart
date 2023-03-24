import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/state/MatchesState.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../model/PaymentRecap.dart';
import '../state/UserState.dart';


class PayWithMoneyButton extends StatelessWidget {

  final String matchId;
  final PaymentRecap paymentRecap;

  const PayWithMoneyButton({Key? key, required this.matchId, required this.paymentRecap}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      GenericButtonWithLoader(
        AppLocalizations.of(context)!.continueToPayment,
        (BuildContext context) async {
          context.read<GenericButtonWithLoaderState>().change(true);

          var userState = context.read<UserState>();
          var match = context.read<MatchesState>().getMatch(matchId);
          var url = "https://europe-central2-nutmeg-9099c.cloudfunctions.net/go_to_stripe_checkout_v2?"
              "is_test=${match?.isTest}&user_id=${userState.currentUserId}&match_id=$matchId";

          if (kIsWeb)
            url = "$url&is_web=true";

          if (kIsWeb)
            await launchUrl(Uri.parse(url), webOnlyWindowName: "_self");
          else
            await launch(url, forceSafariVC: false);
        },
        Primary(),
      );
}
