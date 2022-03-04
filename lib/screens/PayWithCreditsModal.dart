import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/screens/PaymentDetailsDescription.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';

import '../model/PaymentRecap.dart';


class PayWithCreditsButton extends StatelessWidget {

  final String matchId;
  final PaymentRecap paymentRecap;

  const PayWithCreditsButton({Key key, this.matchId, this.paymentRecap}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      GenericButtonWithLoader(
        "PAY WITH CREDITS",
        (BuildContext context) async {
          context.read<GenericButtonWithLoaderState>().change(true);

          await MatchesController.joinMatch(context, matchId, paymentRecap);
          context.read<GenericButtonWithLoaderState>().change(false);

          Get.back(result: true);
          await PaymentDetailsDescription.communicateSuccessToUser(context, matchId);
        },
        Primary(),
      );
}
