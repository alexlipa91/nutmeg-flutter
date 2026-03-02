import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/config/app_config.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:nutmeg/utils/navigate_url.dart';
import 'package:timezone/timezone.dart' as tz;

import '../state/UserState.dart';
import 'share_utils.dart';

String gmtSuffix(String? timeZoneId) {
  var tzLocation = timeZoneId == null ? tz.local : tz.getLocation(timeZoneId);
  var hourOffset =
      tz.TZDateTime.from(DateTime.now(), tzLocation).timeZoneOffset.inHours;
  var gmtString = ((hourOffset > 0) ? "+" : "") + hourOffset.toString();
  return "GMT$gmtString";
}

String formatCurrency(int cents) =>
    NumberFormat.simpleCurrency(name: "EUR").format(cents / 100);

String formatEmail(String? email) {
  if (email == null) return "N/A";
  var parts = email.split("@");
  if (parts.length > 1 && parts[1] == "privaterelay.appleid.com") return "N/A";
  return email;
}

class DynamicLinks {
  static Future<void> shareMatchFunction(BuildContext context, Match match) async {
    final link = "https://app.nutmegplay.com/match/${match.documentId}";
    await shareWithOrigin(context, text: "Checkout this match on Nutmeg!\n$link");
  }
}

DateTime getBeginningOfTheWeek(DateTime dateTime) {
  var currentDay = dateTime.weekday;
  return DateUtils.dateOnly(dateTime.subtract(Duration(days: currentDay - 1)));
}

List<T> interleave<T>(List<T> elements, T e, [bool withTop = false]) {
  List<T> result = [];
  if (withTop) result.add(e);
  elements.forEach((a) {
    result.add(a);
    result.add(e);
  });

  if (result.isNotEmpty) result.removeLast();

  return result;
}

Future<String> getVersion() async {
  if (AppConfig.commitTimestampEpoch.isNotEmpty) {
    return AppConfig.commitTimestampEpoch;
  }
  if (kIsWeb) {
    return AppConfig.commitSha;
  }
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version + " + " + packageInfo.buildNumber;
}

String getStripeUrl(bool isTest, String userId, String? matchId) {
  final baseUri = Uri.base;
  final hasHttpOrigin = baseUri.scheme == "http" || baseUri.scheme == "https";
  final redirectBase =
      hasHttpOrigin ? baseUri.origin : "https://app.nutmegplay.com";
  var redirectUrl = Uri.encodeComponent(redirectBase);
  var path =
      "stripe/account/onboard?is_test=$isTest&user_id=$userId&redirect_url=$redirectUrl";
  if (matchId != null) {
    path = path + "&match_id=$matchId";
  }
  return CloudFunctionsClient().getUrl(path);
}

Future<void> completeAccountAction(BuildContext context, bool isTest,
        {String? matchId}) =>
    navigateToUrl(getStripeUrl(isTest,
        context.read<UserState>().getLoggedUserDetails()!.documentId, matchId));
