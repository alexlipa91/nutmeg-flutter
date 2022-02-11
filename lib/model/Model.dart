import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


enum SubscriptionStatus { going, refunded, canceled }

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
  String stripePriceId;

  List<Subscription> going;
  List<Subscription> refunded;

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
      stripePriceId = jsonInput['stripePriceId'],
      going = List<Subscription>.from(jsonInput["going"]
          .values.map((m) => Subscription.fromJson(m))),
      isTest = jsonInput["isTest"] ?? false,
      documentId = documentId;

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
        'stripePriceId': stripePriceId,
        'isTest': isTest
      };

  int getSpotsLeft() => maxPlayers - numPlayersGoing();

  int numPlayersGoing() => going.length;

  bool isFull() => numPlayersGoing() == maxPlayers;

  bool isUserGoing(UserDetails user) =>
      going.where((e) => e.userId == user.documentId).isNotEmpty;

  double getPrice() => pricePerPersonInCents / 100;

  bool wasCancelled() => cancelledAt != null;
}

class Subscription {
  String userId;
  String stripeSessionId;
  DateTime createdAt;

  Subscription.fromJson(Map<String, dynamic> json)
      : userId = json['userId'],
        createdAt = DateTime.parse(json['createdAt']).toLocal(),
        stripeSessionId = json["stripeSessionId"];

  Map<String, dynamic> toJson() =>
      {
        'userId': userId,
        'stripeSessionId': stripeSessionId,
        'createdAt': createdAt
      };
}

class SportCenter {
  String placeId;

  String name;
  double lat;
  double lng;
  String neighbourhood;
  String address;
  List<String> tags;

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
  List<String> tokens;

  UserDetails(this.documentId, this.isAdmin, this.image, this.name, this.email)
      : creditsInCents = 0,
        tokens = [];

  UserDetails.from(String documentId, UserDetails u)
      : this.documentId = documentId,
        this.isAdmin = u.isAdmin,
        this.image = u.image,
        this.name = u.name,
        this.email = u.email,
        this.stripeId = u.stripeId,
        this.creditsInCents = u.creditsInCents,
        this.tokens = u.tokens;

  UserDetails.fromJson(Map<String, dynamic> json, String documentId)
      : isAdmin = (json["isAdmin"] == null) ? false : json["isAdmin"],
        image = json["image"],
        name = json["name"],
        email = json["email"],
        creditsInCents = json["credits"],
        stripeId = json["stripeId"] ?? null,
        tokens = (json["tokens"] == null) ? [] : List<String>.from(json["tokens"]),
        documentId = documentId;

  Map<String, dynamic> toJson() =>
      {
        'isAdmin': isAdmin,
        'image': image,
        'name': name,
        'email': email,
        'credits': creditsInCents,
        'tokens': tokens
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
