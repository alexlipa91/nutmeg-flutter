class MatchRatings {
  String documentId;

  Map<String, Map<String, int>> ratingsReceived;


  MatchRatings.fromJson(Map<String, dynamic> jsonInput, String documentId) {
    this.ratingsReceived = Map();
    jsonInput.forEach((receiver, value) {
      this.ratingsReceived[receiver] = Map<String, int>();
      (value as Map).forEach((user, vote) {
        this.ratingsReceived[receiver][user] = vote;
      });
    });

    Map<String, dynamic>.from(jsonInput);
    this.documentId = documentId;
  }

  Map<String, double> getFinalRatings(List<String> usersGoing) {
    Map<String, double> ratings = Map();

    usersGoing.forEach((user) {
      // numberOfSkips[user] = (ratingsLists[user] ?? []).where((v) => v < 0).length;
      var votesList = (ratingsReceived[user] ?? {}).values.where((v) => v > 0);
      // numberOfVotes[user] = votesList.length;
      if (votesList.isNotEmpty) {
        ratings[user] = votesList.reduce((a, b) => a + b) / votesList.length;
      } else {
        ratings[user] = 0;
      }
    });

    return ratings;
  }

  void add(String receives, String gives, int score) {
    if (!ratingsReceived.containsKey(receives)) {
      ratingsReceived[receives] = Map();
    }
    ratingsReceived[receives][gives] = score;
  }

  int getNumberOfSkips(String user) =>
      (ratingsReceived[user] ?? {}).values.where((e) => e == -1).length;

  int getNumberOfVotes(String user) =>
      (ratingsReceived[user] ?? {}).values.where((e) => e != -1).length;

  int getNumberOfGivenVotes(String user) =>
      ratingsReceived.values.where((rec) =>
      rec.containsKey(user) && rec[user] > 0).length;

  int getNumberOfGivenSkips(String user) =>
      ratingsReceived.values.where((rec) =>
      rec.containsKey(user) && rec[user] == -1).length;
}
