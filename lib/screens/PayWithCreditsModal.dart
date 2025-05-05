import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/screens/PaymentDetailsDescription.dart';
import 'package:nutmeg/state/MatchState.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';

import '../model/PaymentRecap.dart';

class PayWithCreditsButton extends StatelessWidget {
  final MatchState matchState;
  final PaymentRecap paymentRecap;

  const PayWithCreditsButton(
      {Key? key, required this.matchState, required this.paymentRecap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GenericButtonWithLoader(
      "PAY WITH CREDITS",
      (BuildContext context) async {
        context.read<GenericButtonWithLoaderState>().change(true);

        await matchState.addLoggedInUserToMatch();
        context.read<GenericButtonWithLoaderState>().change(false);

        GoRouter.of(context).pop();
        await PaymentDetailsDescription.communicateSuccessToUser(
            context, matchState.match!.documentId);
      },
      Primary(),
    );
  }
}
