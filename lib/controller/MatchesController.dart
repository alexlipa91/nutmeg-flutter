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

  static Future<Match> refresh(BuildContext context, String matchId) async {
    var matchesState = context.read<MatchesState>();

    var resp = await apiClient.callFunction("get_match_v2", {'id': matchId});
    var match = Match.fromJson(resp!, matchId);

    matchesState.setMatch(match);

    return match;
  }

  // current logged in user joins a match
  static Future<Match> joinMatch(
      BuildContext context, String matchId, PaymentRecap paymentStatus) async {
    var userState = context.read<UserState>();

    await apiClient.callFunction("add_user_to_match", {
      'user_id': userState.getLoggedUserDetails()?.documentId,
      'match_id': matchId,
      'credits_used': paymentStatus.creditsInCentsUsed,
      'money_paid': paymentStatus.finalPriceToPayInCents()
    });
    var  m = await refresh(context, matchId);
    return m;
  }

  // current logged in user leaves a match
  static Future<Match> leaveMatch(BuildContext context, String matchId) async {
    var userState = context.read<UserState>();

    await apiClient.callFunction("remove_user_from_match", {
      'user_id': userState.getLoggedUserDetails()?.documentId,
      'match_id': matchId
    });
    var m = await refresh(context, matchId);
    return m;
  }

  static Future<String> addMatch(Match m) async {
    var resp = await apiClient.callFunction("add_match", m.toJson());
    return resp!["id"];
  }

  static Future<void> editMatch(Match m, String documentId) async {
    var json = m.toJson();
    json["id"] = documentId;
    await apiClient.callFunction("add_match", json);
  }

  // logged-in user voted 'score' for user 'userId' in match 'matchId'
  static Future<void> addRating(
      BuildContext context, String userId, String matchId, double score,
      Set<Skills> skills) async {
    try {
      await apiClient.callFunction("add_rating", {
        "user_id": context.read<UserState>().getLoggedUserDetails()?.documentId,
        "user_rated_id": userId,
        "match_id": matchId,
        "score": score,
        "skills": skills.map((e) => e.name).toList()
      });
    } catch (e, s) {
      print("Failed to add rating: " + e.toString());
      print(s);
    }
  }

  static Future<void> resetRatings(String matchId) async {
    await apiClient
        .callFunction("reset_ratings_for_match", {"match_id": matchId});
  }

  static Future<void> closeRatingRound(String matchId) async {
    await apiClient.callFunction("close_rating_round", {"match_id": matchId});
  }

  static Future<void> cancelMatch(String matchId) async {
    await apiClient.callFunction("cancel_match", {"match_id": matchId});
  }
}
