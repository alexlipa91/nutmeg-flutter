import 'package:tuple/tuple.dart';

import 'UserDetails.dart';


class Match {
  String documentId;

  DateTime dateTime;

  String sportCenterId;
  String sportCenterSubLocation;

  String sport;
  int pricePerPersonInCents;
  int maxPlayers;
  Duration duration;
  DateTime cancelledAt;
  DateTime scoresComputedAt;

  Map<String, DateTime> going;

  String manOfTheMatch;
  double manOfTheMatchScore;

  bool isTest;

  Match(this.dateTime, this.sportCenterId, this.sportCenterSubLocation, this.sport,
      this.maxPlayers, this.pricePerPersonInCents, this.duration, this.isTest);

  Match.fromJson(Map<String, dynamic> jsonInput, String documentId) {
      dateTime = DateTime.parse(jsonInput['dateTime']).toLocal();
      sportCenterId = jsonInput['sportCenterId'];
      sportCenterSubLocation = jsonInput['sportCenterSubLocation'];
      sport = jsonInput['sport'];
      pricePerPersonInCents = jsonInput['pricePerPerson'];
      maxPlayers = jsonInput['maxPlayers'];
      duration = Duration(minutes: jsonInput['duration'] ?? 60);

      if (jsonInput.containsKey("cancelledAt") && jsonInput["cancelledAt"] != null)
        cancelledAt = DateTime.parse(jsonInput['cancelledAt']).toLocal();
      if (jsonInput.containsKey("scoresComputedAt") && jsonInput["scoresComputedAt"] != null)
        scoresComputedAt = DateTime.parse(jsonInput['scoresComputedAt']).toLocal();

      isTest = jsonInput["isTest"] ?? false;
      going = _readGoing(jsonInput);

      var t = _readManOfTheMatch(jsonInput);
      if (t != null) {
        manOfTheMatch = t.item1;
        manOfTheMatchScore = t.item2;
      }

      this.documentId = documentId;
  }

  static Map<String, DateTime> _readGoing(Map<String, dynamic> json) {
    var map = Map<String, dynamic>.from(json["going"] ?? {});
    var x = map.map((key, value) => MapEntry(key, DateTime.parse(value["createdAt"])));
    return x;
  }

  static Tuple2<String, double> _readManOfTheMatch(Map<String, dynamic> json) {
    var map = Map<String, dynamic>.from(json["manOfTheMatch"] ?? {});
    if (map.isEmpty) {
      return null;
    }
    return map.entries.map((e) => Tuple2<String, double>(e.key, e.value)).first;
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

