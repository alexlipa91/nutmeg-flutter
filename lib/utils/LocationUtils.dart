import 'package:dio/dio.dart';
import 'package:location/location.dart';

class LocationUtils {

  static Location location = new Location();

  static Future<String> getDistanceInKm(double lat, double long, String placeId) async {
    // fixme store somewhere
    var directionsApiKey = "AIzaSyDlU4z5DbXqoafB-T-t2mJ8rGv3Y4rAcWY";

    var url =
        "https://maps.googleapis.com/maps/api/distancematrix/json?units=metric&origins=" +
            lat.toString() +
            "," +
            long.toString() +
            "&destinations=place_id:" +
            placeId +
            "&key=" +
            directionsApiKey;

    try {
      final result = await Dio().get(url);
      var kmDistance =
          result.data["rows"][0]["elements"][0]["distance"]["text"];
      print(kmDistance);
      return kmDistance;
    } on DioError catch (e, s) {
      print(e.response);
      throw e;
    }
  }

  // fixme this is a bit slow
  static Future<LocationData> getCurrentLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return null;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    return await location.getLocation();
  }
}
