import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
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

  static Future<void> refreshAll(MatchesState matchesState) async {
    var matches = await getMatches();
    matchesState.setMatches(matches);
  }

  static Future<void> refreshImages(MatchesState matchesState) async {
    Map<String, String> images = Map.fromEntries(await Future.wait(matchesState
        .getMatches()
        .map((m) async => MapEntry(
            m.documentId, await MatchesController.getMatchThumbnailUrl(m)))));
    matchesState.setImages(images);
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
    var resp = await CloudFunctionsUtils.callFunction("get_match", {'id': matchId});
    var match = Match.fromJson(resp, matchId);
    return match;
  }

  static Future<List<Match>> getMatches() async {
    var resp = await CloudFunctionsUtils.callFunction("get_all_matches", {});

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

  // it loads all pictures from the sportcenter in folder sportcenters/<sportcenter_id>/large
  // if no <sportcenter_id> subfolder it uses "default"
  static Future<List<String>> getMatchPicturesUrls(Match match) async {
    var mainFolderRef =
        await FirebaseStorage.instance.ref("sportcenters").listAll();
    var listOfFolders = mainFolderRef.prefixes;

    var folder;
    if (listOfFolders.where((ref) => ref.name == match.sportCenterId).isEmpty) {
      folder = "default";
    } else {
      folder = match.sportCenterId;
    }

    var allRefs = await FirebaseStorage.instance
        .ref("sportcenters/" + folder + "/large")
        .listAll();
    var urls = await Future.wait(allRefs.items.map((e) => e.getDownloadURL()));
    return urls;
  }

  // it loads the thumbnail picture from the sportcenter at sportcenters/<sportcenter_id>/thumbnail.png
  // if no <sportcenter_id> subfolder it uses "default"
  static Future<String> getMatchThumbnailUrl(Match match) async {
    var listOfFiles =
        await FirebaseStorage.instance.ref("sportcenters/").listAll();

    var file;
    if (listOfFiles.prefixes
        .where((ref) => ref.name == match.sportCenterId)
        .isEmpty) {
      file = "sportcenters/default/thumbnail.png";
    } else {
      file = "sportcenters/" + match.sportCenterId + "/thumbnail.png";
    }

    var url = await FirebaseStorage.instance.ref(file).getDownloadURL();
    return url;
  }
}
