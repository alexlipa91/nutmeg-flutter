import 'dart:math';

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

  String sportCenterId;
  Duration duration;
  String? sportCenterSubLocation;

  int pricePerPersonInCents;
  int minPlayers;
  int maxPlayers;
  DateTime? cancelledAt;
  DateTime? scoresComputedAt;
  DateTime? paidOutAt;

  Map<String, DateTime>? going;

  late Map<String, List<String>> teams;

  Map<String, double>? _manOfTheMatch;

  String? organizerId;
  Duration? cancelBefore;

  bool isTest;

  Match(this.dateTime, this.sportCenterId, this.sportCenterSubLocation,
      this.maxPlayers, this.pricePerPersonInCents, this.duration,
      this.isTest, this.minPlayers, this.organizerId, [this.cancelBefore]);

  Match.fromJson(Map<String, dynamic> jsonInput, String documentId) :
        dateTime = DateTime.parse(jsonInput['dateTime']).toLocal(),
        duration = Duration(minutes: jsonInput['duration'] ?? 60),
        isTest = jsonInput["isTest"] ?? false,
        minPlayers = jsonInput['minPlayers'] ?? 0,
        maxPlayers = jsonInput['maxPlayers'],
        pricePerPersonInCents = jsonInput['pricePerPerson'],
        _manOfTheMatch = _readManOfTheMatch(jsonInput),
        sportCenterId = jsonInput['sportCenterId'] {
      sportCenterSubLocation = jsonInput['sportCenterSubLocation'];

      if (jsonInput.containsKey("cancelledAt") && jsonInput["cancelledAt"] != null)
        cancelledAt = DateTime.parse(jsonInput['cancelledAt']).toLocal();
      if (jsonInput.containsKey("scoresComputedAt") && jsonInput["scoresComputedAt"] != null)
        scoresComputedAt = DateTime.parse(jsonInput['scoresComputedAt']).toLocal();

      _readGoing(jsonInput);
      _readTeams(jsonInput);

      if (jsonInput.containsKey("cancelHoursBefore"))
        cancelBefore = Duration(hours: jsonInput['cancelHoursBefore']);

      organizerId = jsonInput["organizerId"];
      cancelBefore = jsonInput.containsKey("cancelHoursBefore") ?
        Duration(hours: jsonInput["cancelHoursBefore"]) : null;

      status = MatchStatus.values
          .firstWhere((e) => e.name == jsonInput["status"]);

      if (jsonInput.containsKey("paid_out_at"))
        paidOutAt = DateTime.parse(jsonInput['paid_out_at']).toLocal();

      this.documentId = documentId;
  }

  Set<String> getPotms() => _manOfTheMatch == null
      ? Set<String>.from([]) : _manOfTheMatch!.keys.toSet();

  void _readGoing(Map<String, dynamic> json) {
    var map = Map<String, dynamic>.from(json["going"] ?? {});
    going = map.map((key, value) => MapEntry(key, DateTime.parse(value["createdAt"])));
  }

  void _readTeams(Map<String, dynamic> json) {
    var map = Map<String, dynamic>.from(json["going"] ?? {});
    teams = Map();
    teams["a"] = [];
    teams["b"] = [];

    map.forEach((key, value) {
      Map valueMap = value as Map;

      if (valueMap.containsKey("team")) {
        teams[valueMap["team"]]?.add(key);
      }
    });
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
        'sportCenterId': sportCenterId,
        'sportCenterSubLocation': sportCenterSubLocation,
        'pricePerPerson': pricePerPersonInCents,
        'maxPlayers': maxPlayers,
        'minPlayers': minPlayers,
        'cancelledAt': cancelledAt,
        'duration': duration.inMinutes,
        'organizerId': organizerId,
        if (cancelBefore != null)
          'cancelHoursBefore': cancelBefore?.inHours,
        'isTest': isTest
      };

  int getSpotsLeft() => maxPlayers - numPlayersGoing();

  int numPlayersGoing() => going?.length ?? 0;

  bool isFull() => numPlayersGoing() == maxPlayers;

  bool isUserGoing(UserDetails? user) =>
      user != null && (going ?? {}).containsKey(user.documentId);

  double getPrice() => pricePerPersonInCents / 100;

  List<String> getGoingUsersByTime() {
    var entries = (going?.entries.toList() ?? [])..sort((e1,e2) => -e1.value.compareTo(e2.value));
    return entries.map((e) => e.key).toList();
  }

  int getMissingPlayers() => max(0, minPlayers - (going?.length ?? 0));

  bool hasTeams() => (going?.length ?? 0) > 0
      && teams.values.map((e) => e.length).reduce((a, b) => a + b)
          == (going?.length ?? 0);

  List<String>? getTeam(String teamName) => teams[teamName];
}

