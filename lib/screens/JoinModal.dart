import 'package:flutter/material.dart';
import 'package:nutmeg/controller/PaymentController.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';

import 'Login.dart';
import 'PaymentDetailsDescription.dart';

class JoinButton extends StatelessWidget {

  final Match match;

  const JoinButton({Key key, this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) => GenericButtonWithLoader(
    "JOIN",
    (BuildContext context) async {
      context.read<GenericButtonWithLoaderState>().change(true);
      await JoinModal.onJoinGameAction(context, match);
      context.read<GenericButtonWithLoaderState>().change(false);
    },
    Primary(),
  );
}

class JoinModal {
  static var onJoinGameAction = (BuildContext context, Match match) async {
    var userState = context.read<UserState>();
    var matchesState = context.read<MatchesState>();

    if (!userState.isLoggedIn()) {
      AfterLoginCommunication communication = await Navigator.push(
            context, MaterialPageRoute(builder: (context) => Login()));
        if (communication != null) {
          await GenericInfoModal(title: "Welcome", body: communication.text)
              .show(context);
        }
    }

    if (userState.isLoggedIn()) {
      var paymentRecap = await PaymentController.generatePaymentRecap(
          matchesState, match.documentId, userState);

      await GenericInfoModal.withBottom(
          title: "Join this match",
          body:
              "You can cancel up to 24h before the game time to get a full refund in credits to use on your next game.\nAfter that, you won't get a refund.",
          bottomWidget: Column(
            children: [
              Divider(),
              PaymentDetailsDescription(
                  match: match, paymentRecap: paymentRecap),
            ],
          )).show(context);
    }
  };
}
