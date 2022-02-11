import 'package:flutter/material.dart';
import 'package:nutmeg/controller/PaymentController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';


class PayWithMoneyButton extends StatelessWidget {

  final Match match;

  const PayWithMoneyButton({Key key, this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      GenericStatefulButton(
        text: "CONTINUE TO PAYMENT",
        onPressed: (BuildContext context) async {
          context.read<GenericButtonState>().change(ButtonState.loading);

          var userState = context.read<UserState>();
          var userDetails = userState.getUserDetails();

          var sessionUrl;
          try {
            sessionUrl = await PaymentController.createCheckout(
                match.stripePriceId,
                userDetails.documentId,
                match.documentId,
                match.isTest);
          } catch (e) {
            print(e);
            Navigator.pop(context, false);
          }

          await launch(sessionUrl, forceSafariVC: false);
        },
      );
}
