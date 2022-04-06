import 'package:flutter/cupertino.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/state/MatchStatsState.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import '../model/PaymentRecap.dart';
import '../state/MatchesState.dart';
import '../state/UserState.dart';
import 'UserController.dart';


class MatchesController {

  static var apiClient = CloudFunctionsClient();

  static Future<Match> refresh(BuildContext context, String matchId) async {
    var matchesState = context.read<MatchesState>();

    var resp = await apiClient.callFunction("get_match_v2", {'id': matchId});
    var match = Match.fromJson(resp, matchId);

    matchesState.setMatch(match);

    return match;
  }

  static Future<List<Match>> refreshAll(BuildContext context) async {
    var matchesState = context.read<MatchesState>();

    var resp = await apiClient.callFunction("get_all_matches_v2", {});
    Map<String, dynamic> data = (resp == null) ? Map()
        : Map<String, dynamic>.from(resp);

    var matches = data.entries
        .map((e) => Match.fromJson(Map<String, dynamic>.from(e.value), e.key))
        .toList();

    matchesState.setMatches(matches);
    return matches;
  }

  // current logged in user joins a match
  static Future<Match> joinMatch(BuildContext context,
      String matchId, PaymentRecap paymentStatus) async {
    var userState = context.read<UserState>();

    await apiClient.callFunction("add_user_to_match", {
      'user_id': userState.getLoggedUserDetails().documentId,
      'match_id': matchId,
      'credits_used': paymentStatus.creditsInCentsUsed,
      'money_paid': paymentStatus.finalPriceToPayInCents()
    });
    print("joined");
    var m = await refresh(context, matchId);
    await refreshMatchStatus(context, m);
    return m;
  }

  // current logged in user leaves a match
  static Future<Match> leaveMatch(BuildContext context, String matchId) async {
    var userState = context.read<UserState>();

    await apiClient.callFunction("remove_user_from_match", {
      'user_id': userState.getLoggedUserDetails().documentId,
      'match_id': matchId
    });
    var m = await refresh(context, matchId);
    await refreshMatchStatus(context, m);
    return m;
  }

  static Future<String> addMatch(Match m) async {
    var resp = await apiClient.callFunction("add_match", m.toJson());
    return resp["id"];
  }

  static Future<void> editMatch(Match m) async {
    await apiClient.callFunction(
        "edit_match", {"id": m.documentId, "data": m.toJson()});
  }

  // compute status of a match
  static Future<Tuple2<MatchStatusForUser, List<String>>> refreshMatchStatus(
      BuildContext context, Match match) async {
    var userState = context.read<UserState>();
    var matchesState = context.read<MatchesState>();

    MatchStatusForUser status;
    List<String> stillToRateData;

    if (match.cancelledAt != null) {
      status = MatchStatusForUser.canceled;
    } else if (match.scoresComputedAt != null) {
      status = MatchStatusForUser.rated;
    } else {
      var isPast = match.dateTime.isBefore(DateTime.now());
      var isGoing =
          userState.isLoggedIn() &&
              match.isUserGoing(userState.getLoggedUserDetails());

      if (isPast) {
        if (isGoing) {
          stillToRateData = await UserController.getUsersToRateInMatchForLoggedUser(context,
              match.documentId);
          status =
          (stillToRateData.isEmpty) ? MatchStatusForUser.no_more_to_rate
              : MatchStatusForUser.to_rate;
        } else {
          return null;
        }
      } else {
        if (match.numPlayersGoing() == match.maxPlayers) {
          status = (isGoing) ? MatchStatusForUser.fullGoing
              : MatchStatusForUser.fullNotGoing;
        } else {
          status =
          (isGoing) ? MatchStatusForUser.canLeave : MatchStatusForUser.canJoin;
        }
      }
    }

    if ((status == MatchStatusForUser.to_rate || status == MatchStatusForUser.no_more_to_rate
        || status == MatchStatusForUser.rated) && shouldDisableRatings) {
      print("DISABLING IT");
      status = null;
    }

    matchesState.setMatchStatus(match.documentId, status);
    matchesState.setUsersToRate(match.documentId, stillToRateData);

    return Tuple2(status, stillToRateData);
  }

  // logged-in user voted 'score' for user 'userId' in match 'matchId'
  static Future<void> addRating(BuildContext context, String userId, String matchId, double score) async {
    try {
      await apiClient.callFunction("add_rating",
          {"user_id": context.read<UserState>().getLoggedUserDetails().documentId,
            "user_rated_id": userId,
            "match_id": matchId, "score": score});
    } catch (e, s) {
      print("Failed to add rating: " + e.toString());
      print(s);
    }
  }

  static Future<void> resetRatings(String matchId) async {
    await apiClient.callFunction("reset_ratings_for_match", {
      "match_id": matchId
    });
  }

  static Future<void> closeRatingRound(String matchId) async {
    await apiClient.callFunction("close_rating_round", {
      "match_id": matchId
    });
  }

  static Future<void> cancelMatch(String matchId) async {
    await apiClient.callFunction("cancel_match", {
      "match_id": matchId
    });
  }

  static Future<Map<String, List<int>>> refreshMatchStats(BuildContext context, String matchId) async {
    var ratingsState = context.read<MatchStatState>();

    var resp = await apiClient.callFunction("get_ratings_by_match", {
      "match_id": matchId
    });

    var r = Map<String, List<int>>();

    resp.forEach((key, value) {
      r[key] = List<int>.from(value);
    });

    ratingsState.setRatings(
        context.read<MatchesState>().getMatch(matchId).going.keys.toList(),
        r);
    return r;
  }
}
