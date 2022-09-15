class RatingEntry {
  final String user;
  final double vote;
  final bool isPotm;

  RatingEntry(this.user, this.vote, this.isPotm);
}

class SkillRatingEntry {
  final Skills s;
  final int totals;
  final int percentage;

  SkillRatingEntry(this.s, this.totals, this.percentage);
}

class VotesEntry {
  final String user;
  final int numberOfVotes;
  final int numberOfSkips;
  final bool isPotm;

  VotesEntry(this.user, this.isPotm, this.numberOfVotes, this.numberOfSkips);
}

enum
Skills {
  Speed,
  Shooting,
  Passing,
  Dribbling,
  Defending,
  Physicality,
  Goalkeeping,
}


class MatchRatings {
  final String documentId;

  late Map<String, Map<String, int>> ratingsReceived;
  late Map<String, Map<String, List<Skills>>> skillsRatingsReceived;

  MatchRatings.fromJson(Map<String, dynamic> jsonInput, String documentId):
    this.documentId = documentId {

    this.ratingsReceived = Map();
    jsonInput["scores"].forEach((receiver, value) {
      this.ratingsReceived[receiver] = Map<String, int>();
      (value as Map).forEach((user, vote) {
        this.ratingsReceived[receiver]![user] = vote;
      });
    });

    this.skillsRatingsReceived = Map();
    jsonInput["skills"].forEach((receiver, value) {
      this.skillsRatingsReceived[receiver] = Map<String, List<Skills>>();
      (value as Map).forEach((user, skillsString) {
        this.skillsRatingsReceived[receiver]![user] =
            List<String>.from(skillsString).map((e) => Skills.values.byName(e))
                .toList();
      });
    });
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

  Map<String, List<SkillRatingEntry>> getSkillRatings() {
    Map<String, List<SkillRatingEntry>> ratings = Map();

    skillsRatingsReceived.forEach((user, ratesReceived) {
      Map<Skills, int> totals = Map();

      ratesReceived.forEach((_, rated) {
        rated.forEach((skill) {
          totals[skill] = (totals[skill] ?? 0) + 1;
        });
      });

      ratings[user] = totals.entries.map((e) {
          return SkillRatingEntry(
              e.key, e.value, (e.value / ratesReceived.length * 100).toInt());})
          .toList()
        ..sort((a, b) => b.percentage - a.percentage);
    });
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

