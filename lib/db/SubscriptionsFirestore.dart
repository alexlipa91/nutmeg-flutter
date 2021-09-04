import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutmeg/model/Model.dart';
import "package:collection/collection.dart";


class SubscriptionsDb {

  static Future<CollectionReference<Subscription>> getQuerySnapshot(
      String matchId) async =>
      FirebaseFirestore.instance.collection('matches')
          .doc(matchId)
          .collection("subscriptions")
          .withConverter<Subscription>(
        fromFirestore: (snapshot, _) =>
            Subscription.fromJson(snapshot.data(), snapshot.id),
        toFirestore: (sub, _) => sub.toJson(),
      );

  static Future<List<Subscription>> getMatchSubscriptionsLog(
      String matchId) async {
    CollectionReference<Subscription> subscriptionsRef = await getQuerySnapshot(matchId);
    var qs = await subscriptionsRef.get();
    return qs.docs.map((e) => e.data()).toList();
  }

  static Future<List<Subscription>> getMatchSubscriptionsLatestState(String matchId) async {
    List<Subscription> log = await getMatchSubscriptionsLog(matchId);
    if (log.isEmpty) {
      return [];
    }
    return log.groupListsBy((s) => s.userId).values.map((subs) => subs.reduce((a, b) => (a.createdAt.compareTo(b.createdAt) > 0) ? a : b)).toList();
  }

  static Future<Subscription> getMatchSubscriptionsLatestStatePerUser(
      UserDetails userDetails, String matchId) async {
    List<Subscription> latestStates = await getMatchSubscriptionsLatestState(matchId);
    var latestStateFilter = latestStates.where((s) => s.userId == userDetails.getUid());
    if (latestStateFilter.isEmpty) {
      return null;
    }
    return latestStateFilter.first;
  }

  static Future<void> addSubscription(String matchId, Subscription s) async {
    var ref = await getQuerySnapshot(matchId);
    await ref.add(s);
  }
}
