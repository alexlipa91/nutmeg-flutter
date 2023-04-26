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
  SportCenter sportCenter;

  Duration duration;
  String? sportCenterSubLocation;

  int pricePerPersonInCents;
  int minPlayers;
  int maxPlayers;
  DateTime? cancelledAt;
  DateTime? scoresComputedAt;
  DateTime? paidOutAt;

  Map<String, DateTime> going;

  List<List<String>> computedTeams;
  List<List<String>> manualTeams;
  bool? hasManualTeams;

  String? organizerId;
  Duration? cancelBefore;

  int userFee;
  int organiserFee;

  bool managePayments;

  List<int>? score;

  String? dynamicLink;

  bool isTest;

  Match(this.dateTime, this.sportCenterId, this.sportCenter,
      this.sportCenterSubLocation,
      this.maxPlayers, this.pricePerPersonInCents, this.duration,
      this.isTest, this.minPlayers, this.organizerId, this.userFee,
      this.organiserFee, this.going, this.computedTeams, this.manualTeams,
      this.cancelBefore,
      this.managePayments, this.score);

  Match.fromJson(Map<String, dynamic> jsonInput, String documentId)
      :
        dateTime = DateTime.parse(jsonInput['dateTime']),
        duration = Duration(minutes: jsonInput['duration'] ?? 60),
        isTest = jsonInput["isTest"] ?? false,
        minPlayers = jsonInput['minPlayers'] ?? 0,
        maxPlayers = jsonInput['maxPlayers'],
        going = _readGoing(jsonInput),
        computedTeams = _readComputedTeams(jsonInput),
        manualTeams = _readManualTeams(jsonInput),
        hasManualTeams = jsonInput["hasManualTeams"],
        pricePerPersonInCents = jsonInput['pricePerPerson'],
        sportCenterId = jsonInput['sportCenterId'],
        userFee = jsonInput["userFee"] ?? 0,
        organiserFee = jsonInput["organiserFee"] ?? 0,
        score = jsonInput["score"] == null ? null : List<int>.from(
            jsonInput["score"]),
        dynamicLink = jsonInput["dynamicLink"],
        managePayments = jsonInput["managePayments"] ?? true,
        sportCenter = SportCenter.fromJson(
            Map<String, dynamic>.from(jsonInput["sportCenter"]),
            jsonInput["sportCenter"]["placeId"]) {
    sportCenterSubLocation = jsonInput['sportCenterSubLocation'];

    if (jsonInput.containsKey("cancelledAt") &&
        jsonInput["cancelledAt"] != null)
      cancelledAt = DateTime.parse(jsonInput['cancelledAt']).toLocal();
    if (jsonInput.containsKey("scoresComputedAt") &&
        jsonInput["scoresComputedAt"] != null)
      scoresComputedAt =
          DateTime.parse(jsonInput['scoresComputedAt']).toLocal();

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

  static Map<String, DateTime> _readGoing(Map<String, dynamic> json) {
    var map = Map<String, dynamic>.from(json["going"] ?? {});
    return map.map((key, value) =>
        MapEntry(key, DateTime.parse(value["createdAt"])));
  }

  static List<List<String>> _readComputedTeams(Map<String, dynamic> json) {
    if (json.containsKey("teams"))
      return [
        List<String>.from(json["teams"]["balanced"]["players"]["a"]),
        List<String>.from(json["teams"]["balanced"]["players"]["b"]),
      ].toList();
    return List.empty();
  }

  static List<List<String>> _readManualTeams(Map<String, dynamic> json) {
    if (json.containsKey("teams") && json["teams"].containsKey("manual"))
      return [
        List<String>.from(json["teams"]["manual"]["players"]["a"]),
        List<String>.from(json["teams"]["manual"]["players"]["b"]),
      ].toList();
    return List.empty();
  }

  Map<String, dynamic> toJson() =>
      {
        'dateTime': dateTime.toUtc().toIso8601String(),
        if (sportCenterId != null)
          'sportCenterId': sportCenterId,
        'sportCenter': sportCenter.toJson(),
        if (sportCenterSubLocation != null)
          'sportCenterSubLocation': sportCenterSubLocation,
        'pricePerPerson': pricePerPersonInCents,
        'maxPlayers': maxPlayers,
        'minPlayers': minPlayers,
        if (cancelledAt != null)
          'cancelledAt': cancelledAt,
        if (hasManualTeams != null)
          "hasManualTeams": hasManualTeams,
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
        "dynamicLink": dynamicLink,
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
      ..sort((e1, e2) => -e1.value.compareTo(e2.value));
    return entries.map((e) => e.key).toList();
  }

  int getGoingPlayers() => going.length;

  int getMissingPlayers() => max(0, minPlayers - going.length);

  bool hasTeams() => computedTeams.isNotEmpty;

  DateTime getLocalizedTime(String timezoneId) =>
      tz.TZDateTime.from(dateTime, tz.getLocation(timezoneId));

  bool isMatchFinished() => DateTime.now().isAfter(dateTime.add(duration));

  bool canUserModifyTeams(String? userId) {
    return userId != null && userId == organizerId;
  }
}

class Ratings {

  Map<String, double> scores;
  List<String>? potms;

  Ratings.fromJson(Map<String, dynamic> jsonInput) :
      scores = Map<String, double>.from(jsonInput["scores"]),
      potms = List<String>.from(jsonInput["potms"] ?? []);
}

