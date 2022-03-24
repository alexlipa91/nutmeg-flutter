class SportCenter {
  String placeId;

  String name;
  double lat;
  double lng;
  String neighbourhood;
  String address;
  List<String> tags;

  String _thumbnailUrl;
  List<String> _imagesUrls;

  SportCenter.fromJson(Map<String, dynamic> json, String documentId)
      : placeId = documentId,
        name = json['name'],
        neighbourhood = json['neighbourhood'],
        address = json['address'],
        lat = json['lat'],
        lng = json['lng'],
        tags = List<String>.from(json['tags']),
        _thumbnailUrl = json['thumbnailUrl'],
        _imagesUrls = List<String>.from(json["largeImageUrls"] ?? []);

  String getName() => name;

  bool operator ==(dynamic other) =>
      other != null && other is SportCenter && this.placeId == other.placeId;

  @override
  int get hashCode => super.hashCode;

  String getThumbnailUrl() => _thumbnailUrl == null
      ? "https://storage.googleapis.com/nutmeg-9099c.appspot.com/sportcenters/default/thumbnail.png" : _thumbnailUrl;

  List<String> getImagesUrls() => _imagesUrls.isEmpty ? ["https://storage.googleapis.com/nutmeg-9099c.appspot.com/sportcenters/default/large/1.png"] : _imagesUrls;

  String getShortAddress() =>
      address
          .split(",")
          .first;
}

