import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

var formatCurrency = NumberFormat.simpleCurrency(name: "EUR");

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

  String sportCenter;
  String sportCenterSubLocation;

  String sport;
  int pricePerPersonInCents;
  int maxPlayers;
  Duration duration;
  Timestamp cancelledAt;
  String stripePriceId;

  List<Subscription> going;
  List<Subscription> cancelled;

  Match(this.dateTime, this.sportCenter, this.sportCenterSubLocation, this.sport,
      this.maxPlayers, this.pricePerPersonInCents, this.duration, this.cancelledAt);

  Match.fromJson(Map<String, dynamic> json, String documentId)
      : dateTime = (json['dateTime'] as Timestamp).toDate(),
        sportCenter = json['sportCenter'],
        sportCenterSubLocation = json['sportCenterSubLocation'],
        sport = json['sport'],
        pricePerPersonInCents = json['pricePerPerson'],
        maxPlayers = json['maxPlayers'],
        duration = Duration(minutes: json['durationInMinutes'] ?? 60),
        cancelledAt = json['cancelledAt'],
        stripePriceId = json['stripePriceId'],
        documentId = documentId;

  Map<String, dynamic> toJson() =>
      {
        'dateTime': Timestamp.fromDate(dateTime),
        'sportCenter': sportCenter,
        'sportCenterSubLocation': sportCenterSubLocation,
        'sport': sport,
        'pricePerPerson': pricePerPersonInCents,
        'maxPlayers': maxPlayers,
        'cancelledAt': cancelledAt,
        'stripePriceId': stripePriceId
      };

  int getSpotsLeft() => maxPlayers - numPlayersGoing();

  int numPlayersGoing() => going.length;

  bool isFull() => numPlayersGoing() == maxPlayers;

  bool isUserGoing(UserDetails user) =>
      going.where((e) => e.userId == user.documentId).isNotEmpty;

  double getPrice() => pricePerPersonInCents / 100;

  String getFormattedPrice() => formatCurrency.format(getPrice());

  bool wasCancelled() => cancelledAt != null;
}

class Subscription {
  String userId;
  String stripeSessionId;
  Timestamp createdAt;

  Subscription.fromJson(Map<String, dynamic> json, String documentId)
      : userId = json['userId'],
        createdAt = json['createdAt'],
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
      : isAdmin = json["isAdmin"] ?? false,
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

  String getCreditsAvailable() => formatCurrency.format(creditsInCents / 100);
}

class Coupon {
  String id;

  String description;
  int percentage;

  Coupon.fromJson(Map<String, dynamic> json, String id)
      : id = id,
        description = json["description"],
        percentage = json["percentage"];

  Map<String, dynamic> toJson() =>
      {'percentage': percentage, 'description': description};
}

class PaymentRecap {

  PaymentRecap(this.matchPriceInCents, this.creditsInCentsUsed);

  int matchPriceInCents;
  int creditsInCentsUsed;

  finalPriceToPayInCents() => matchPriceInCents - creditsInCentsUsed;

  onlyCreditsUsed() => matchPriceInCents == creditsInCentsUsed;
}
