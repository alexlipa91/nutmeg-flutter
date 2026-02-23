import 'package:nutmeg/model/LocationInfo.dart';

class StripeInfo {
  String? connectedAccountId;
  bool chargesEnabled;
  String? customerId;

  StripeInfo({
    this.connectedAccountId,
    this.chargesEnabled = false,
    this.customerId,
  });

  factory StripeInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return StripeInfo();
    return StripeInfo(
      connectedAccountId: json["connected_account_id"],
      chargesEnabled: json["charges_enabled"] ?? false,
      customerId: json["customer_id"],
    );
  }
}

class UserDetails {
  String documentId;

  bool? isAdmin;
  String? image;
  String? name;
  String? email;
  int? creditsInCents;

  int? numJoinedMatches;
  int numRatedMatches;
  double sumTotalRates;
  double? averageScore;
  double? deltaFromLastScore;
  List<double>? lastScores;
  List<String>? lastScoreDates;
  Map<String, int>? skillsCount;

  List<String>? createdMatches;
  List<String>? createdTestMatches;

  Map<String, bool>? potmDates;

  StripeInfo stripeInfo;
  StripeInfo stripeTestInfo;

  int? numWin;
  int? numDraw;
  int? numLoss;

  LocationInfo? location;
  String? language;

  String? paymentInfo;

  Map<String, int>? playedWith;
  Map<String, int>? organizerPlayers;

  Map<String, dynamic>? appInfo;

  UserDetails(this.documentId, this.isAdmin, this.image, this.name, this.email)
      : numRatedMatches = 0,
        sumTotalRates = 0,
        creditsInCents = 0,
        stripeInfo = StripeInfo(),
        stripeTestInfo = StripeInfo();

  UserDetails.fromJson(Map<String, dynamic> json, String documentId)
      : isAdmin = (json["isAdmin"] == null) ? false : json["isAdmin"],
        image = json["image"],
        name = json["name"],
        email = json["email"],
        creditsInCents = json["credits"],
        stripeInfo = StripeInfo.fromJson(
            json["stripe"] as Map<String, dynamic>?),
        stripeTestInfo = StripeInfo.fromJson(
            json["stripe_test"] as Map<String, dynamic>?),
        numJoinedMatches = json["num_matches_joined"] ?? 0,
        averageScore = json["avg_score"] ?? null,
        numRatedMatches = (json["scores"] ?? {})["number_of_scored_games"] ?? 0,
        sumTotalRates = ((json["scores"] ?? {})["total_sum"] ?? 0).toDouble(),
        potmDates = json["potm_dates"] != null
            ? Map<String, bool>.from(
                (json["potm_dates"] as Map).map((k, v) => MapEntry(k.toString(), true)))
            : null,
        lastScores = (json["last_date_scores"] == null)
            ? []
            : _readLastScores(
                Map<String, double>.from(json["last_date_scores"])),
        lastScoreDates = (json["last_date_scores"] == null)
            ? []
            : _readLastScoreDates(
                Map<String, double>.from(json["last_date_scores"])),
        deltaFromLastScore = json["delta_from_last_score"],
        skillsCount = Map<String, int>.from((json["skills_count"] ?? {})),
        createdMatches =
            Map<String, dynamic>.from(json["created_matches"] ?? {})
                .keys
                .toList(),
        createdTestMatches =
            Map<String, dynamic>.from(json["created_test_matches"] ?? {})
                .keys
                .toList(),
        location = json.containsKey("location")
            ? LocationInfo.fromJson(json["location"])
            : null,
        language = json["language"],
        numWin = (json["record"] ?? {})["num_win"],
        numLoss = (json["record"] ?? {})["num_loss"],
        numDraw = (json["record"] ?? {})["num_draw"],
        paymentInfo = json["paymentInfo"],
        playedWith = json["played_with"] != null
            ? Map<String, dynamic>.from(json["played_with"])
                .map((k, v) => MapEntry(k, (v as num).toInt()))
            : null,
        organizerPlayers = json["organizer_players"] != null
            ? Map<String, dynamic>.from(json["organizer_players"])
                .map((k, v) => MapEntry(k, (v as num).toInt()))
            : null,
        appInfo = json["app_info"] != null
            ? Map<String, dynamic>.from(json["app_info"])
            : null,
        documentId = documentId;

  static List<double> _readLastScores(Map<String, double> lastDateScores) {
    var sortedKeys = lastDateScores.keys.toList()..sort();
    return sortedKeys.map((d) => lastDateScores[d]!).toList();
  }

  static List<String> _readLastScoreDates(Map<String, double> lastDateScores) {
    var sortedKeys = lastDateScores.keys.toList()..sort();
    return sortedKeys;
  }

  Map<String, dynamic> toJson() => {
        'isAdmin': isAdmin,
        'image': image,
        'name': name,
        'email': email,
        'credits': creditsInCents,
      };

  String getUid() => documentId;

  double? getScoreMatches() => averageScore;

  int getNumJoinedMatches() => numJoinedMatches ?? 0;

  List<double> getLastScores() => lastScores ?? [];

  int getNumManOfTheMatch() => potmDates?.length ?? 0;

  StripeInfo getStripeInfo(bool isTest) => isTest ? stripeTestInfo : stripeInfo;

  String? getPhotoUrl() => image;

  bool getIsAdmin() => (isAdmin == null) ? false : isAdmin!;

  String? getShortName() => name?.split(' ').first;

  bool isOrganiser(isTest) {
    if (isTest)
      return this.createdTestMatches != null &&
          this.createdTestMatches!.isNotEmpty;
    return this.createdMatches != null && this.createdMatches!.isNotEmpty;
  }

  bool areChargesEnabled(bool isTest) {
    return getStripeInfo(isTest).chargesEnabled;
  }

  double getDeltaFromLastScore() => deltaFromLastScore ?? 0;

  static String getDisplayName(UserDetails? ud) {
    if (ud == null) return "Player";
    if (ud.name != null) return ud.name!;
    if (ud.email != null && !ud.email!.contains("privaterelay"))
      return ud.email!;
    return "Player";
  }
}
