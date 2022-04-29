class SportCenter {
  String placeId;

  String name;
  double lat;
  double lng;
  String neighbourhood;
  String address;
  Map<String, dynamic> _info;

  String _thumbnailUrl;
  List<String> _imagesUrls;

  SportCenter.fromJson(Map<String, dynamic> json, String documentId)
      : placeId = documentId,
        name = json['name'],
        neighbourhood = json['neighbourhood'],
        address = json['address'],
        lat = json['lat'],
        lng = json['lng'],
        _info = Map<String, dynamic>.from(json["info"] ?? {}),
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

  bool hasChangingRooms() => _info["changeRooms"];

  String getCourtType() => _info["courtType"];

  bool isIndoor() => _info["indoor"];

  String getSurface() => _info["surface"];
}

