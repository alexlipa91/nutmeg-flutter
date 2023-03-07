import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nutmeg/controller/SportCentersController.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/screens/PaymentDetailsDescription.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';

import '../model/PaymentRecap.dart';


class PayWithCreditsButton extends StatelessWidget {

  final Match match;
  final PaymentRecap paymentRecap;

  const PayWithCreditsButton({Key? key, required this.match,
    required this.paymentRecap}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      GenericButtonWithLoader(
        "PAY WITH CREDITS",
        (BuildContext context) async {
          context.read<GenericButtonWithLoaderState>().change(true);

          await MatchesController.joinMatch(context, match.documentId,
              paymentRecap);
          context.read<GenericButtonWithLoaderState>().change(false);

          GoRouter.of(context).pop();
          await PaymentDetailsDescription.communicateSuccessToUser(context,
              match);
        },
        Primary(),
      );
}
