class UserDetails {
  String documentId;

  bool? isAdmin;
  String? image;
  String? name;
  String? email;
  String? stripeId;
  int? creditsInCents;

  int? numJoinedMatches;
  double? averageScore;

  List<String>? createdMatches;
  List<String>? createdTestMatches;

  int? potmCount;

  bool? chargesEnabledOnStripe;
  bool? chargesEnabledOnStripeTest;

  UserDetails.empty(this.documentId);

  UserDetails(this.documentId, this.isAdmin, this.image, this.name, this.email)
      : creditsInCents = 0;

  UserDetails.from(String documentId, UserDetails u)
      : this.documentId = documentId,
        this.isAdmin = u.isAdmin,
        this.image = u.image,
        this.name = u.name,
        this.email = u.email,
        this.stripeId = u.stripeId,
        this.creditsInCents = u.creditsInCents;

  UserDetails.fromJson(Map<String, dynamic> json, String documentId)
      : isAdmin = (json["isAdmin"] == null) ? false : json["isAdmin"],
        image = json["image"],
        name = json["name"],
        email = json["email"],
        creditsInCents = json["credits"],
        stripeId = json["stripeId"] ?? null,
        numJoinedMatches = json["num_matches_joined"] ?? 0,
        averageScore = json["avg_score"] ?? null,
        potmCount = json["potm_count"] ?? 0,
        chargesEnabledOnStripe = json["chargesEnabledOnStripe"] ?? false,
        chargesEnabledOnStripeTest = json["chargesEnabledOnStripeTest"] ?? false,
        createdMatches = Map<String, dynamic>.from(json["created_matches"] ?? {}).keys.toList(),
        createdTestMatches = Map<String, dynamic>.from(json["created_test_matches"] ?? {}).keys.toList(),
        documentId = documentId;

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

  static String getDisplayName(UserDetails? ud) {
    if (ud == null) return "Player";
    if (ud.name != null) return ud.name!;
    if (ud.email != null && !ud.email!.contains("privaterelay")) return ud.email!;
    return "Player";
  }
}
