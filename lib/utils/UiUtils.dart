import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


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

class UiUtils {

  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

class Palette {
  static var primary = UiUtils.fromHex("#394BBB");

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
