import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutmeg/screens/Login.dart';
import 'package:nutmeg/screens/UserPage.dart';
import 'package:provider/provider.dart';

import 'models/UserModel.dart';

var topBoxDecoration = BoxDecoration(
    color: Colors.green.shade700,
    borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)));

var infoMatchDecoration = BoxDecoration(
  border: Border.all(color: Colors.transparent),
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(20)),
  boxShadow: [
    BoxShadow(
      color: Colors.grey.withOpacity(0.5),
      spreadRadius: 5,
      blurRadius: 7,
      offset: Offset(0, 3), // changes position of shadow
    ),
  ],
);

class Palette {
  static var green = Colors.green.shade700;
  static var white = Colors.white;
  static var lightGrey = Colors.grey.shade200;
}

var appTheme = new ThemeData(
    primaryColor: Colors.green.shade700,
    accentColor: Colors.white,
    textTheme: GoogleFonts.latoTextTheme(
      TextTheme(
          headline1: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 28),
          headline2: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w500, fontSize: 18),
          headline3: TextStyle(
              color: Colors.purple, fontWeight: FontWeight.w700, fontSize: 25),
          bodyText1: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
          bodyText2: TextStyle(
              color: Colors.black, fontSize: 12, fontWeight: FontWeight.w500)),
    ));

getAppBar(BuildContext context) {
  getTopBottomWidget(BuildContext context) {
    return Consumer<UserModel>(builder: (context, user, child) {
      var widget;
      var function;
      var backgroundImage;
      if (user.isLoggedIn()) {
        print("Building app bar: detected user is " + user.user.uid);
        // fixme this doesn't really pad well
        function = () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => new UserPage()));
        };
        backgroundImage =
            NetworkImage(context.read<UserModel>().userDetails.image);
      } else {
        function = () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => Login()));
        widget = Icon(Icons.login, color: Colors.green);
      }

      return InkWell(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
              child: widget,
              backgroundImage: backgroundImage,
              radius: 25,
              backgroundColor: Palette.white),
        ),
        onTap: function,
      );
    });
  }

  return AppBar(
    toolbarHeight: 70,
    title: Text("Nutmeg",
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.w500, fontSize: 26)),
    leading: Icon(
      Icons.menu,
      color: Colors.white,
    ),
    actions: [getTopBottomWidget(context)],
    elevation: 0,
  );
}

bool isSameDay(DateTime a, DateTime b) {
  return a.day == b.day && a.month == b.month && a.year == b.year;
}
