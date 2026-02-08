class LocationInfo {
  // these are city coordinates:
  double lat;
  double lng;
  String country;
  String city;

  LocationInfo(this.country, this.city, this.lat, this.lng);

  LocationInfo.fromJson(Map<String, dynamic> json)
      : country = json["country"],
        city = json["city"],
        lat = json["lat"],
        lng = json["lng"];

  Map<String, dynamic> toJson() =>
      {"country": country, "city": city, "lat": lat, "lng": lng};

  String getText() => "$city, $country";
}
