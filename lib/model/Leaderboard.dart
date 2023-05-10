class LeaderboardEntry {
  String userId;
  int numMatchesJoined;
  int potmCount;
  int numDraw;
  int numLoss;
  int numWin;
  double? averageScore;

  double? getWinLossRatio() {
    var total = numWin + numDraw + numLoss;
    if (total == 0) {
      return null;
    }
    return (numWin / total) * 100;
  }

  LeaderboardEntry.fromJson(String userId, Map<String, dynamic> userJson):
      this.userId = userId,
      this.numMatchesJoined = userJson["num_matches_joined"],
      this.potmCount = userJson["potm_count"],
      this.numDraw = userJson["record"]["num_draw"],
      this.numLoss = userJson["record"]["num_loss"],
      this.numWin = userJson["record"]["num_win"],
      this.averageScore = userJson["scores"]["number_of_scored_games"] == 0
          ? null : userJson["scores"]["total_sum"] / userJson["scores"]["number_of_scored_games"];
}

class Leaderboard {
  String id;
  List<LeaderboardEntry> entries;

  Leaderboard.fromJson(String id, Map<String, dynamic> json):
        this.id = id,
        entries = List<LeaderboardEntry>.from(
            (json["entries"] as Map<String, dynamic>).entries.map((e) =>
                LeaderboardEntry.fromJson(e.key, e.value))
        );
}
