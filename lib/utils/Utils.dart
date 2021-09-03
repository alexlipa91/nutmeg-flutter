import 'package:intl/intl.dart';

bool isSameDay(DateTime a, DateTime b) {
  return a.day == b.day && a.month == b.month && a.year == b.year;
}

var uiDateFormat = new DateFormat("E, MMM dd");
var uiHourFormat = new DateFormat("HH:mm");

String getFormattedDate(DateTime dateTime) {
  var diff = dateTime.difference(DateTime.now());

  var dayString;

  if (diff.inDays == 0) {
    dayString = "Today";
  } else if (diff.inDays == 1) {
    dayString = "Tomorrow";
  } else if (diff.inDays == -1) {
    dayString = "Yesterday";
  } else {
    dayString = uiDateFormat.format(dateTime);
  }

  return dayString + " at " + uiHourFormat.format(dateTime);
}