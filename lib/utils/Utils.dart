import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';


bool isSameDay(DateTime a, DateTime b) {
  return a.day == b.day && a.month == b.month && a.year == b.year;
}

var uiHourFormat = new DateFormat("HH:mm");

String getFormattedDate(DateTime dateTime) => _getFormattedDate(dateTime, DateFormat("E, MMM dd"));

String getFormattedDateLong(DateTime dateTime) => _getFormattedDate(dateTime, DateFormat("EEEE, MMM dd"));

String _getFormattedDate(DateTime dateTime, DateFormat dateFormat) {
  var now = DateTime.now();

  var dayString;

  if (now.day == dateTime.day && now.month == dateTime.month && now.year == dateTime.year) {
    dayString = "Today";
  } else if (now.day + 1 == dateTime.day && now.month == dateTime.month && now.year == dateTime.year) {
    dayString = "Tomorrow";
  } else if (now.day - 1 == dateTime.day && now.month == dateTime.month && now.year == dateTime.year) {
    dayString = "Yesterday";
  } else {
    dayString = dateFormat.format(dateTime);
  }

  return dayString + " at " + uiHourFormat.format(dateTime);
}

List<String> getStartAndEndHour(DateTime dateTime, Duration duration) => [
  uiHourFormat.format(dateTime), uiHourFormat.format(dateTime.add(duration))
];


class DynamicLinks {
  static shareMatchFunction(String matchId) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://nutmegapp.page.link',

      link: Uri.parse('https://nutmegapp.com/match?id=' + matchId),
      androidParameters: AndroidParameters(
        packageName: 'com.nutmeg.nutmeg',
        minimumVersion: 0,
      ),
      iosParameters: IosParameters(
        bundleId: 'com.nutmeg.app',
        minimumVersion: '1',
        appStoreId: '1592985083',
      ),
    );
    var long = await parameters.buildUrl();
    var url = await parameters.buildShortLink();

    print(long);
    print(url.shortUrl);
    // fixme this doesn't wait
    await Share.share("Wanna join this match on Nutmeg?\n" + url.shortUrl.toString());
  }
}

var isTestPaymentMode = false;