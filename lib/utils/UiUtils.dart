import 'dart:ui';

import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


var topBoxDecoration = BoxDecoration(
    color: Palette.primary,
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
  //for CTAs, links, buttons
  static var primary = UiUtils.fromHex("#394BBB");

  //delete, remove, etc
  static var destructive = UiUtils.fromHex("#E34D4F");

  //for background
  static var light = UiUtils.fromHex("#F3F5FA");

  //text
  static var mediumgrey = UiUtils.fromHex("#787878");
  static var darkgrey = UiUtils.fromHex("#444444");
  static var black = UiUtils.fromHex("#1E1E24");

  static var lightGrey = Colors.grey.shade200; // used for background
  static var green = Colors.green.shade700;

  static var white = Colors.white;
}

class TextPalette {

  static TextStyle h1Default = GoogleFonts.roboto(color: Palette.black, fontSize: 30, fontWeight: FontWeight.w900);
  static TextStyle h1Inverted = GoogleFonts.roboto(color: Palette.white, fontSize: 30, fontWeight: FontWeight.w900);

  static TextStyle h2 = GoogleFonts.roboto(color: Palette.black, fontSize: 18, fontWeight: FontWeight.w700);

  static TextStyle h3 = GoogleFonts.roboto(color: Palette.black, fontSize: 14, fontWeight: FontWeight.w500);
  static TextStyle h3WithBar = GoogleFonts.roboto(color: Palette.black, fontSize: 14, fontWeight: FontWeight.w500, decoration: TextDecoration.lineThrough);

  static TextStyle h4 = GoogleFonts.roboto(color: Palette.darkgrey, fontSize: 12, fontWeight: FontWeight.w500);

  static TextStyle bodyText = GoogleFonts.roboto(color: Palette.mediumgrey, fontSize: 14, fontWeight: FontWeight.w400, height: 1.6);
  static TextStyle bodyTextOneLine = GoogleFonts.roboto(color: Palette.mediumgrey, fontSize: 14, fontWeight: FontWeight.w400);
  static TextStyle bodyTextInverted = GoogleFonts.roboto(color: Palette.white, fontSize: 14, fontWeight: FontWeight.w400, height: 1.6);

  static TextStyle linkStyle = GoogleFonts.roboto(color: Palette.primary, fontSize: 14, fontWeight: FontWeight.w700);
  static TextStyle linkStyleInverted = GoogleFonts.roboto(color: Palette.white, fontSize: 14, fontWeight: FontWeight.w700);
}

// ignore for now
var appTheme = new ThemeData(
    primaryColor: Palette.primary,
    accentColor: Palette.light
);

var defaultErrorMessage = (err, context) =>
    CoolAlert.show(context: context, type: CoolAlertType.error, text: err.toString());