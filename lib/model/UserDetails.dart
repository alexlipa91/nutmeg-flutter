class UserDetails {
  String documentId;

  bool isAdmin;
  String image;
  String name;
  String email;
  String stripeId;
  int creditsInCents;

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

  String getStripeId() => stripeId;

  void setStripeId(String stripeId) => stripeId = stripeId;

  String getPhotoUrl() => image;
}

