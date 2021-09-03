import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutmeg/db/SubscriptionsFirestore.dart';
import 'package:nutmeg/model/Model.dart';


class MatchesFirestore {

  static var _ref = FirebaseFirestore.instance.collection('matches').withConverter<Match>(
    fromFirestore: (snapshot, _) => Match.fromJson(snapshot.data(), snapshot.id),
    toFirestore: (match, _) => match.toJson(),
  );

  static Future<List<Match>> fetchMatches() async {
    var querySnapshot = await _ref.get();
    return await Future.wait(querySnapshot.docs.map((doc) => _createMatchObject(doc)));
  }

  static Future<Match> fetchMatch(Match m) async {
    var d = await _ref.doc(m.documentId).get();
    return d.data();
  }

  static Future<Match> _createMatchObject(DocumentSnapshot<Match> doc) async {
    var match = doc.data();
    match.subscriptions = await SubscriptionsDb.getMatchSubscriptionsLatestState(match.documentId) ?? [];
    return match;
  }

  static Future<String> addMatch(Match m) async {
    var doc = await _ref.add(m);
    return doc.id;
  }

  static Future<void> editMatch(Match m) async {
    await _ref.doc(m.documentId).set(m);
  }
}
