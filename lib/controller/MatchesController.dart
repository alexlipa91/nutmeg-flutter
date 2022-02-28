import 'package:nutmeg/controller/CloudFunctionsUtils.dart';
import 'package:nutmeg/model/Model.dart';

import '../state/MatchesState.dart';
import '../state/UserState.dart';
import 'UserController.dart';


class MatchesController {

  static Future<Match> refresh(
      MatchesState matchesState, UserState userState, String matchId) async {
    var match = await getMatch(matchId);
    matchesState.setMatch(match);

    await _refreshMatchStatus(matchId, matchesState, userState);
    return match;
  }

  static Future<void> init(MatchesState matchesState) async {
    if (matchesState.getMatches() == null) {
      await refreshAll(matchesState);
    }
  }

  static Future<void> refreshAll(MatchesState matchesState) async {
    var matches = await getMatches();
    matchesState.setMatches(matches);
  }

  static Future<void> joinMatch(MatchesState matchesState, String matchId,
      UserState userState, PaymentRecap paymentStatus) async {
    await CloudFunctionsUtils.callFunction("add_user_to_match", {
      'user_id': userState.getLoggedUserDetails().documentId,
      'match_id': matchId,
      'credits_used': paymentStatus.creditsInCentsUsed,
      'money_paid': paymentStatus.finalPriceToPayInCents()
    });
    print("joined");
    await refresh(matchesState, userState, matchId);
  }

  static leaveMatch(
      MatchesState matchesState, String matchId, UserState userState) async {
    await CloudFunctionsUtils.callFunction("remove_user_from_match", {
      'user_id': userState.getLoggedUserDetails().documentId,
      'match_id': matchId
    });
    await refresh(matchesState, userState, matchId);
  }

  static Future<Match> getMatch(String matchId) async {
    var resp = await CloudFunctionsUtils.callFunction("get_match_v2", {'id': matchId});
    var match = Match.fromJson(resp, matchId);
    return match;
  }

  static Future<List<Match>> getMatches() async {
    var resp = await CloudFunctionsUtils.callFunction("get_all_matches_v2", {});

    Map<String, dynamic> data = (resp == null) ? Map() : Map<String, dynamic>.from(resp);

    var matches = data.entries
        .map((e) => Match.fromJson(Map<String, dynamic>.from(e.value), e.key))
        .toList();
    return matches;
  }

  static Future<String> addMatch(Match m) async {
    var resp = await CloudFunctionsUtils.callFunction("add_match", m.toJson());
    return resp["id"];
  }

  static Future<void> editMatch(MatchesState matchesState, Match m) async {
    matchesState.setMatch(m);
    await CloudFunctionsUtils.callFunction(
        "edit_match", {"id": m.documentId, "data": m.toJson()});
  }

  static Future<void> _refreshMatchStatus(String matchId, MatchesState state,
      UserState userState) async {
    Match match = state.getMatch(matchId);

    MatchStatusForUser status;
    List<UserDetails> stillToRateData;

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
          stillToRateData = await UserController.getUsersToRateInMatch(matchId,
              userState.getLoggedUserDetails().documentId, userState);
          status =
          (stillToRateData.isEmpty) ? MatchStatusForUser.no_more_to_rate
              : MatchStatusForUser.to_rate;
        } else {
          print("We shouldn't show this match to the user");
          return null;
        }
      } else {
        if (match.numPlayersGoing() == match.maxPlayers) {
          status = MatchStatusForUser.full;
        } else {
          status =
          (isGoing) ? MatchStatusForUser.leave : MatchStatusForUser.join;
        }
      }
    }

    state.setMatchStatus(matchId, status);
    userState.setUsersStillToRate(matchId, stillToRateData);
  }
}
