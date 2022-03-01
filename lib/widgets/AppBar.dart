import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutmeg/screens/Login.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Buttons.dart';
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
  @override
  Widget build(BuildContext context) {
    var isLoggedIn = context.watch<UserState>().isLoggedIn();

    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle.light,
      centerTitle: false,
      backgroundColor: Palette.primary,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      elevation: 0,
      title: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset('assets/nutmeg_white.png', height: 24),
            if (isLoggedIn)
              Builder(builder: (context) => CurrentUserAvatarWithRedirect(radius: 18))
            else
              InkWell(
                onTap: () async {
                  var communication = await Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Login()));
                  if (communication != null) {
                    GenericInfoModal(title: "Welcome", description: communication.text)
                        .show(context);
                  }
                },
                child: Container(
                  height: 40,
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

class MatchAppBar extends StatelessWidget {
  final String matchId;

  const MatchAppBar({Key key, this.matchId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      backgroundColor: Colors.transparent,
      centerTitle: false,
      leadingWidth: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // SizedBox(width: 16,), // we cannot pad outside
          InkWell(
              splashColor: Palette.lighterGrey,
              child: Container(
                width: 40,
                height: 40,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(Icons.arrow_back,
                      color: Colors.black, size: 25.0),
                ),
              ),
              onTap: () => Navigator.of(context).pop()
          ),
          if (!DeviceInfo().name.contains("ipad"))
            Align(alignment: Alignment.centerRight,
                child: ShareButton(matchId, Palette.black, 25.0)),
        ],
      ),
    );
  }

}

class UserPageAppBar extends NutmegAppBar {
  @override
  Widget build(BuildContext context) {
    return NutmegAppBar(
      systemUiOverlayStyle: SystemUiOverlayStyle.dark,
      backgroundColor: Colors.transparent,
      mainRow: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Icon(Icons.arrow_back, color: Colors.black)),
              onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

class AdminAreaAppBar extends NutmegAppBar {
  @override
  Widget build(BuildContext context) {
    return NutmegAppBar(
        backgroundColor: Colors.green,
        mainRow: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                  child: Icon(Icons.arrow_back, color: Palette.white, size: 32),
                  onTap: () => Navigator.pop(context)),
              CurrentUserAvatarWithRedirect(radius: 18)
            ],
          ),
        ));
  }
}

class AdminAreaAppBarInverted extends NutmegAppBar {
  @override
  Widget build(BuildContext context) {
    return NutmegAppBar(
        systemUiOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Palette.light,
        mainRow: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                  child:
                      Icon(Icons.arrow_back, color: Palette.primary, size: 32),
                  onTap: () => Navigator.pop(context)),
              UserAvatar(24, context.watch<UserState>().getLoggedUserDetails())
            ],
          ),
        ));
  }
}
