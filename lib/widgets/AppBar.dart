import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/screens/Login.dart';
import 'package:nutmeg/screens/UserPage.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

class NutmegAppBar extends StatelessWidget with PreferredSizeWidget {
  final Color backgroundColor;
  final Widget mainRow;

  const NutmegAppBar({Key key, this.backgroundColor, this.mainRow})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
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
      backgroundColor: Palette.primary,
      mainRow: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset('assets/nutmeg_white.png', height: 24),
            if (isLoggedIn)
              UserAvatar()
            else
              Center(
                  child: InkWell(
                      child:
                          Text("LOGIN", style: TextPalette.linkStyleInverted),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (context) => Login()))))
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
      backgroundColor: Colors.transparent,
      mainRow: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
                child: Icon(Icons.arrow_back, color: Colors.black),
                onTap: () => Navigator.of(context).pop()),
            InkWell(
                child: Icon(Icons.share, color: Colors.black),
                onTap: () async => await DynamicLinks.shareMatchFunction(matchId))
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

class UserAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var userDetails = context.watch<UserState>().getUserDetails();
    return InkWell(
        child: CircleAvatar(
            backgroundImage: NetworkImage(userDetails.getPhotoUrl()),
            radius: 25),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => new UserPage())));
  }
}

class AdminAreaAppBar extends NutmegAppBar {
  @override
  Widget build(BuildContext context) {
    return NutmegAppBar(
        backgroundColor: Palette.primary,
        mainRow: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                  child: Icon(Icons.arrow_back, color: Palette.white),
                  onTap: () => Navigator.pop(context)),
              UserAvatar()
            ],
          ),
        ));
  }
}

class AdminAreaAppBarInverted extends NutmegAppBar {
  @override
  Widget build(BuildContext context) {
    return NutmegAppBar(
        backgroundColor: Palette.light,
        mainRow: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                  child: Icon(Icons.arrow_back, color: Palette.primary),
                  onTap: () => Navigator.pop(context)),
              UserAvatar()
            ],
          ),
        ));
  }
}
