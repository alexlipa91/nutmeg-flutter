import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nutmeg/model/SportCenter.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:timezone/timezone.dart' as tz;

import 'UserDetails.dart';

enum MatchStatus {
  open, // match is on and can be joined
  pre_playing, // match is on and from now on no-one can leave
  playing, // mach is being played
  to_rate, // match is in the past and within rating window
  rated, // match is in the past and after rating window (man of the match is available)
  cancelled, // match is canceled
  unpublished // match is created but not joinable by others
}

class Price {
  int basePrice;
  int userFee;

  Price(this.basePrice, this.userFee);

  Price.fromJson(Map<String, dynamic> json)
      : basePrice = json["basePrice"],
        userFee = json["userFee"];

  Map<String, dynamic> toJson() => {"basePrice": basePrice, "userFee": userFee};

  int getBasePrice() => basePrice;
  int getTotalPrice() => basePrice + userFee;
}

class Match {
  late String documentId;

  MatchStatus? status;

  DateTime dateTime;

  String? sportCenterId;
  SportCenter? sportCenter;

  Duration duration;
  String? sportCenterSubLocation;

  Price? price;

  int minPlayers;
  int maxPlayers;
  DateTime? cancelledAt;
  DateTime? scoresComputedAt;
  DateTime? paidOutAt;

  Map<String, DateTime> going;
  Map<String, String> goingPaymentStatus; // userId -> manualPaymentStatus
  Map<String, DateTime> waitList;

  List<List<String>> computedTeams;
  List<List<String>> manualTeams;

  String? organizerId;
  Duration? cancelBefore;

  List<int>? score;

  String? dynamicLink;

  Payout? payout;

  bool isPrivate;
  bool isTest = false;
  bool isManualPayment;

  Match(
      this.dateTime,
      this.sportCenterId,
      this.sportCenter,
      this.sportCenterSubLocation,
      this.maxPlayers,
      this.price,
      this.duration,
      this.isTest,
      this.minPlayers,
      this.organizerId,
      this.going,
      this.goingPaymentStatus,
      this.waitList,
      this.computedTeams,
      this.manualTeams,
      this.isPrivate,
      this.cancelBefore,
      this.score,
      this.isManualPayment);

  Match.fromJson(Map<String, dynamic> jsonInput, String documentId)
      : dateTime = DateTime.parse(jsonInput['dateTime']),
        duration = Duration(minutes: jsonInput['duration'] ?? 60),
        isTest = jsonInput["isTest"] ?? false,
        minPlayers = jsonInput['minPlayers'] ?? 0,
        maxPlayers = jsonInput['maxPlayers'],
        going = _readGoing(jsonInput),
        goingPaymentStatus = _readGoingPaymentStatus(jsonInput),
        waitList = _readWaitList(jsonInput),
        computedTeams = _readComputedTeams(jsonInput),
        manualTeams = _readManualTeams(jsonInput),
        price = jsonInput["price"] == null
            ? null
            : Price.fromJson(jsonInput['price']),
        sportCenterId = jsonInput['sportCenterId'],
        score = jsonInput["score"] == null
            ? null
            : List<int>.from(jsonInput["score"]),
        dynamicLink = jsonInput["dynamicLink"],
        sportCenter = jsonInput["sportCenter"] == null
            ? null
            : SportCenter.fromJson(
                Map<String, dynamic>.from(jsonInput["sportCenter"]),
                jsonInput["sportCenter"]["placeId"]),
        isPrivate = jsonInput["isPrivate"] ?? false,
        isManualPayment = jsonInput["isManualPayment"] ?? false,
        payout = jsonInput["payout"] != null
            ? Payout.fromJson(jsonInput["payout"])
            : null {
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
    cancelBefore = jsonInput.containsKey("cancelHoursBefore")
        ? Duration(hours: jsonInput["cancelHoursBefore"])
        : null;

    status =
        MatchStatus.values.firstWhere((e) => e.name == jsonInput["status"]);

    if (jsonInput.containsKey("paid_out_at"))
      paidOutAt = DateTime.parse(jsonInput['paid_out_at']).toLocal();

    this.documentId = documentId;
  }

  static Map<String, DateTime> _readGoing(Map<String, dynamic> json) {
    var map = Map<String, dynamic>.from(json["going"] ?? {});
    return map
        .map((key, value) => MapEntry(key, DateTime.parse(value["createdAt"])));
  }

  static Map<String, String> _readGoingPaymentStatus(Map<String, dynamic> json) {
    var map = Map<String, dynamic>.from(json["going"] ?? {});
    return map.map((key, value) =>
        MapEntry(key, (value["manualPaymentStatus"] ?? "not_yet_paid") as String));
  }

  String getPaymentStatus(String userId) =>
      goingPaymentStatus[userId] ?? "not_yet_paid";

