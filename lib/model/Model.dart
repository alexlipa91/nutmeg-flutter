import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../utils/Utils.dart';

enum MatchStatus { open, played, canceled }

enum SportCenterTags { indoor, outdoor }

enum Sport { fiveAsideFootball }

enum SubscriptionStatus { going, canceled }

extension SportExtension on Sport {
  String getDisplayTitle() {
    switch (this) {
      case Sport.fiveAsideFootball:
        return "5-aside-football";
      default:
        return "";
    }
  }
}

class Match {
  static var serializationDateFormat = new DateFormat("yyyy/MM/dd:HH:mm");
  static var uiDateFormat = new DateFormat("yyyy-MM-dd");
  static var uiHourFormat = new DateFormat("HH:mm");

  String documentId;

  DateTime dateTime;
  String sportCenter;
  Sport sport;
  double pricePerPerson;
  int maxPlayers;
  MatchStatus status;

  List<Subscription> subscriptions;

  Match(this.dateTime, this.sportCenter, this.sport, this.maxPlayers,
      this.pricePerPerson, this.status);

  Match.fromJson(Map<String, dynamic> json, String documentId)
      : dateTime = serializationDateFormat.parse(json['dateTime']),
        sportCenter = json['sportCenter'],
        sport = Sport.values[json['sport']],
        pricePerPerson = json['pricePerPerson'],
        maxPlayers = json['maxPlayers'],
        status = MatchStatus.values[json['status']],
        documentId = documentId;

  Map<String, dynamic> toJson() => {
        'dateTime': serializationDateFormat.format(dateTime),
        'sportCenter': sportCenter,
        'sport': sport.index,
        'pricePerPerson': pricePerPerson,
        'maxPlayers': maxPlayers,
        'status': status.index,
      };

  String getFormattedDate() {
    return (isSameDay(DateTime.now(), dateTime)
            ? "Today"
            : uiDateFormat.format(dateTime)) +
        " at " +
        uiHourFormat.format(dateTime);
  }

  int getSpotsLeft() => maxPlayers - numPlayersGoing();

  int numPlayersGoing() =>
      subscriptions.where((s) => s.status == SubscriptionStatus.going).length;

  bool isUserGoing(UserDetails user) => subscriptions
      .where((s) =>
          s.status == SubscriptionStatus.going && s.userId == user.getUid())
      .isNotEmpty;
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
  String neighbourhood;
  String address;
  List<String> tags;

  SportCenter.fromJson(Map<String, dynamic> json, String documentId)
      : placeId = documentId,
        name = json['name'],
        neighbourhood = json['neighbourhood'],
        address = json['address'],
        tags = List<String>.from(json['tags']);

  String getName() => name;

  bool operator ==(dynamic other) =>
      other != null && other is SportCenter && this.placeId == other.placeId;

  @override
  int get hashCode => super.hashCode;
}

class UserDetails {
  User firebaseUser;

  bool isAdmin;
  String image;
  String name;

  UserDetails(this.firebaseUser, this.isAdmin, this.image, this.name);

  UserDetails.fromJson(Map<String, dynamic> json, User firebaseUser)
      : isAdmin = json["isAdmin"] ?? false,
        image = json["image"],
        name = json["name"],
        firebaseUser = firebaseUser;

  Map<String, dynamic> toJson() =>
      {'isAdmin': isAdmin, 'image': image, 'name': name};

  String getUid() => firebaseUser.uid;
}
