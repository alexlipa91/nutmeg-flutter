class UserDetails {
  String documentId;

  bool isAdmin;
  String image;
  String name;
  String email;
  String stripeId;
  int creditsInCents;

  List<String> joinedMatches;
  List<String> organisedMatches;
  Map<String, double> scoreMatches;
  List<String> manOfTheMatch;

  bool _isConnectedAccountComplete;
  bool _isConnectedAccountTestComplete;

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
        joinedMatches = Map<String, dynamic>.from(json["joined_matches"] ?? {}).keys.toList(),
        scoreMatches = Map<String, double>.from(json["scoreMatches"] ?? {}),
        manOfTheMatch = List<String>.from(json["manOfTheMatch"] ?? []),
        _isConnectedAccountComplete = json["isConnectedAccountComplete"] ?? null,
        _isConnectedAccountTestComplete = json["isConnectedAccountTestComplete"] ?? null,
        organisedMatches = Map<String, dynamic>.from(json["organised_matches"] ?? {}).keys.toList(),
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

  double getScoreMatches() {
    if (scoreMatches == null || scoreMatches.isEmpty) {
      return -1;
    }
    return scoreMatches.values.toList()
        .where((e) => e > 0).reduce((a, b) => a + b) / scoreMatches.length;
  }

  List<String> getJoinedMatches() => (joinedMatches == null) ? List<String>.empty() : joinedMatches;

  int getNumManOfTheMatch() => (manOfTheMatch == null) ? 0 : manOfTheMatch.length;

  String getStripeId() => stripeId;

  void setStripeId(String stripeId) => stripeId = stripeId;

  String getPhotoUrl() => image;
  
  bool getIsAdmin() => (isAdmin == null) ? false : isAdmin;

  bool isOrganiser() {
    return this._isConnectedAccountComplete != null
        || this._isConnectedAccountTestComplete != null;
  }

  bool connectedAccountNeedsCompletion(isTest) {
    var outcome =
      isTest ?
      (_isConnectedAccountTestComplete != null && !_isConnectedAccountTestComplete) :
      (_isConnectedAccountComplete != null && !_isConnectedAccountComplete);
    return outcome;
  }

  static String getDisplayName(UserDetails ud) {
    if (ud == null) return "Player";
    if (ud.name != null) return ud.name;
    if (ud.email != null && !ud.email.contains("privaterelay")) return ud.email;
    return "Player";
  }
}

