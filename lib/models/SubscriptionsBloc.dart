import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import 'Model.dart';

class SubscriptionsBloc extends ChangeNotifier {

  var _ref = FirebaseFirestore.instance
      .collection('subscriptions')
      .withConverter<Subscription>(
          fromFirestore: (snapshot, _) =>
              Subscription.fromJson(snapshot.id, snapshot.data()),
          toFirestore: (subscription, _) => subscription.toJson());

  Iterable<Subscription> _subs = Iterable.empty();

  Iterable<Subscription> getSubscriptionsByUser(User user) =>
      _subs.where((e) => e.userId == user.id);

  Future<void> addSubscription(String userId, String matchId) async {
    await _ref.add(new Subscription(matchId, userId, "paymentId"));
    await update();
  }

  Future<void> update() async {
    _subs = await _ref.get().then((q) => q.docs.map((d) => d.data()));
    notifyListeners();
  }

  Iterable<Subscription> getSubscriptions() => _subs;
}
