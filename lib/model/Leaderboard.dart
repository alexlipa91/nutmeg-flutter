import 'package:nutmeg/model/UserDetails.dart';

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

  static int compareBy(LeaderboardEntry a, LeaderboardEntry b, int index) {
    var score = (b.averageScore ?? 0).compareTo(a.averageScore ?? 0);
    var potm = b.potmCount.compareTo(a.potmCount);
    var numMatches = b.numMatchesJoined.compareTo(a.numMatchesJoined);
    var winLossRatio =  (b.getWinLossRatio() ?? -1).compareTo(a.getWinLossRatio() ?? -1);

    List<int> ordered;

    if (index == 0) {
      ordered = [score, potm, numMatches, winLossRatio];
    }
    else if (index == 1) {
      ordered = [potm, score, numMatches, winLossRatio];
    } else if (index == 2) {
      ordered = [numMatches, score, potm, winLossRatio];
    } else {
      ordered = [winLossRatio, score, potm, numMatches];
    }

    var differences = ordered.where((e) => e != 0);

    if (differences.length == 0) {
      return 0;
    }
    return differences.first;
  }
}

class Leaderboard {
  String id;
  List<LeaderboardEntry> entries;
  Map<String, UserDetails> userData;

  Leaderboard.fromJson(String id, Map<String, dynamic> json):
        this.id = id,
        userData = (json["cache_user_data"] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k,
            UserDetails.fromJson(json["cache_user_data"][k], k))),
        entries = List<LeaderboardEntry>.from(
            (json["entries"] as Map<String, dynamic>).entries.map((e) =>
                LeaderboardEntry.fromJson(e.key, e.value))
        );
}
