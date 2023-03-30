import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:skeletons/skeletons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


enum Surface {indoor, grass}

class SportCenter {
  String placeId;
  String address;
  String name;
  double lat;
  double lng;

  Surface _surface;
  bool? hasChangingRooms;
  String courtType;
  String timezoneId;
  String country;

  SportCenter.fromJson(Map<String, dynamic>? json, String documentId)
      : placeId = documentId,
        name = json!['name'],
        address = json['address'],
        lat = json['lat'],
        lng = json['lng'],
        country = json['country'] ?? 'NL',
        _surface = Surface.values.where((e) => e.name == json["surface"].toString().toLowerCase()).first,
        hasChangingRooms = json['hasChangingRooms'],
        timezoneId = json["timeZoneId"] ?? "Europe/Amsterdam",
        courtType = json['courtType']!;

  Map<String, dynamic> toJson() => {
        'address': address,
        'placeId': placeId,
        'name': name,
        'lat': lat,
        'lng': lng,
        'surface': _surface.name,
        'country': country,
        'timeZoneId': timezoneId,
        if (hasChangingRooms != null)
          'hasChangingRooms': hasChangingRooms!,
        'courtType': courtType
      };

  Widget getThumbnail() {
    return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: Image.asset("assets/sportcenters/${_surface.name}_thumb.png").image,
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.all(Radius.circular(10)),
        )
    );
  }

  List<Widget> getCarouselImages() {
    return [
      Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: Image.asset("assets/sportcenters/${_surface.name}_carousel.png").image,
              fit: BoxFit.fill,
            ),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          )
      )];
  }

  String getName() => name;

  String getCourtType() => courtType;

  bool? getHasChangingRooms() => hasChangingRooms;

  String? getSurface(BuildContext context) {
    Map<Surface, String> surfacesDescription = {
      Surface.grass: AppLocalizations.of(context)!.artificialGrass,
      Surface.indoor: "Indoor"
    };

    return surfacesDescription[_surface];
  }
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

  String getTimezoneId() => "Europe/Amsterdam";
}
