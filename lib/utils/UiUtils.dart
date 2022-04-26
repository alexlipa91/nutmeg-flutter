import 'dart:io';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


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
  // black and white
  static const white = Colors.white;
  static var black = UiUtils.fromHex("#1E1E24");

  // greys
  static var grey_lightest = UiUtils.fromHex("#F7F7F7"); // previous “light”
  static var grey_lighter = UiUtils.fromHex("#EEEEEE"); // previous “lighterGrey”
  static var grey_light = UiUtils.fromHex("#C2C2C2"); // previous “lightGrey”
  static var grey_dark = UiUtils.fromHex("#787878"); // previous “mediumgrey”
  static var grey_darker = UiUtils.fromHex("#4444444"); // previous “darkgrey”

  // colors
  static var primary = UiUtils.fromHex("#394BBB");
  static var destructive = UiUtils.fromHex("#E34D4F");
  static var green = Colors.green.shade700;
  static var accent = UiUtils.fromHex("#FD9F41");
  static var warning = UiUtils.fromHex("#FFEDAF");
  static var darkWarning = UiUtils.fromHex("#B88014");
}

class TextPalette {

  static TextStyle h1Default = GoogleFonts.roboto(color: Palette.black, fontSize: 30, fontWeight: FontWeight.w900);
  static TextStyle h1Inverted = GoogleFonts.roboto(color: Palette.white, fontSize: 30, fontWeight: FontWeight.w900);

  static TextStyle getH2(Color color) => GoogleFonts.roboto(color: color, fontSize: 18, fontWeight: FontWeight.w700);
  static TextStyle h2 = GoogleFonts.roboto(color: Palette.black, fontSize: 18, fontWeight: FontWeight.w700);

  static TextStyle getH3(Color color) => GoogleFonts.roboto(color: color, fontSize: 14, fontWeight: FontWeight.w500);
  static TextStyle h3 = getH3(Palette.black);

  static TextStyle h3WithBar = GoogleFonts.roboto(color: Palette.black, fontSize: 14, fontWeight: FontWeight.w500, decoration: TextDecoration.lineThrough);

  static TextStyle h4 = GoogleFonts.roboto(color: Palette.black, fontSize: 12, fontWeight: FontWeight.w500);

  static TextStyle getBodyText(Color color) => GoogleFonts.roboto(color: color, fontSize: 14, fontWeight: FontWeight.w400, height: 1.6);
  static TextStyle bodyText = GoogleFonts.roboto(color: Palette.grey_dark, fontSize: 14, fontWeight: FontWeight.w400, height: 1.6);
  static TextStyle bodyTextPrimary = GoogleFonts.roboto(color: Palette.primary, fontSize: 14, fontWeight: FontWeight.w400, height: 1.6);

  static TextStyle bodyTextOneLine = GoogleFonts.roboto(color: Palette.grey_dark, fontSize: 14, fontWeight: FontWeight.w400);
  static TextStyle bodyTextInverted = GoogleFonts.roboto(color: Palette.white, fontSize: 14, fontWeight: FontWeight.w400, height: 1.6);

  static TextStyle linkStyle = GoogleFonts.roboto(color: Palette.primary, fontSize: 14, fontWeight: FontWeight.w700);
  static TextStyle linkStyleInverted = GoogleFonts.roboto(color: Palette.white, fontSize: 14, fontWeight: FontWeight.w700);

  static TextStyle getLinkStyle(Color color) => GoogleFonts.roboto(color: color, fontSize: 14, fontWeight: FontWeight.w700);

  static TextStyle buttonOff = GoogleFonts.roboto(color: Palette.grey_lighter, fontSize: 14, fontWeight: FontWeight.w700);
  static TextStyle getStats(Color color) => GoogleFonts.roboto(color: color, fontSize: 30, fontWeight: FontWeight.w400);
}

class DeviceInfo {
  static final DeviceInfo _singleton = DeviceInfo._internal();

  String name;

  factory DeviceInfo() {
    return _singleton;
  }

  DeviceInfo._internal();

  Future<void> init() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      name = (await deviceInfo.iosInfo).model.toLowerCase();
    } else if (Platform.isAndroid) {
      name = (await deviceInfo.androidInfo).model.toLowerCase();
    }
    print("device name is " + name);
  }
}
