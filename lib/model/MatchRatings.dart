class RatingEntry {
  final String user;
  final double vote;
  final bool isPotm;

  RatingEntry(this.user, this.vote, this.isPotm);
}

class VotesEntry {
  final String user;
  final int numberOfVotes;
  final int numberOfSkips;
  final bool isPotm;

  VotesEntry(this.user, this.isPotm, this.numberOfVotes, this.numberOfSkips);
}


class MatchRatings {
  String documentId;

  late Map<String, Map<String, int>> ratingsReceived;

  MatchRatings.fromJson(Map<String, dynamic> jsonInput, String documentId):
    this.documentId = documentId {
    this.ratingsReceived = Map();
    jsonInput.forEach((receiver, value) {
      this.ratingsReceived[receiver] = Map<String, int>();
      (value as Map).forEach((user, vote) {
        this.ratingsReceived[receiver]![user] = vote;
      });
    });

    Map<String, dynamic>.from(jsonInput);
    this.documentId = documentId;
  }

  List<RatingEntry> getFinalRatings(List<String> usersGoing, Set<String> potm) {
    List<RatingEntry> ratings = List.from([]);

    usersGoing.forEach((user) {
      var votesList = (ratingsReceived[user] ?? {}).values.where((v) => v > 0);
      if (votesList.isNotEmpty) {
        ratings.add(RatingEntry(
            user,
            votesList.reduce((a, b) => a + b) / votesList.length,
            potm.contains(user)
        ));
      } else {
        ratings.add(RatingEntry(user, 0, false));
      }
    });

    ratings.sort((a, b) => b.vote.compareTo(a.vote));

    return ratings;
  }

  List<VotesEntry> getVotesEntry(List<String> usersGoing, Set<String> potm, String type) {
    List<VotesEntry> votes = List.from([]);

    usersGoing.forEach((user) {
      votes.add(VotesEntry(
          user,
          potm.contains(user),
          type == "RECEIVED" ? getNumberOfVotes(user) : getNumberOfGivenVotes(user),
          type == "RECEIVED" ? getNumberOfSkips(user) : getNumberOfGivenSkips(user)
      ));
    });

    votes.sort((a, b) => b.numberOfVotes.compareTo(a.numberOfVotes));

    return votes;
  }


  void add(String receives, String gives, int score) {
    if (!ratingsReceived.containsKey(receives)) {
      ratingsReceived[receives] = Map();
    }
    ratingsReceived[receives]![gives] = score;
  }

  int getNumberOfSkips(String user) =>
      (ratingsReceived[user] ?? {}).values.where((e) => e == -1).length;

  int getNumberOfVotes(String user) =>
      (ratingsReceived[user] ?? {}).values.where((e) => e != -1).length;

  int getNumberOfGivenVotes(String user) =>
      ratingsReceived.values.where((rec) =>
      rec.containsKey(user) && rec[user]! > 0).length;

  int getNumberOfGivenSkips(String user) =>
      ratingsReceived.values.where((rec) =>
      rec.containsKey(user) && rec[user] == -1).length;
}

