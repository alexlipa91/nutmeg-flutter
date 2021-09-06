import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutmeg/model/Model.dart';


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

  static Future<List<Subscription>> getMatchSubscriptionsLogPerUser(
      String matchId, String userId) async {
    CollectionReference<Subscription> subscriptionsRef = await getQuerySnapshot(matchId);
    var qs = await subscriptionsRef.where('userId', isEqualTo: userId).get();
    return qs.docs.map((e) => e.data()).toList();
  }

  static Future<void> addSubscription(String matchId, Subscription s) async {
    var ref = await getQuerySnapshot(matchId);
    await ref.add(s);
  }
}
