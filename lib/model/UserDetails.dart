import '../state/UserState.dart';

class UserDetails {
  String documentId;

  bool? isAdmin;
  String? image;
  String? name;
  String? email;
  String? stripeId;
  int? creditsInCents;

  int? numJoinedMatches;
  int numRatedMatches;
  double sumTotalRates;
  double? averageScore;
  double? deltaFromLastScore;
  List<double>? lastScores;
  Map<String, int>? skillsCount;

  List<String>? createdMatches;
  List<String>? createdTestMatches;

  int? potmCount;

  bool? chargesEnabledOnStripe;
  bool? chargesEnabledOnStripeTest;

  LocationInfo? location;

  UserDetails(this.documentId, this.isAdmin, this.image, this.name, this.email)
      : numRatedMatches = 0,
        sumTotalRates = 0,
        creditsInCents = 0;

  UserDetails.fromJson(Map<String, dynamic> json, String documentId)
      : isAdmin = (json["isAdmin"] == null) ? false : json["isAdmin"],
        image = json["image"],
        name = json["name"],
        email = json["email"],
        creditsInCents = json["credits"],
        stripeId = json["stripeId"] ?? null,
        numJoinedMatches = json["num_matches_joined"] ?? 0,
        averageScore = json["avg_score"] ?? null,
        numRatedMatches = (json["scores"] ?? {})["number_of_scored_games"] ?? 0,
        sumTotalRates = ((json["scores"] ?? {})["total_sum"] ?? 0).toDouble(),
        potmCount = json["potm_count"] ?? 0,
        lastScores = (json["last_date_scores"] == null) ? []
            : _readLastScores(Map<String, double>.from(json["last_date_scores"])),
        deltaFromLastScore = json["delta_from_last_score"],
        skillsCount = Map<String, int>.from((json["skills_count"] ?? {})),
        chargesEnabledOnStripe = json["chargesEnabledOnStripe"] ?? false,
        chargesEnabledOnStripeTest = json["chargesEnabledOnStripeTest"] ?? false,
        createdMatches = Map<String, dynamic>.from(json["created_matches"] ?? {}).keys.toList(),
        createdTestMatches = Map<String, dynamic>.from(json["created_test_matches"] ?? {}).keys.toList(),
        location = json.containsKey("location") ? LocationInfo.fromJson(json["location"]) : null,
        documentId = documentId;

  static List<double> _readLastScores(Map<String, double> lastDateScores) {
    var sortedKeys = lastDateScores.keys.toList()..sort();
    return sortedKeys.map((d) => lastDateScores[d]!).toList();
  }

  Map<String, dynamic> toJson() =>
      {
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

  int getNumManOfTheMatch() => potmCount ?? 0;

  String? getStripeId() => stripeId;

  void setStripeId(String stripeId) => stripeId = stripeId;

  String? getPhotoUrl() => image;
  
  bool getIsAdmin() => (isAdmin == null) ? false : isAdmin!;

  bool isOrganiser(isTest) {
    if (isTest)
      return this.createdTestMatches != null && this.createdTestMatches!.isNotEmpty;
    return this.createdMatches != null && this.createdMatches!.isNotEmpty;
  }

  bool areChargesEnabled(bool isTest) {
    return isTest ? chargesEnabledOnStripeTest ?? false : chargesEnabledOnStripe ?? false;
  }

  double getDeltaFromLastScore() => deltaFromLastScore ?? 0;

  static String getDisplayName(UserDetails? ud) {
    if (ud == null) return "Player";
    if (ud.name != null) return ud.name!;
    if (ud.email != null && !ud.email!.contains("privaterelay")) return ud.email!;
    return "Player";
  }
}
