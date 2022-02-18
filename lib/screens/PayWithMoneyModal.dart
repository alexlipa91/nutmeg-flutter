import 'package:flutter/material.dart';
import 'package:nutmeg/controller/PaymentController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';


class PayWithMoneyButton extends StatelessWidget {

  final Match match;
  final PaymentRecap paymentRecap;

  const PayWithMoneyButton({Key key, this.match, this.paymentRecap}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      GenericButtonWithLoader(
        "CONTINUE TO PAYMENT",
        (BuildContext context) async {
          context.read<GenericButtonWithLoaderState>().change(true);

          var userState = context.read<UserState>();
          var userDetails = userState.getUserDetails();

          var sessionUrl;
          try {
            sessionUrl = await PaymentController.createCheckout(
                userDetails.documentId,
                match.documentId,
                paymentRecap.creditsInCentsUsed,
                match.isTest);
          } catch (e) {
            print(e);
            Navigator.pop(context, false);
          }

          await launch(sessionUrl, forceSafariVC: false);
        },
        Primary(),
      );
}
