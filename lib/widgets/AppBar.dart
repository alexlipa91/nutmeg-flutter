import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:nutmeg/screens/Login.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:provider/provider.dart';

import '../state/UserState.dart';
import 'Avatar.dart';


class NutmegAppBar extends StatelessWidget with PreferredSizeWidget {
  final Color backgroundColor;
  final Widget mainRow;
  final SystemUiOverlayStyle systemUiOverlayStyle;

  const NutmegAppBar(
      {Key key, this.backgroundColor, this.mainRow, this.systemUiOverlayStyle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
        systemOverlayStyle: systemUiOverlayStyle,
        centerTitle: false,
        backgroundColor: backgroundColor,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        elevation: 0,
        title: mainRow);
  }

  @override
  Size get preferredSize => Size.fromHeight(50.0);
}

class MainAppBar extends NutmegAppBar {
  final color;

  MainAppBar(this.color);

  @override
  Widget build(BuildContext context) {
    var isLoggedIn = context.watch<UserState>().isLoggedIn();

    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle.light,
      centerTitle: false,
      backgroundColor: color,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      elevation: 0,
      title: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () => Get.toNamed("/home"),
                child: Image.asset('assets/nutmeg_white.png', height: 24)),
            if (isLoggedIn)
              Builder(
                  builder: (context) =>
                      LoggedUserAvatarWithRedirectUserPage(radius: 2))
            else
              InkWell(
                onTap: () async {
                  var communication = await Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Login()));
                  if (communication != null) {
                    GenericInfoModal(
                            title: "Welcome", description: communication.text)
                        .show(context);
                  }
                },
                child: Container(
                  height: 50,
                  child: Center(
                      child:
                          Text("LOGIN", style: TextPalette.linkStyleInverted)),
                ),
              )
          ],
        ),
      ),
    );
  }
}
