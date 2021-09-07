import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:intl/intl.dart';
import 'package:share/share.dart';

bool isSameDay(DateTime a, DateTime b) {
  return a.day == b.day && a.month == b.month && a.year == b.year;
}

var uiHourFormat = new DateFormat("HH:mm");

String getFormattedDate(DateTime dateTime) => _getFormattedDate(dateTime, DateFormat("E, MMM dd"));

String getFormattedDateLong(DateTime dateTime) => _getFormattedDate(dateTime, DateFormat("EEEE, MMM dd"));

String _getFormattedDate(DateTime dateTime, DateFormat dateFormat) {
  var now = DateTime.now();

  var dayString;

  if (now.day == dateTime.day) {
    dayString = "Today";
  } else if (now.day == dateTime.day - 1) {
    dayString = "Tomorrow";
  } else if (now.day == dateTime.day + 1) {
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
        bundleId: 'your_ios_bundle_identifier',
        minimumVersion: '1',
        appStoreId: 'your_app_store_id',
      ),
    );
    var url = await parameters.buildShortLink();

    print(url.shortUrl);
    Share.share("Wanna join this match on Nutmeg?\n" + url.shortUrl.toString());
  }
}
