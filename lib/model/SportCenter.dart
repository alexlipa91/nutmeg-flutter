import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:skeletons/skeletons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


enum Surface {indoor, grass}

extension SurfaceExstension on Surface {

  String getTitle(BuildContext context) {
    switch (this) {
      case Surface.indoor: return AppLocalizations.of(context)!.indoorTitle;
      default: return AppLocalizations.of(context)!.grassTitle;
    }
  }

  String getDbName() {
    switch (this) {
      case Surface.indoor: return "indoor";
      default: return "grass";
    }
  }

  String getDescription(BuildContext context) {
    switch (this) {
      case Surface.indoor: return AppLocalizations.of(context)!.indoorDesc;
      default: return AppLocalizations.of(context)!.grassDesc;
    }
  }

  String getImagePath() {
    switch (this) {
      case Surface.indoor: return "assets/sportcenters/indoor_thumb.png";
      default: return "assets/sportcenters/grass_thumb.png";
    }
  }
}

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

  String? _thumbnailUrl;
  List<String>? _imagesUrls;

  bool? isSaved;

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
        courtType = json['courtType']!,
        _thumbnailUrl = json['thumbnailUrl'],
        _imagesUrls = json["largeImageUrls"] == null
            ? null : List<String>.from(json["largeImageUrls"]!);

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
        'courtType': courtType,
        if (_thumbnailUrl != null)
          'thumbnailUrl': _thumbnailUrl!,
        if (_imagesUrls != null)
          "largeImageUrls": _imagesUrls
      };

  Widget getThumbnail() {
    if (_thumbnailUrl != null)
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
    if (_imagesUrls != null) {
      return _imagesUrls!
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
    }

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

  String getShortAddress() => address.split(",").first;

  String getTimezoneId() => "Europe/Amsterdam";
}
