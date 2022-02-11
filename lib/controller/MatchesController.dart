import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
    HttpsCallable callable =
        FirebaseFunctions.instanceFor(region: "europe-central2")
            .httpsCallable('add_user_to_match');
    await callable({
      'user_id': userState.getUserDetails().documentId,
      'match_id': matchId,
      'credits_used': paymentStatus.creditsInCentsUsed,
      'money_paid': paymentStatus.finalPriceToPayInCents()
    });
  }

  static leaveMatch(
      MatchesState matchesState, String matchId, UserState userState) async {
    HttpsCallable callable =
        FirebaseFunctions.instanceFor(region: "europe-central2")
            .httpsCallable('remove_user_from_match');
    await callable({
      'user_id': userState.getUserDetails().documentId,
      'match_id': matchId
    });

    await refresh(matchesState, matchId);
  }

  static Future<Match> getMatch(String matchId) async {
    HttpsCallable callable = FirebaseFunctions.instanceFor(region: "europe-central2")
        .httpsCallable('get_match');

    var resp = await callable({'id': matchId});
    Map<String, dynamic> data = json.decode(resp.data);

    return Match.fromJson(data, matchId);
  }

  static Future<List<Match>> getMatches() async {
    HttpsCallable callable =
    FirebaseFunctions.instanceFor(region: "europe-central2")
        .httpsCallable('get_all_matches');

    var resp = await callable();
    Map<String, dynamic> data = Map<String, dynamic>.from(resp.data);

    return data.entries.map((e) => Match.fromJson(
        json.decode(e.value),
        e.key)).toList();
  }

  static Future<String> addMatch(Match m) async {
    HttpsCallable callable =
        FirebaseFunctions.instanceFor(region: "europe-central2")
            .httpsCallable('add_match');
    print(m.toJson());
    var resp = await callable(m.toJson());
    return (resp).data["id"];
  }

  static Future<void> editMatch(Match m) async {
    HttpsCallable callable =
    FirebaseFunctions.instanceFor(region: "europe-central2")
        .httpsCallable('edit_match');
    await callable({"id": m.documentId, "data": m.toJson()});
  }

  static Future<void> cancelMatch(
      MatchesState matchesState, String matchId) async {
    var match = matchesState.getMatch(matchId);
    match.cancelledAt = Timestamp.fromDate(DateTime.now());
    await editMatch(match);
    matchesState.setMatch(await getMatch(matchId));
  }

  // it loads all pictures from the sportcenter in folder sportcenters/<sportcenter_id>/large
  // if no <sportcenter_id> subfolder it uses "default"
  static Future<List<String>> getMatchPicturesUrls(Match match) async {
    var mainFolderRef =
        await FirebaseStorage.instance.ref("sportcenters").listAll();
    var listOfFolders = mainFolderRef.prefixes;

    var folder;
    if (listOfFolders.where((ref) => ref.name == match.sportCenterId).isEmpty) {
      print("no large images found for sportcenter " +
          match.sportCenterId +
          ". Using default");
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
      print("no thumbnail images found for sportcenter " +
          match.sportCenterId +
          ". Using default");
      file = "sportcenters/default/thumbnail.png";
    } else {
      file = "sportcenters/" + match.sportCenterId + "/thumbnail.png";
    }

    var url = await FirebaseStorage.instance.ref(file).getDownloadURL();
    return url;
  }
}
