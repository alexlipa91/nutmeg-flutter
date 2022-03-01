class Sport {
  String documentId;

  String displayTitle;

  Sport(this.displayTitle);

  Sport.fromJson(Map<String, dynamic> json, String documentId)
      : displayTitle = json["displayTitle"],
        documentId = documentId;
}