  bool hasUserPaid(String userId) =>
      goingPaymentStatus[userId] == "paid";

  static Map<String, DateTime> _readWaitList(Map<String, dynamic> json) {
    var map = Map<String, dynamic>.from(json["waitList"] ?? {});
    return map
        .map((key, value) => MapEntry(key, DateTime.parse(value["createdAt"])));
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
    if (json.containsKey("teams") &&
        json["teams"].containsKey("manual") &&
        json["teams"]["manual"].containsKey("players"))
      return [
        List<String>.from(json["teams"]["manual"]["players"]["a"]),
        List<String>.from(json["teams"]["manual"]["players"]["b"]),
      ].toList();
    return List.empty();
  }

  Map<String, dynamic> toJson() => {
        'dateTime': dateTime.toUtc().toIso8601String(),
        if (sportCenterId != null) 'sportCenterId': sportCenterId,
        if (sportCenter != null) 'sportCenter': sportCenter!.toJson(),
        if (sportCenterSubLocation != null)
          'sportCenterSubLocation': sportCenterSubLocation,
        if (price != null) 'price': price!.toJson(),
        'maxPlayers': maxPlayers,
        'minPlayers': minPlayers,
        if (cancelledAt != null) 'cancelledAt': cancelledAt,
        'duration': duration.inMinutes,
        'organizerId': organizerId,
        if (cancelBefore != null) 'cancelHoursBefore': cancelBefore?.inHours,
        if (score != null) 'score': score,
        "isPrivate": isPrivate,
        "dynamicLink": dynamicLink,
        'isTest': isTest,
        'isManualPayment': isManualPayment
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

  List<String> getWaitListUsersByTime() {
    var entries = waitList.entries.toList()
      ..sort((e1, e2) => e1.value.compareTo(e2.value));
    return entries.map((e) => e.key).toList();
  }

  bool isUserInWaitList(UserDetails? user) =>
      user != null && waitList.containsKey(user.documentId);

  int numPlayersInWaitList() => waitList.length;

  int getGoingPlayers() => going.length;

  int getMissingPlayers() => max(0, minPlayers - going.length);

  bool hasTeams() => computedTeams.isNotEmpty || manualTeams.isNotEmpty;

  TimeOfDay getLocalizedStart() => TimeOfDay(
      hour: getLocalizedTime().hour, minute: getLocalizedTime().minute);
  TimeOfDay getLocalizedEnd() => TimeOfDay(
      hour: getLocalizedTime().add(duration).hour,
      minute: getLocalizedTime().add(duration).minute);

  List<String> getToRate(String currentUser) {
    var all = going.keys.toSet();
    all.remove(currentUser);
    var l = all.toList();
    l.sort();
    return l;
  }

  DateTime getLocalizedTime() {
    var location = tz.getLocation(sportCenter?.timezoneId ?? tz.local.name);
    return tz.TZDateTime.from(dateTime, location);
  }

  DateTime getLocalizedTimeCancellation() {
    var location = tz.getLocation(sportCenter?.timezoneId ?? tz.local.name);
    return tz.TZDateTime.from(dateTime.subtract(cancelBefore!), location);
  }

  bool isMatchFinished() => DateTime.now().isAfter(dateTime.add(duration));
}

class Ratings {
  Map<String, double> scores;
  List<String>? potms;
  // user_id -> {award_id -> number_of_votes}
  Map<String, Map<String, int>> awards;
  int numDistinctScoreVoters;
  int numDistinctAwardVoters;
  String? ratingsNotComputedReason;

  static Map<String, Map<String, int>> readAwards(
      Map<String, dynamic> awardsJson) {
    
    var awards = Map<String, Map<String, int>>();
    for (var award in awardsJson.entries) {
      var awardId = award.key;
      var votes = Map<String, int>.from(award.value);
      awards[awardId] = votes;
    }
    return awards;
  }

  Ratings.fromJson(Map<String, dynamic> jsonInput)
      : scores = Map<String, double>.from(jsonInput["scores"] ?? {}),
        potms = List<String>.from(jsonInput["potms"] ?? []),
        awards = readAwards(jsonInput["awards"] ?? {}),
        numDistinctScoreVoters = jsonInput["num_distinct_score_voters"] ?? 0,
        numDistinctAwardVoters = jsonInput["num_distinct_award_voters"] ?? 0,
        ratingsNotComputedReason = jsonInput["ratings_not_computed_reason"];
}

class Payout {
  String status;
  int amount;
  DateTime arrivalDate;

  Payout.fromJson(Map<String, dynamic> json)
      : status = json["status"],
        arrivalDate =
            DateTime.fromMillisecondsSinceEpoch(json["arrival_date"] * 1000),
        amount = json["amount"];
}
