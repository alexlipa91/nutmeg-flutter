class SportCenter {
  String placeId;
  String address;
  String name;
  double lat;
  double lng;
  Map<String, dynamic> _info;

  String getName() => name;

  String getThumbnailUrl() =>
      "https://storage.googleapis.com/nutmeg-9099c.appspot.com/sportcenters/default/thumbnail.png";

  List<String> getImagesUrls() => [
    "https://storage.googleapis.com/nutmeg-9099c.appspot.com/sportcenters/default/large/1.png"
  ];

  bool hasChangingRooms() => _info["changeRooms"] ?? false;

  String? getCourtType() => _info["courtType"];

  String? getSurface() => _info["surface"];

  SportCenter(this.address, this.name, this.placeId, this.lat, this.lng, this._info);

  SportCenter.fromJson(Map<String, dynamic>? json, String documentId):
        address = json!['address'],
        name = json['name'],
        placeId = documentId,
        lat = json['lat'],
        lng = json['lng'],
        _info = Map<String, dynamic>.from(json["info"] ?? {});

  Map<String, dynamic> toJson() =>
      {
        'address': address,
        'placeId': placeId,
        'name': name,
        'info': _info,
        'lat': lat,
        'lng': lng
      };
}

class SavedSportCenter extends SportCenter {
  String? neighbourhood;
  String? cid;

  String? _thumbnailUrl;
  List<String> _imagesUrls;

  SavedSportCenter.fromJson(Map<String, dynamic>? json, String documentId)
      : neighbourhood = json!['neighbourhood'],
        cid = json['cid'],
        _thumbnailUrl = json['thumbnailUrl'],
        _imagesUrls = List<String>.from(json["largeImageUrls"] ?? []),
        super.fromJson(json, documentId);

  bool operator ==(dynamic other) =>
      other != null && other is SavedSportCenter && this.placeId == other.placeId;

  @override
  int get hashCode => super.hashCode;

  // images are 60x78
  @override
  String getThumbnailUrl() => _thumbnailUrl == null
      ? "https://storage.googleapis.com/nutmeg-9099c.appspot.com/sportcenters/default/thumbnail.png" : _thumbnailUrl!;

  // images are 670x358
  @override
  List<String> getImagesUrls() => _imagesUrls.isEmpty ? ["https://storage.googleapis.com/nutmeg-9099c.appspot.com/sportcenters/default/large/1.png"] : _imagesUrls;

  String getShortAddress() =>
      address
          .split(",")
          .first;
}