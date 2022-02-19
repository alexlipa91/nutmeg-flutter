import 'package:flutter/material.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';


import 'Launch.dart';
import 'UserPage.dart';


class LeaveMatchButton extends StatelessWidget {

  final Match match;

  const LeaveMatchButton({Key key, this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      GenericButtonWithLoader(
        "CONFIRM",
        (BuildContext context) async {
          context.read<GenericButtonWithLoaderState>().change(true);

          await MatchesController.leaveMatch(context.read<MatchesState>(),
              match.documentId, context.read<UserState>());
          Navigator.of(context).pop(true);

          var userState = context.read<UserState>();

          GenericInfoModal.withBottom(
              title: formatCurrency(match.pricePerPersonInCents) +
                  " credits were added to your account",
              body:
              "You can find your credits in your account page. Next time you join a game they will be automatically used.",
              bottomWidget: Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: InkWell(
                    onTap: () async {
                      await UserController.refreshCurrentUser(userState);
                      Navigator.pushReplacement(navigatorKey.currentContext,
                          MaterialPageRoute(builder: (context) => UserPage()));
                    },
                    child:
                    Text("GO TO MY ACCOUNT", style: TextPalette.linkStyle)),
              )).show(context);
        },
        Secondary(),
      );
}
