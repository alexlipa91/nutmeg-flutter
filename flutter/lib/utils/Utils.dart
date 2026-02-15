import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tuple/tuple.dart';
import 'package:nutmeg/utils/navigate_url.dart';
import 'package:version/version.dart';
import 'package:timezone/timezone.dart' as tz;

import '../state/UserState.dart';

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
  static var dayDateFormat = DateFormat("EEEE, MMM dd");

  static shareMatchFunction(BuildContext context, Match match) async {
    String link;
    if (match.dynamicLink != null)
      link = match.dynamicLink!;
    else {
      // todo slowly deprecate
      var deepLinkUrl =
          Uri.parse('https://web.nutmegapp.com/match/' + match.documentId);

      final DynamicLinkParameters parameters = DynamicLinkParameters(
          uriPrefix: 'https://nutmegapp.page.link',
          link: deepLinkUrl,
          androidParameters: AndroidParameters(
            packageName: 'com.nutmeg.nutmeg',
            minimumVersion: 0,
            // fallbackUrl: deepLinkUrl
          ),
          iosParameters: IOSParameters(
            bundleId: 'com.nutmeg.app',
            minimumVersion: '1',
            appStoreId: '1592985083',
            // fallbackUrl: deepLinkUrl
          ),
          socialMetaTagParameters: SocialMetaTagParameters(
            title: "Match on ${dayDateFormat.format(match.getLocalizedTime())} "
                "${gmtSuffix(match.sportCenter?.timezoneId)}",
            description: "Location: ${match.sportCenter?.name}",
          ));
      var url = await FirebaseDynamicLinks.instance.buildShortLink(parameters);
      link = url.shortUrl.toString();
    }

    // fixme this doesn't wait
    await Share.share("Checkout this match on Nutmeg!\n" + link);
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

const String COMMIT_SHA =
    String.fromEnvironment("COMMIT_SHA", defaultValue: "");

const String COMMIT_TIMESTAMP =
    String.fromEnvironment("COMMIT_TIMESTAMP", defaultValue: "");

Future<String> getVersion() async {
  if (COMMIT_TIMESTAMP.isNotEmpty) {
    return COMMIT_TIMESTAMP;
  }
  if (kIsWeb) {
    return COMMIT_SHA;
  }
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version + " + " + packageInfo.buildNumber;
}

class ConfigsUtils {
  static bool removeCreditsFunctionality() => true;

  // FirebaseRemoteConfig.instance.getBool("remove_credit_functionality");
  static bool feesOnOrganiser(String orgId) => false;

  static bool allowUsersToMarkPayments() =>
      FirebaseRemoteConfig.instance.getBool("allow_users_to_mark_payments");

  static bool allowNutmegManagedPayments() => true;
}

String getStripeUrl(bool isTest, String userId, String? matchId) {
  var redirectUrl = Uri.encodeComponent(Uri.base.origin);
  var path = "stripe/account/onboard?is_test=$isTest&user_id=$userId&redirect_url=$redirectUrl";
  if (matchId != null) {
    path = path + "&match_id=$matchId";
  }
  return CloudFunctionsClient().getUrl(path);
}

Future<void> completeAccountAction(BuildContext context, bool isTest,
        {String? matchId}) =>
    navigateToUrl(getStripeUrl(
        isTest,
        context.read<UserState>().getLoggedUserDetails()!.documentId,
        matchId));
