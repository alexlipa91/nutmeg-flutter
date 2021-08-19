import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/db//SubscriptionsFirestore.dart';

// todo try to have one change notifier per match rather than one per all the matches
class MatchesFirestore {

  static var _ref = FirebaseFirestore.instance.collection('matches').withConverter<Match>(
    fromFirestore: (snapshot, _) => Match.fromJson(snapshot.data(), snapshot.id),
    toFirestore: (match, _) => match.toJson(),
  );

  static Future<Match> joinMatch(UserDetails user, Match match) async {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      var subscriptionsRef = _ref.doc(match.documentId).collection("subscriptions").withConverter<Subscription>(
        fromFirestore: (snapshot, _) => Subscription.fromJson(snapshot.data(), snapshot.id),
        toFirestore: (sub, _) => sub.toJson(),
      );

      var subsQuerySnapshot = await subscriptionsRef.get();
      var subs = subsQuerySnapshot.docs.map((e) => e.data());
      
      if (subs.where((s) => s.userId == user.getUid() && s.status == SubscriptionStatus.going).isNotEmpty) {
        throw new Exception("Already going");
      }

      subscriptionsRef.add(new Subscription(user.getUid(), SubscriptionStatus.going));
    });

    return await _ref.doc(match.documentId).get().then((value) => value.data());
  }

  static Future<Match> leaveMatch(UserDetails user, Match match) async {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      var subscriptionsRef = _ref.doc(match.documentId).collection("subscriptions").withConverter<Subscription>(
        fromFirestore: (snapshot, _) => Subscription.fromJson(snapshot.data(), snapshot.id),
        toFirestore: (match, _) => match.toJson(),
      );

      var subsQuerySnapshot = await subscriptionsRef.get();
      var subs = subsQuerySnapshot.docs.map((e) => e.data());

      var currentSub = subs.where((s) => s.userId == user.getUid() && s.status == SubscriptionStatus.going);
      
      if (currentSub.isEmpty) {
        throw new Exception("Cannot remove since not going");
      }

      subscriptionsRef.doc(currentSub.first.documentId).set(new Subscription(user.getUid(), SubscriptionStatus.canceled));
    });

    return await _ref.doc(match.documentId).get().then((value) => value.data());
  }

  static Future<List<Match>> fetchMatches() async {
    var querySnapshot = await _ref.get();
    return await Future.wait(querySnapshot.docs.map((doc) => _createMatchObject(doc)));
  }

  static Future<Match> fetchMatch(Match m) async =>
      await _ref.doc(m.documentId).get().then((value) => value.data());

  static Future<Match> _createMatchObject(DocumentSnapshot<Match> doc) async {
    var match = doc.data();
    match.subscriptions = await SubscriptionsDb.getMatchSubscriptions(match.documentId) ?? [];
    return match;
  }
}
