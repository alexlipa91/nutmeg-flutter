import 'package:flutter/material.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';

import '../state/UserState.dart';


class LogOutButton extends StatelessWidget {

  final Match match;

  const LogOutButton({Key key, this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      GenericButtonWithLoader(
        "LOGOUT",
        (BuildContext context) async {
          context.read<GenericButtonWithLoaderState>().change(true);

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
        },
        Primary(),
      );
}
