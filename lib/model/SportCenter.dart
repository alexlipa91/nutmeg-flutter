import 'package:tuple/tuple.dart';

import 'UserDetails.dart';


class SportCenter {
  String placeId;

  String name;
  double lat;
  double lng;
  String neighbourhood;
  String address;
  List<String> tags;

  String thumbnailUrl;
  List<String> imagesUrls;

  SportCenter.fromJson(Map<String, dynamic> json, String documentId)
      : placeId = documentId,
        name = json['name'],
        neighbourhood = json['neighbourhood'],
        address = json['address'],
        lat = json['lat'],
        lng = json['lng'],
        tags = List<String>.from(json['tags']);

  String getName() => name;

  bool operator ==(dynamic other) =>
      other != null && other is SportCenter && this.placeId == other.placeId;

  @override
  int get hashCode => super.hashCode;

  String getShortAddress() =>
      address
          .split(",")
          .first;
}

