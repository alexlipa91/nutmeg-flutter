import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutmeg/model/Model.dart';

// todo try to have one change notifier per match rather than one per all the matches
class SubscriptionsDb  {

  static Future<List<Subscription>> getMatchSubscriptions(String matchId) async {
    var subscriptionsRef = await FirebaseFirestore.instance.collection('matches').doc(matchId).collection("subscriptions").withConverter<Subscription>(
      fromFirestore: (snapshot, _) => Subscription.fromJson(snapshot.data(), snapshot.id),
      toFirestore: (sub, _) => sub.toJson(),
    ).get();

    return subscriptionsRef.docs.map((e) => e.data()).toList();
  }
}
