import 'package:cloud_firestore/cloud_firestore.dart';


class Sport {
  String documentId;

  String displayTitle;

  Sport(this.displayTitle);

  Sport.fromJson(Map<String, dynamic> json, String documentId)
      : displayTitle = json["displayTitle"],
        documentId = documentId;
}

class Match {
  String documentId;

  DateTime dateTime;

  String sportCenterId;
  String sportCenterSubLocation;

  String sport;
  int pricePerPersonInCents;
  int maxPlayers;
  Duration duration;
  Timestamp cancelledAt;

  Map<String, DateTime> going;

  bool isTest;

  Match(this.dateTime, this.sportCenterId, this.sportCenterSubLocation, this.sport,
      this.maxPlayers, this.pricePerPersonInCents, this.duration, this.isTest);

  Match.fromJson(Map<String, dynamic> jsonInput, String documentId):
      dateTime = DateTime.parse(jsonInput['dateTime']).toLocal(),
      sportCenterId = jsonInput['sportCenterId'],
      sportCenterSubLocation = jsonInput['sportCenterSubLocation'],
      sport = jsonInput['sport'],
      pricePerPersonInCents = jsonInput['pricePerPerson'],
      maxPlayers = jsonInput['maxPlayers'],
      duration = Duration(minutes: jsonInput['duration'] ?? 60),
      cancelledAt = jsonInput['cancelledAt'],
      isTest = jsonInput["isTest"] ?? false,
      going = _readGoing(jsonInput),
      documentId = documentId;

  static Map<String, DateTime> _readGoing(Map<String, dynamic> json) {
    var map = Map<String, dynamic>.from(json["going"] ?? {});
    var x = map.map((key, value) => MapEntry(key, DateTime.parse(value["createdAt"])));
    return x;
  }

  Map<String, dynamic> toJson() =>
      {
        'dateTime': dateTime.toUtc().toIso8601String(),
        'sportCenterId': sportCenterId,
        'sportCenterSubLocation': sportCenterSubLocation,
        'sport': sport,
        'pricePerPerson': pricePerPersonInCents,
        'maxPlayers': maxPlayers,
        'cancelledAt': cancelledAt,
        'duration': duration.inMinutes,
        'isTest': isTest
      };

  int getSpotsLeft() => maxPlayers - numPlayersGoing();

  int numPlayersGoing() => going.length;

  bool isFull() => numPlayersGoing() == maxPlayers;

  bool isUserGoing(UserDetails user) => going.containsKey(user.documentId);

  double getPrice() => pricePerPersonInCents / 100;

  bool wasCancelled() => cancelledAt != null;

  List<String> getGoingUsersByTime() {
    var entries = going.entries.toList()..sort((e1,e2) => -e1.value.compareTo(e2.value));
    return entries.map((e) => e.key).toList();
  }
}

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

class UserDetails {
  String documentId;

  bool isAdmin;
  String image;
  String name;
  String email;
  String stripeId;
  int creditsInCents;

  UserDetails(this.documentId, this.isAdmin, this.image, this.name, this.email)
      : creditsInCents = 0;

  UserDetails.from(String documentId, UserDetails u)
      : this.documentId = documentId,
        this.isAdmin = u.isAdmin,
        this.image = u.image,
        this.name = u.name,
        this.email = u.email,
        this.stripeId = u.stripeId,
        this.creditsInCents = u.creditsInCents;

  UserDetails.fromJson(Map<String, dynamic> json, String documentId)
      : isAdmin = (json["isAdmin"] == null) ? false : json["isAdmin"],
        image = json["image"],
        name = json["name"],
        email = json["email"],
        creditsInCents = json["credits"],
        stripeId = json["stripeId"] ?? null,
        documentId = documentId;

  Map<String, dynamic> toJson() =>
      {
        'isAdmin': isAdmin,
        'image': image,
        'name': name,
        'email': email,
        'credits': creditsInCents,
      };

  String getUid() => documentId;

  String getStripeId() => stripeId;

  void setStripeId(String stripeId) => stripeId = stripeId;

  String getPhotoUrl() => image;
}

class PaymentRecap {

  PaymentRecap(this.matchPriceInCents, this.creditsInCentsUsed);

  int matchPriceInCents;
  int creditsInCentsUsed;

  finalPriceToPayInCents() => matchPriceInCents - creditsInCentsUsed;

  onlyCreditsUsed() => matchPriceInCents == creditsInCentsUsed;
}
