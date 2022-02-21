import 'package:flutter/material.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/screens/PaymentDetailsDescription.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';


class PayWithCreditsButton extends StatelessWidget {

  final Match match;
  final PaymentRecap paymentRecap;

  const PayWithCreditsButton({Key key, this.match, this.paymentRecap}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      GenericButtonWithLoader(
        "PAY WITH CREDITS",
        (BuildContext context) async {
          context.read<GenericButtonWithLoaderState>().change(true);

          await MatchesController.joinMatch(context.read<MatchesState>(),
              match.documentId, context.read<UserState>(), paymentRecap);
          await MatchesController.refresh(context.read<MatchesState>(), match.documentId);
          context.read<GenericButtonWithLoaderState>().change(false);

          Navigator.pop(context, true);
          await PaymentDetailsDescription.communicateSuccessToUser(context, match.documentId);
        },
        Primary(),
      );
}
