import 'package:flutter/cupertino.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:provider/provider.dart';

import '../model/MatchRatings.dart';
import '../state/UserState.dart';

class MatchesController {
  static var apiClient = CloudFunctionsClient();

  // logged-in user voted 'score' for user 'userId' in match 'matchId'
  static Future<void> pushAddRating(BuildContext context, String userId,
      String matchId, double score, Set<Skills> skills) async {
    try {
      await apiClient.post("matches/$matchId/ratings/add", {
        "user_id": context.read<UserState>().getLoggedUserDetails()?.documentId,
        "user_rated_id": userId,
        "score": score,
        "skills": skills.map((e) => e.name).toList()
      });
    } catch (e, s) {
      print("Failed to add rating: " + e.toString());
      print(s);
    }
  }

  static Future<void> cancelMatch(String matchId) async {
    await apiClient.get("matches/$matchId/cancel");
  }
}
