import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:provider/provider.dart';

import '../state/UserState.dart';
import 'Avatar.dart';


class NutmegAppBar extends StatelessWidget {
  final Color backgroundColor;
  final Widget mainRow;
  final SystemUiOverlayStyle systemUiOverlayStyle;

  const NutmegAppBar(
      {Key? key,
      required this.backgroundColor,
      required this.mainRow,
      required this.systemUiOverlayStyle})
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
}

class MainAppBar extends StatelessWidget {
  final Color color;
  static const buildTimestamp = String.fromEnvironment("BUILD_TIMESTAMP");

  MainAppBar(this.color) : super();

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
                onTap: () => context.go("/"),
                child: Image.asset('assets/nutmeg_white.png', height: 24)),
            if (buildTimestamp.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(buildTimestamp,
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            if (isLoggedIn)
              Builder(
                  builder: (context) =>
                      LoggedUserAvatarWithRedirectUserPage(radius: 2))
            else
              InkWell(
                onTap: () async {
                  context.go("/login");
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
