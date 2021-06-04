import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import 'Model.dart';

class SubscriptionsModel extends ChangeNotifier {
  var _ref = FirebaseFirestore.instance
      .collection('subscriptions')
      .withConverter<Subscription>(
          fromFirestore: (snapshot, _) =>
              Subscription.fromJson(snapshot.id, snapshot.data()),
          toFirestore: (subscription, _) => subscription.toJson());

  Iterable<Subscription> _subscriptions;

  Iterable<Subscription> getSubscriptions() => _subscriptions;

  Subscription getSubscription(String id) =>
      _subscriptions.firstWhere((e) => e.id == id);

  Future<void> update() async {
    _subscriptions = await _fetchSubscriptions();
    notifyListeners();
  }

  Future<Iterable<Subscription>> _fetchSubscriptions() async =>
      await _ref.get().then((q) => q.docs.map((doc) => doc.data()));
}
