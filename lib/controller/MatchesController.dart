import 'package:nutmeg/controller/CloudFunctionsUtils.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';

class MatchesController {
  static Future<Match> refresh(
      MatchesState matchesState, String matchId) async {
    var match = await getMatch(matchId);
    matchesState.setMatch(match);
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
      'user_id': userState.getUserDetails().documentId,
      'match_id': matchId,
      'credits_used': paymentStatus.creditsInCentsUsed,
      'money_paid': paymentStatus.finalPriceToPayInCents()
    });
  }

  static leaveMatch(
      MatchesState matchesState, String matchId, UserState userState) async {
    await CloudFunctionsUtils.callFunction("remove_user_from_match", {
      'user_id': userState.getUserDetails().documentId,
      'match_id': matchId
    });
    await refresh(matchesState, matchId);
  }

  static Future<Match> getMatch(String matchId) async {
    var resp = await CloudFunctionsUtils.callFunction("get_match_v2", {'id': matchId});
    var match = Match.fromJson(resp, matchId);
    return match;
  }

  static Future<List<Match>> getMatches() async {
    var resp = await CloudFunctionsUtils.callFunction("get_all_matches_v2", {});

    Map<String, dynamic> data = Map<String, dynamic>.from(resp);

    return data.entries
        .map((e) => Match.fromJson(Map<String, dynamic>.from(e.value), e.key))
        .toList();
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
}
