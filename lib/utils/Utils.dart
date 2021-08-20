import 'package:dio/dio.dart';
import 'package:location/location.dart';

bool isSameDay(DateTime a, DateTime b) {
  return a.day == b.day && a.month == b.month && a.year == b.year;
}
