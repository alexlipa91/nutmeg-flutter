import 'dart:ui';

import 'package:flutter/material.dart';

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
          color: Colors.purple, fontWeight: FontWeight.w700, fontSize: 18),
      bodyText1: TextStyle(
          color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
      bodyText2: TextStyle(
          color: Colors.black, fontSize: 12, fontWeight: FontWeight.w500)),
  fontFamily: "Montserrat",
);