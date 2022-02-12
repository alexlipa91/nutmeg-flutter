import 'package:flutter/material.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/screens/PaymentDetailsDescription.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:provider/provider.dart';


class PayWithCreditsButton extends StatelessWidget {

  final Match match;
  final PaymentRecap paymentRecap;

  const PayWithCreditsButton({Key key, this.match, this.paymentRecap}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      GenericStatefulButton(
        text: "PAY WITH CREDITS",
        onPressed: (BuildContext context) async {
          context.read<GenericButtonState>().change(ButtonState.loading);

          await MatchesController.joinMatch(context.read<MatchesState>(),
              match.documentId, context.read<UserState>(), paymentRecap);
          await Future.delayed(Duration(milliseconds: 500));
          context.read<GenericButtonState>().change(ButtonState.idle);

          Navigator.pop(context, true);
          await PaymentDetailsDescription.communicateSuccessToUser(context, match.documentId);
        },
      );
}
