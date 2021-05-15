import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nutmeg/Authentication.dart';
import 'package:nutmeg/screens/Login.dart';
import 'package:provider/provider.dart';

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}

var appTheme = new ThemeData(
  primaryColor: Colors.black,
  accentColor: Colors.blueAccent,
  textTheme: TextTheme(
      headline1: TextStyle(
          color: Colors.black, fontWeight: FontWeight.w700, fontSize: 28),
      headline2: TextStyle(
          color: Colors.black, fontWeight: FontWeight.w500, fontSize: 18),
      headline3: TextStyle(
          color: Colors.purple, fontWeight: FontWeight.w700, fontSize: 25),
      bodyText1: TextStyle(
          color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
      bodyText2: TextStyle(
          color: Colors.black, fontSize: 12, fontWeight: FontWeight.w500)),
  fontFamily: "Montserrat",
);

getAppBar(BuildContext context) {

  getTopBottomWidget(BuildContext context) {
    return Consumer<UserModel>(
      builder: (context, user, child) {
        if (user.name != null) {
          print("User is " + user.name);
          // fixme this doesn't really pad well
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 1.0),
            child: RawMaterialButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (_) => new AlertDialog(
                      content: new Text("Here go to user page"),
                    ));
              },
              elevation: 2.0,
              fillColor: Colors.purple,
              child: Text(user.name[0].toUpperCase(),
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500)),
              padding: EdgeInsets.all(15.0),
              shape: CircleBorder(),
            ),
          );
        }

        return InkWell(
            onTap: () =>
                Navigator.push(context, MaterialPageRoute(builder: (context) => Login())),
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: Text("Login",
                  style: Theme.of(context).textTheme.headline3
                // style: new TextStyle(color: Colors.purple, fontSize: 25.0)
              ),
            )
        );
      }
    );
  }

  return AppBar(
    title: Text("Nutmeg", style: Theme
        .of(context)
        .textTheme
        .headline1),
    backgroundColor: Colors.grey.shade400,
    actions: [
      getTopBottomWidget(context)
    ],
    elevation: 0,
  );
}