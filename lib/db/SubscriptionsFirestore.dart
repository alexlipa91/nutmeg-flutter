import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutmeg/model/Model.dart';


class SubscriptionsDb {

  static Future<CollectionReference<Subscription>> getQuerySnapshot(
      String matchId, String status) async =>
      FirebaseFirestore.instance.collection('matches')
          .doc(matchId)
          .collection(status)
          .withConverter<Subscription>(
        fromFirestore: (snapshot, _) =>
            Subscription.fromJson(snapshot.data()),
        toFirestore: (sub, _) => sub.toJson(),
      );

  static Future<List<Subscription>> getGoing(String matchId) async {
    CollectionReference<Subscription> subscriptionsRef = await getQuerySnapshot(matchId, "going");
    var qs = await subscriptionsRef.get();
    return qs.docs.map((e) => e.data()).toList();
  }
}
