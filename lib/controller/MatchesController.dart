import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutmeg/controller/SubscriptionsController.dart';
import 'package:nutmeg/db/MatchesFirestore.dart';
import 'package:nutmeg/db/SubscriptionsFirestore.dart';
import 'package:nutmeg/db/UserFirestore.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'UserController.dart';

class MatchesController {

  static Future<Match> refresh(MatchesState matchesState, String matchId) async {
    var match = await getMatch(matchId);
    matchesState.setMatch(match);
    return match;
  }

  static Future<void> refreshAll(MatchesState matchesState) async {
    var matches = await getMatches();
    matchesState.setMatches(matches);
  }

  static Future<void> joinMatch(MatchesState matchesState, String matchId,
      UserState userState, PaymentRecap paymentStatus) async {
    await UserController.refresh(userState);
    await refresh(matchesState, matchId);

    var userDetails = userState.getUserDetails();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      var currentUserSub =
          await SubscriptionsController.getMatchSubscriptionsLatestStatePerUser(
              userDetails.getUid(), matchId);

      if (currentUserSub != null &&
          currentUserSub.status == SubscriptionStatus.going) {
        throw new Exception("Already going");
      } else {
        var sub = new Subscription(
            userDetails.getUid(),
            SubscriptionStatus.going,
            paymentStatus.finalPriceToPayInCents(),
            paymentStatus.creditsInCentsUsed,
            0);
        await SubscriptionsDb.addSubscription(matchId, sub);
      }

      if (paymentStatus.creditsInCentsUsed > 0) {
        userDetails.creditsInCents =
            userDetails.creditsInCents - paymentStatus.creditsInCentsUsed;
      }
      await UserFirestore.storeUserDetails(userDetails);
    });

    await UserController.refresh(userState);
    await refresh(matchesState, matchId);
  }

  static leaveMatch(
      MatchesState matchesState, String matchId, UserState userState) async {
    await UserController.refresh(userState);
    await refresh(matchesState, matchId);

    var userDetails = userState.getUserDetails();
    var match = matchesState.getMatch(matchId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      var issueRefund = match.dateTime.difference(DateTime.now()).inHours >= 24;
      var currentUserSub =
          await SubscriptionsController.getMatchSubscriptionsLatestStatePerUser(
              userDetails.getUid(), matchId);

      var newSub;
      if (currentUserSub.status != SubscriptionStatus.going) {
        throw new Exception("Already not going");
      } else {
        var refundInCents = (issueRefund) ? match.pricePerPersonInCents : 0;

        newSub = new Subscription(
            userDetails.getUid(),
            (refundInCents == 0)
                ? SubscriptionStatus.canceled
                : SubscriptionStatus.refunded,
            0,
            0,
            refundInCents);

        if (refundInCents != 0) {
          userDetails.creditsInCents =
              userDetails.creditsInCents + refundInCents;
        }
      }

      // update db
      await UserFirestore.storeUserDetails(userDetails);
      await SubscriptionsDb.addSubscription(matchId, newSub);
    });

    // refresh state
    await UserController.refresh(userState);
    await refresh(matchesState, matchId);
  }

  static Future<Match> getMatch(String matchId) async {
    var match = await MatchesFirestore.fetchMatch(matchId);
    match.subscriptions =
        await SubscriptionsController.getMatchSubscriptionsLatestState(matchId) ??
            [];
    return match;
  }

  static Future<List<Match>> getMatches() async {
    var ids = await MatchesFirestore.fetchMatchesId();

    // add subs
    var addSubsFutures = ids.map((m) => getMatch(m));
    return await Future.wait(addSubsFutures);
  }

  static int numPlayedByUser(MatchesState matchesState, String userId) =>
      matchesState.getMatches()
          .where((m) =>
              !m.wasCancelled() &&
              m.subscriptions
                  .where((sub) =>
                      sub.status == SubscriptionStatus.going &&
                      sub.userId == userId)
                  .isNotEmpty)
          .length;

  static Future<void> cancelMatch(MatchesState matchesState, String matchId) async {
    var match = matchesState.getMatch(matchId);
    match.cancelledAt = Timestamp.fromDate(DateTime.now());
    await MatchesFirestore.editMatch(match);
    matchesState.setMatch(await getMatch(matchId));
  }

  // it loads all pictures from the sportcenter in folder sportcenters/<sportcenter_id>/large
  // if no <sportcenter_id> subfolder it uses "default"
  static Future<List<String>> getMatchPicturesUrls(Match match) async {
    var mainFolderRef = await FirebaseStorage.instance.ref("sportcenters").listAll();
    var listOfFolders = mainFolderRef.prefixes;

    var folder;
    if (listOfFolders.where((ref) => ref.name == match.sportCenter).isEmpty) {
      print("no large images found for sportcenter " + match.sportCenter + ". Using default");
      folder = "default";
    } else {
      folder = match.sportCenter;
    }

    var allRefs = await FirebaseStorage.instance.ref("sportcenters/" + folder + "/large").listAll();
    var urls = await Future.wait(allRefs.items.map((e) => e.getDownloadURL()));
    return urls;
  }

  // it loads the thumbnail picture from the sportcenter at sportcenters/<sportcenter_id>/thumbnail.png
  // if no <sportcenter_id> subfolder it uses "default"
  static Future<String> getMatchThumbnailUrl(Match match) async {
    var listOfFiles = await FirebaseStorage.instance.ref("sportcenters/").listAll();

    var file;
    if (listOfFiles.prefixes.where((ref) => ref.name == match.sportCenter).isEmpty) {
      print("no thumbnail images found for sportcenter " + match.sportCenter + ". Using default");
      file = "sportcenters/default/thumbnail.png";
    } else {
      file = "sportcenters/" + match.sportCenter + "/thumbnail.png";
    }

    var url = await FirebaseStorage.instance.ref(file).getDownloadURL();
    return url;
  }
}
