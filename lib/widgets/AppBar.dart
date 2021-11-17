import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/screens/Login.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Buttons.dart';
import 'package:provider/provider.dart';

import 'Avatar.dart';

class NutmegAppBar extends StatelessWidget with PreferredSizeWidget {
  final Color backgroundColor;
  final Widget mainRow;
  final SystemUiOverlayStyle systemUiOverlayStyle;

  const NutmegAppBar({Key key, this.backgroundColor, this.mainRow, this.systemUiOverlayStyle})
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
  Size get preferredSize => Size.fromHeight(70.0);
}

class MainAppBar extends NutmegAppBar {
  @override
  Widget build(BuildContext context) {
    var isLoggedIn = context.watch<UserState>().isLoggedIn();

    return NutmegAppBar(
      systemUiOverlayStyle: SystemUiOverlayStyle.light,
      backgroundColor: Palette.primary,
      mainRow: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset('assets/nutmeg_white.png', height: 24),
            if (isLoggedIn)
              UserAvatarWithRedirect(radius: 18)
            else
              Center(
                  child: InkWell(
                      child:
                          Text("LOGIN", style: TextPalette.linkStyleInverted),
                      onTap: () async {
                        var communication = await Navigator.push(context,
                            MaterialPageRoute(builder: (context) => Login()));
                        if (communication != null) {
                          GenericInfoModal(
                                  title: "Welcome", body: communication.text)
                              .show(context);
                        }
                      }))
          ],
        ),
      ),
    );
  }
}

class MatchAppBar extends NutmegAppBar {
  final String matchId;

  MatchAppBar(this.matchId);

  @override
  Widget build(BuildContext context) {
    return NutmegAppBar(
      systemUiOverlayStyle: SystemUiOverlayStyle.dark,
      backgroundColor: Colors.transparent,
      mainRow: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
                child: Icon(Icons.arrow_back, color: Colors.black),
                onTap: () => Navigator.of(context).pop()),
            if (!DeviceInfo().name.contains("ipad"))
              ShareButton(matchId: matchId)
          ],
        ),
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
              UserAvatarWithRedirect(radius: 18)
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
              UserAvatar()
            ],
          ),
        ));
  }
}
