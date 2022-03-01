import 'package:flutter/material.dart';
import 'package:nutmeg/controller/PaymentController.dart';
import 'package:nutmeg/state/MatchesState.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/PaymentRecap.dart';
import '../state/UserState.dart';


class PayWithMoneyButton extends StatelessWidget {

  final String matchId;
  final PaymentRecap paymentRecap;

  const PayWithMoneyButton({Key key, this.matchId, this.paymentRecap}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      GenericButtonWithLoader(
        "CONTINUE TO PAYMENT",
        (BuildContext context) async {
          context.read<GenericButtonWithLoaderState>().change(true);

          var userState = context.read<UserState>();
          var userDetails = userState.getLoggedUserDetails();
          var match = context.read<MatchesState>().getMatch(matchId);

          var sessionUrl;
          try {
            sessionUrl = await PaymentController.createCheckout(
                userDetails.documentId,
                matchId,
                paymentRecap.creditsInCentsUsed,
                match.isTest);
            context.read<GenericButtonWithLoaderState>().change(false);
          } catch (e) {
            print(e);
            Navigator.pop(context, false);
          }

          await launch(sessionUrl, forceSafariVC: false);
        },
        Primary(),
      );
}
