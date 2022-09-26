import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:skeletons/skeletons.dart';

class SportCenter {
  String placeId;
  String address;
  String name;
  double lat;
  double lng;

  String surface;
  bool? hasChangingRooms;
  String courtType;

  SportCenter(this.placeId, this.address, this.name, this.lat, this.lng,
      this.surface, this.hasChangingRooms, this.courtType);

  SportCenter.fromJson(Map<String, dynamic>? json, String documentId)
      : placeId = documentId,
        name = json!['name'],
        address = json['address'],
        lat = json['lat'],
        lng = json['lng'],
        surface = json["surface"],
        hasChangingRooms = json['hasChangingRooms'],
        courtType = json['courtType']!;

  Map<String, dynamic> toJson() => {
        'address': address,
        'placeId': placeId,
        'name': name,
        'lat': lat,
        'lng': lng,
        'surface': surface,
        if (hasChangingRooms != null)
          'hasChangingRooms': hasChangingRooms!,
        'courtType': courtType
      };

  Widget getThumbnail() {
    var surf = surface.toLowerCase() == "indoor" ? "indoor" : "grass";
    return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: Image.asset("assets/sportcenters/${surf}_thumb.png").image,
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.all(Radius.circular(10)),
        )
    );
  }

  List<Widget> getCarouselImages() {
    var surf = surface.toLowerCase() == "indoor" ? "indoor" : "grass";
    return [
      Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: Image.asset("assets/sportcenters/${surf}_carousel.png").image,
              fit: BoxFit.fill,
            ),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          )
      )];
  }

  String getName() => name;

  String getCourtType() => courtType;

  String getSurface() => surface;

  bool? getHasChangingRooms() => hasChangingRooms;
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
      other != null &&
      other is SavedSportCenter &&
      this.placeId == other.placeId;

  @override
  int get hashCode => super.hashCode;

  List<String> getImagesUrls() => _imagesUrls.isEmpty
      ? [
          "https://storage.googleapis.com/nutmeg-9099c.appspot.com/sportcenters/default/large/1.png"
        ]
      : _imagesUrls;

  // images are 60x78
  @override
  Widget getThumbnail() {
    return CachedNetworkImage(
      imageUrl: _thumbnailUrl == null
          ? "https://storage.googleapis.com/nutmeg-9099c.appspot.com/sportcenters/default/thumbnail.png"
          : _thumbnailUrl!,
      fadeInDuration: Duration(milliseconds: 0),
      imageBuilder: (context, imageProvider) => Container(
          decoration: BoxDecoration(
        image: DecorationImage(
          image: imageProvider,
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      )),
      // placeholder: (context, url) => placeHolder,
      errorWidget: (context, url, error) => Icon(Icons.error),
    );
  }

  @override
  List<Widget> getCarouselImages() => _imagesUrls
      .map((i) => CachedNetworkImage(
            imageUrl: i,
            fadeInDuration: Duration(milliseconds: 0),
            fadeOutDuration: Duration(milliseconds: 0),
            imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.fill,
              ),
            )),
            placeholder: (context, imageProvider) => SkeletonAvatar(
              style: SkeletonAvatarStyle(
                  width: double.infinity,
                  height: 213,
                  borderRadius: BorderRadius.circular(10.0)),
            ),
            errorWidget: (context, url, error) => Icon(Icons.error),
          ))
      .toList();

  String getShortAddress() => address.split(",").first;

  String getSurface() => surface;
}
