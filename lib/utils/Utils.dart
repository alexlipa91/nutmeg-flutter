import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tuple/tuple.dart';
import 'package:version/version.dart';

var uiHourFormat = new DateFormat("HH:mm");

String getFormattedDate(DateTime dateTime) =>
    _getFormattedDate(dateTime, DateFormat("E, MMM dd"));

String getFormattedDateLong(DateTime dateTime) =>
    _getFormattedDate(dateTime, DateFormat("EEEE, MMM dd"));

String getFormattedDateLongWithHour(DateTime dateTime) =>
    _getFormattedDate(dateTime, DateFormat("EEEE, MMM dd"), true);

String _getFormattedDate(DateTime dateTime, DateFormat dateFormat,
    [bool showHours = false]) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  final tomorrow = DateTime(now.year, now.month, now.day + 1);

  var dayString;

  final aDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
  if (aDate == today) {
    dayString = "Today";
  } else if (aDate == yesterday) {
    dayString = "Yesterday";
  } else if (aDate == tomorrow) {
    dayString = "Tomorrow";
  } else {
    dayString = dateFormat.format(dateTime);
  }

  if (!showHours)
    return dayString;
  return dayString + " at " + uiHourFormat.format(dateTime);
}

String formatCurrency(int cents) =>
    NumberFormat.simpleCurrency(name: "EUR").format(cents / 100);

String formatEmail(String? email) {
  if (email == null)
    return "N/A";
  var parts = email.split("@");
  if (parts.length > 1 && parts[1] == "privaterelay.appleid.com")
    return "N/A";
  return email;
}

List<String> getStartAndEndHour(DateTime dateTime, Duration duration) => [
      uiHourFormat.format(dateTime),
      uiHourFormat.format(dateTime.add(duration))
    ];

class DynamicLinks {
  static shareMatchFunction(String matchId) async {
    var deepLinkUrl = Uri.parse('https://web.nutmegapp.com/match/' + matchId);

    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://nutmegapp.page.link',
      link: deepLinkUrl,
      androidParameters: AndroidParameters(
        packageName: 'com.nutmeg.nutmeg',
        minimumVersion: 0,
        fallbackUrl: deepLinkUrl
      ),
      iosParameters: IosParameters(
        bundleId: 'com.nutmeg.app',
        minimumVersion: '1',
        appStoreId: '1592985083',
        fallbackUrl: deepLinkUrl
      ),
    );
    var url = await parameters.buildShortLink();

    // fixme this doesn't wait
    await Share.share(
        "Checkout this match on Nutmeg!\n" + url.shortUrl.toString());
  }
}

DateTime getBeginningOfTheWeek(DateTime dateTime) {
  var currentDay = dateTime.weekday;
  return DateUtils.dateOnly(dateTime.subtract(Duration(days: currentDay - 1)));
}

List<T> interleave<T>(List<T> elements, T e, [bool withTop=false]) {
  List<T> result = [];
  if (withTop)
    result.add(e);
  elements.forEach((a) {
    result.add(a);
    result.add(e);
  });

  if (result.isNotEmpty) result.removeLast();

  return result;
}

Future<Tuple2<Version, String>> getVersion() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  var versionParts = packageInfo.version.split(".");
  return Tuple2<Version, String>(
      Version(int.parse(versionParts[0]), int.parse(versionParts[1]),
          int.parse(versionParts[2])),
      packageInfo.buildNumber);
}

class ConfigsUtils {

  static bool removeCreditsFunctionality() =>
      true;
      // FirebaseRemoteConfig.instance.getBool("remove_credit_functionality");
}