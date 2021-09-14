import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

var formatCurrency = NumberFormat.simpleCurrency(name: "EUR");

enum SportCenterTags { indoor, outdoor }

enum Sport { fiveAsideFootball }

enum SubscriptionStatus { going, refunded, canceled }

extension SportExtension on Sport {
  String getDisplayTitle() {
    switch (this) {
      case Sport.fiveAsideFootball:
        return "5v5";
      default:
        return "";
    }
  }
}

class Match {
  String documentId;

  DateTime dateTime;
  String sportCenter;
  Sport sport;
  int pricePerPersonInCents;
  int maxPlayers;
  Duration duration;
  Timestamp cancelledAt;

  List<Subscription> subscriptions;

  Match(this.dateTime, this.sportCenter, this.sport, this.maxPlayers,
      this.pricePerPersonInCents, this.duration, this.cancelledAt);

  Match.from(Match m) {
    documentId = m.documentId;
    dateTime = m.dateTime;
    sportCenter = m.sportCenter;
    sport = m.sport;
    pricePerPersonInCents = m.pricePerPersonInCents;
    maxPlayers = m.maxPlayers;
    subscriptions = m.subscriptions;
    duration = m.duration;
    cancelledAt = m.cancelledAt;
  }

  Match.fromJson(Map<String, dynamic> json, String documentId)
      : dateTime = (json['dateTime'] as Timestamp).toDate(),
        sportCenter = json['sportCenter'],
        sport = Sport.values[json['sport']],
        pricePerPersonInCents = json['pricePerPerson'],
        maxPlayers = json['maxPlayers'],
        duration = Duration(minutes: json['durationInMinutes'] ?? 60),
        cancelledAt = json['cancelledAt'],
        documentId = documentId;

  Map<String, dynamic> toJson() =>
      {
        'dateTime': Timestamp.fromDate(dateTime),
        'sportCenter': sportCenter,
        'sport': sport.index,
        'pricePerPerson': pricePerPersonInCents,
        'maxPlayers': maxPlayers,
        'cancelledAt': cancelledAt
      };

  int getSpotsLeft() => maxPlayers - numPlayersGoing();

  int numPlayersGoing() =>
      subscriptions
          .where((s) => s.status == SubscriptionStatus.going)
          .length;

  bool isFull() => numPlayersGoing() == maxPlayers;

  Subscription getUserSub(UserDetails user) {
    var userSubFilter = subscriptions.where((s) => s.userId == user.getUid());
    if (userSubFilter.isEmpty) {
      return null;
    }
    return userSubFilter.first;
  }

  List<Subscription> getOrderedGoingSubscriptions(UserDetails userDetails) {
    // if user is in match place him on top of list
    var orderedSubscriptions = subscriptions.where((e) =>
    e.status == SubscriptionStatus.going).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (userDetails != null) {
      var userIndex = orderedSubscriptions.indexWhere((e) =>
      e.userId == userDetails.getUid());
      if (userIndex != -1) {
        orderedSubscriptions.insert(
            0, orderedSubscriptions.removeAt(userIndex));
      }
    }
    return orderedSubscriptions;
  }

  double getPrice() => pricePerPersonInCents / 100;

  String getFormattedPrice() => formatCurrency.format(getPrice());

  bool wasCancelled() => cancelledAt != null;
}

class Subscription {
  String documentId;

  String userId;
  SubscriptionStatus status;
  Timestamp createdAt;
  int paid;
  int paidInCredits;
  int refundedInCredits;

  Subscription(this.userId, this.status, this.paid, this.paidInCredits,
      this.refundedInCredits)
      : createdAt = Timestamp.now();

  Subscription.fromJson(Map<String, dynamic> json, String documentId)
      : documentId = documentId,
        userId = json['userId'],
        paid = json['paid'],
        paidInCredits = json['paidInCredits'],
        refundedInCredits = json['refundedInCredits'],
        createdAt = json['createdAt'] ?? null,
        status = SubscriptionStatus.values
            .firstWhere((e) =>
        e
            .toString()
            .split(".")
            .last == json['status']);

  Map<String, dynamic> toJson() =>
      {
        'userId': userId,
        'status': status
            .toString()
            .split(".")
            .last,
        'createdAt': createdAt,
        'paid': paid,
        'paidInCredits': paidInCredits,
        'refundedInCredits': refundedInCredits,
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
  int matchPriceInCents;
  int creditsInCentsUsed;

  finalPriceToPayInCents() => matchPriceInCents - creditsInCentsUsed;

  onlyCreditsUsed() => matchPriceInCents == creditsInCentsUsed;
}
