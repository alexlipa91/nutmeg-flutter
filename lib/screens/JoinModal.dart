import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/controller/PaymentController.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:provider/provider.dart';

import 'Login.dart';
import 'PaymentDetailsDescription.dart';

class JoinButton extends StatelessWidget {

  final Match match;

  const JoinButton({Key key, this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) => GenericStatefulButton(
    text: "JOIN",
    onPressed: (BuildContext context) async {
      context.read<GenericButtonState>().change(ButtonState.loading);
      await Future.delayed(Duration(milliseconds: 500));
      await JoinModal.onJoinGameAction(context, match);
      context.read<GenericButtonState>().change(ButtonState.idle);
    },
  );
}

class JoinModal {
  static var onJoinGameAction = (BuildContext context, Match match) async {
    var userState = context.read<UserState>();
    var matchesState = context.read<MatchesState>();

    if (!userState.isLoggedIn()) {
      try {
        AfterLoginCommunication communication = await Navigator.push(
            context, MaterialPageRoute(builder: (context) => Login()));
        if (communication != null) {
          await GenericInfoModal(title: "Welcome", body: communication.text)
              .show(context);
        }
      } catch (e) {
        // fixme proper alert
        UiUtils.showGenericErrorModal(context);
        Navigator.pop(context);
        return;
      }
    }

    if (userState.isLoggedIn()) {
      var paymentRecap = await PaymentController.generatePaymentRecap(
          matchesState, match.documentId, userState);

      var success = await GenericInfoModal.withBottom(
          title: "Join this game",
          body:
              "You can cancel up to 24h before the game starting time to get a full refund in credits to use on your next game.\nIf you cancel after this time you won't get a refund.",
          bottomWidget: Column(
            children: [
              Divider(),
              PaymentDetailsDescription(
                  match: match, paymentRecap: paymentRecap),
            ],
          )).show(context);
      if (success != null && !success) {
        UiUtils.showGenericErrorModal(context);
      }
    }
  };
}
