import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


enum MatchStatus { open, played, canceled }

enum SportCenterTags { indoor, outdoor }

enum Sport { fiveAsideFootball }

enum SubscriptionStatus { going, canceled }

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
  static var serializationDateFormat = new DateFormat("yyyy/MM/dd:HH:mm");
  static var uiDateFormat = new DateFormat("E, MMM dd");
  static var uiHourFormat = new DateFormat("HH:mm");

  String documentId;

  DateTime dateTime;
  String sportCenter;
  Sport sport;
  int pricePerPersonInCents;
  int maxPlayers;
  MatchStatus status;

  List<Subscription> subscriptions;

  Match(this.dateTime, this.sportCenter, this.sport, this.maxPlayers,
      this.pricePerPersonInCents, this.status);

  Match.fromJson(Map<String, dynamic> json, String documentId)
      : dateTime = (json['dateTime'] as Timestamp).toDate(),
        sportCenter = json['sportCenter'],
        sport = Sport.values[json['sport']],
        pricePerPersonInCents = json['pricePerPerson'],
        maxPlayers = json['maxPlayers'],
        status = MatchStatus.values[json['status']],
        documentId = documentId;

  Map<String, dynamic> toJson() => {
        'dateTime': Timestamp.fromDate(dateTime),
        'sportCenter': sportCenter,
        'sport': sport.index,
        'pricePerPerson': pricePerPersonInCents,
        'maxPlayers': maxPlayers,
        'status': status.index,
      };

  String getFormattedDate() {
    var diff = dateTime.difference(DateTime.now());

    var dayString;

    if (diff.inDays == 0) {
      dayString = "Today";
    } else if (diff.inDays == 1) {
      dayString = "Tomorrow";
    } else {
      dayString = uiDateFormat.format(dateTime);
    }

    return dayString + " at " + uiHourFormat.format(dateTime);
  }

  int getSpotsLeft() => maxPlayers - numPlayersGoing();

  int numPlayersGoing() =>
      subscriptions.where((s) => s.status == SubscriptionStatus.going).length;

  bool isUserGoing(UserDetails user) => subscriptions
      .where((s) =>
          s.status == SubscriptionStatus.going && s.userId == user.getUid())
      .isNotEmpty;

  double getPrice() => pricePerPersonInCents / 100;
}

class Subscription {
  String documentId;

  String userId;
  SubscriptionStatus status;

  Subscription(this.userId, this.status);

  Subscription.fromJson(Map<String, dynamic> json, String documentId)
      : documentId = documentId,
        userId = json['userId'],
        status = SubscriptionStatus.values[json['status']];

  Map<String, dynamic> toJson() => {'userId': userId, 'status': status.index};
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

  String getShortAddress() => address.split(",").first;

  List<String> getMainPicturesListUrls() => ["assets/sportcentertest_large.png",
    "assets/sportcentertest_large.png",
    "assets/sportcentertest_large.png"
  ];
}

class UserDetails {
  User firebaseUser;

  bool isAdmin;
  String image;
  String name;
  String stripeId;

  UserDetails(this.firebaseUser, this.isAdmin, this.image, this.name);

  UserDetails.fromJson(Map<String, dynamic> json, User firebaseUser)
      : isAdmin = json["isAdmin"] ?? false,
        image = json["image"],
        name = json["name"],
        stripeId = json["stripeId"] ?? null,
        firebaseUser = firebaseUser;

  Map<String, dynamic> toJson() =>
      {'isAdmin': isAdmin, 'image': image, 'name': name};

  String getUid() => firebaseUser.uid;

  String getStripeId() => stripeId;

  void setStripeId(String stripeId) => stripeId = stripeId;

  String getPhotoUrl() => firebaseUser.photoURL ?? image;
}
