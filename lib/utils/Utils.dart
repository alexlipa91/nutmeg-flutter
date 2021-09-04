import 'package:intl/intl.dart';

bool isSameDay(DateTime a, DateTime b) {
  return a.day == b.day && a.month == b.month && a.year == b.year;
}

var uiDateFormat = new DateFormat("E, MMM dd");
var uiHourFormat = new DateFormat("HH:mm");

String getFormattedDate(DateTime dateTime) {
  var now = DateTime.now();

  var dayString;

  if (now.day == dateTime.day) {
    dayString = "Today";
  } else if (now.day == dateTime.day - 1) {
    dayString = "Tomorrow";
  } else if (now.day == dateTime.day + 1) {
    dayString = "Yesterday";
  } else {
    dayString = uiDateFormat.format(dateTime);
  }

  return dayString + " at " + uiHourFormat.format(dateTime);
}