import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';

import '../state/UserState.dart';


class LogOutButton extends StatelessWidget {

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
            Get.back(result: false);
            return;
          }

          await Future.delayed(Duration(milliseconds: 500));
          Navigator.of(context).pop(true);
        },
        Primary(),
      );
}
