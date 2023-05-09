import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tuple/tuple.dart';
import 'package:version/version.dart';
import 'package:timezone/timezone.dart' as tz;


String gmtSuffix(String timeZoneId) {
  var hourOffset = tz.TZDateTime.from(DateTime.now(),
      tz.getLocation(timeZoneId)).timeZoneOffset.inHours;
  var gmtString = ((hourOffset > 0) ? "+" : "") + hourOffset.toString();
  return "GMT$gmtString";
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

class DynamicLinks {
  static var dayDateFormat = DateFormat("EEEE, MMM dd");

  static shareMatchFunction(BuildContext context, Match match) async {
    String link;
    if (match.dynamicLink != null)
      link = match.dynamicLink!;
    else {
      // todo slowly deprecate
      var deepLinkUrl = Uri.parse('https://web.nutmegapp.com/match/' + match.documentId);

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
            title: "Match on ${dayDateFormat
                .format(match.getLocalizedTime(match.sportCenter.timezoneId))} "
                "${gmtSuffix(match.sportCenter.timezoneId)}",
            description: "Location: ${match.sportCenter.name}",
          )
      );
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

  static bool feesOnOrganiser(String orgId) => false;
}

String getStripeUrl(bool isTest, String userId) =>
    CloudFunctionsClient().getUrl("stripe/account/onboard?is_test=$isTest");
