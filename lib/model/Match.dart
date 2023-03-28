import 'dart:math';

import 'package:nutmeg/model/SportCenter.dart';
import 'package:timezone/timezone.dart' as tz;

import 'UserDetails.dart';


enum MatchStatus {
  open,                // match is on and can be joined
  pre_playing,         // match is on and from now on no-one can leave
  playing,             // mach is being played
  to_rate,             // match is in the past and within rating window
  rated,               // match is in the past and after rating window (man of the match is available)
  cancelled,           // match is canceled
  unpublished          // match is created but not joinable by others
}

class Match {
  late String documentId;

  MatchStatus? status;

  DateTime dateTime;

  String? sportCenterId;
  SportCenter? sportCenter;

  Duration duration;
  String? sportCenterSubLocation;

  int pricePerPersonInCents;
  int minPlayers;
  int maxPlayers;
  DateTime? cancelledAt;
  DateTime? scoresComputedAt;
  DateTime? paidOutAt;

  Map<String, DateTime> going;

  Map<String, List<String>> teams;

  Map<String, double>? _manOfTheMatch;

  String? organizerId;
  Duration? cancelBefore;

  int userFee;
  int organiserFee;

  bool managePayments;

  List<int>? score;

  bool isTest;

  Match(this.dateTime, this.sportCenterId, this.sportCenter, this.sportCenterSubLocation,
      this.maxPlayers, this.pricePerPersonInCents, this.duration,
      this.isTest, this.minPlayers, this.organizerId, this.userFee,
      this.organiserFee, this.going, this.teams, this.cancelBefore,
      this.managePayments, this.score);

  Match.fromJson(Map<String, dynamic> jsonInput, String documentId) :
        dateTime = DateTime.parse(jsonInput['dateTime']),
        duration = Duration(minutes: jsonInput['duration'] ?? 60),
        isTest = jsonInput["isTest"] ?? false,
        minPlayers = jsonInput['minPlayers'] ?? 0,
        maxPlayers = jsonInput['maxPlayers'],
        going = _readGoing(jsonInput),
        teams = _readTeams(jsonInput),
        pricePerPersonInCents = jsonInput['pricePerPerson'],
        _manOfTheMatch = _readManOfTheMatch(jsonInput),
        sportCenterId = jsonInput['sportCenterId'],
        userFee = jsonInput["userFee"] ?? 0,
        organiserFee = jsonInput["organiserFee"] ?? 0,
        score = jsonInput["score"],
        managePayments = jsonInput["managePayments"] ?? true {
      sportCenterSubLocation = jsonInput['sportCenterSubLocation'];

      if (jsonInput.containsKey("cancelledAt") && jsonInput["cancelledAt"] != null)
        cancelledAt = DateTime.parse(jsonInput['cancelledAt']).toLocal();
      if (jsonInput.containsKey("scoresComputedAt") && jsonInput["scoresComputedAt"] != null)
        scoresComputedAt = DateTime.parse(jsonInput['scoresComputedAt']).toLocal();

      if (jsonInput.containsKey("cancelHoursBefore"))
        cancelBefore = Duration(hours: jsonInput['cancelHoursBefore']);

      organizerId = jsonInput["organizerId"];
      cancelBefore = jsonInput.containsKey("cancelHoursBefore") ?
        Duration(hours: jsonInput["cancelHoursBefore"]) : null;

      status = MatchStatus.values
          .firstWhere((e) => e.name == jsonInput["status"]);

      if (jsonInput.containsKey("paid_out_at"))
        paidOutAt = DateTime.parse(jsonInput['paid_out_at']).toLocal();

      if (jsonInput.containsKey("sportCenter")) {
        sportCenter = SportCenter.fromJson(
            Map<String, dynamic>.from(jsonInput["sportCenter"]),
            jsonInput["sportCenter"]["placeId"]);
      }

      this.documentId = documentId;
  }

  Set<String> getPotms() => _manOfTheMatch == null
      ? Set<String>.from([]) : _manOfTheMatch!.keys.toSet();

  static Map<String, DateTime> _readGoing(Map<String, dynamic> json) {
    var map = Map<String, dynamic>.from(json["going"] ?? {});
    return map.map((key, value) =>
        MapEntry(key, DateTime.parse(value["createdAt"])));
  }

  static Map<String, List<String>> _readTeams(Map<String, dynamic> json) {
    var goingMap = Map<String, dynamic>.from(json["going"] ?? {});
    Map<String, List<String>> teams = Map();
    teams["a"] = [];
    teams["b"] = [];

    goingMap.forEach((key, value) {
      Map valueMap = value as Map;

      if (valueMap.containsKey("team")) {
        teams[valueMap["team"]]?.add(key);
      }
    });
    return teams;
  }

  static Map<String, double>? _readManOfTheMatch(Map<String, dynamic> json) {
    var map = Map<String, dynamic>.from(json["manOfTheMatch"] ?? {});
    if (map.isEmpty) {
      return null;
    }
    return map.map((key, value) => MapEntry(key, value));
  }

  Map<String, dynamic> toJson() =>
      {
        'dateTime': dateTime.toUtc().toIso8601String(),
        if (sportCenterId != null)
          'sportCenterId': sportCenterId,
        if (sportCenter != null)
          'sportCenter': sportCenter!.toJson(),
        if (sportCenterSubLocation != null)
          'sportCenterSubLocation': sportCenterSubLocation,
        'pricePerPerson': pricePerPersonInCents,
        'maxPlayers': maxPlayers,
        'minPlayers': minPlayers,
        if (cancelledAt != null)
          'cancelledAt': cancelledAt,
        'duration': duration.inMinutes,
        'organizerId': organizerId,
        if (cancelBefore != null)
          'cancelHoursBefore': cancelBefore?.inHours,
        if (userFee > 0)
          'userFee': userFee,
        if (organiserFee > 0)
          'organiserFee': organiserFee,
        if (score != null)
          'score': score,
        'managePayments': managePayments,
        'isTest': isTest
      };

  int getSpotsLeft() => maxPlayers - numPlayersGoing();

  int numPlayersGoing() => going.length;

  bool isFull() => numPlayersGoing() == maxPlayers;

  bool isUserGoing(UserDetails? user) =>
      user != null && going.containsKey(user.documentId);

  int getServiceFee() => 50;

  List<String> getGoingUsersByTime() {
    var entries = going.entries.toList()
      ..sort((e1,e2) => -e1.value.compareTo(e2.value));
    return entries.map((e) => e.key).toList();
  }

  int getGoingPlayers() => going.length;

  int getMissingPlayers() => max(0, minPlayers - going.length);

  bool hasTeams() => going.length > minPlayers
      && teams.values.map((e) => e.length).reduce((a, b) => a + b)
          == going.length;

  List<String>? getTeam(String teamName) => teams[teamName];

  DateTime getLocalizedTime(String timezoneId) =>
      tz.TZDateTime.from(dateTime, tz.getLocation(timezoneId));
}

