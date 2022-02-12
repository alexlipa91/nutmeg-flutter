import 'package:flutter/material.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:provider/provider.dart';


class LogOutButton extends StatelessWidget {

  final Match match;

  const LogOutButton({Key key, this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      GenericStatefulButton(
        text: "LOGOUT",
        onPressed: (BuildContext context) async {
          context.read<GenericButtonState>().change(ButtonState.loading);

          try {
            await Future.delayed(Duration(milliseconds: 500),
                    () => UserController.logout(context.read<UserState>()));
            Navigator.of(context).pop();
          } catch (e, stackTrace) {
            print(e);
            print(stackTrace);
            Navigator.pop(context, false);
            return;
          }

          await Future.delayed(Duration(milliseconds: 500));
          Navigator.of(context).pop(true);
        }
      );
}
