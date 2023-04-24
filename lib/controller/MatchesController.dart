import 'package:flutter/cupertino.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:provider/provider.dart';

import '../model/MatchRatings.dart';
import '../model/PaymentRecap.dart';
import '../state/MatchesState.dart';
import '../state/UserState.dart';


class MatchesController {

  static var apiClient = CloudFunctionsClient();

  // current logged in user joins a match
  static Future<Match> joinMatch(
      BuildContext context, String matchId, PaymentRecap paymentStatus) async {
    await apiClient.post("matches/$matchId/users/add", {
      'match_id': matchId,
    });
    var  m = await context.read<MatchesState>().fetchMatch(matchId);
    return m;
  }

  // current logged in user leaves a match
  static Future<Match> leaveMatch(BuildContext context, String matchId) async {
    await CloudFunctionsClient().post("matches/$matchId/users/remove", {});
    var m = await context.read<MatchesState>().fetchMatch(matchId);
    return m;
  }

  // logged-in user voted 'score' for user 'userId' in match 'matchId'
  static Future<void> pushAddRating(
      BuildContext context, String userId, String matchId, double score,
      Set<Skills> skills) async {
    try {
      await apiClient.post("matches/$matchId/ratings.add", {
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
    await apiClient.callFunction("cancel_match", {"match_id": matchId});
  }
}
