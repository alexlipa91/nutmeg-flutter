import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutmeg/db/SubscriptionsFirestore.dart';
import 'package:nutmeg/model/Model.dart';


class MatchesFirestore {

  static var _ref = FirebaseFirestore.instance.collection('matches').withConverter<Match>(
    fromFirestore: (snapshot, _) => Match.fromJson(snapshot.data(), snapshot.id),
    toFirestore: (match, _) => match.toJson(),
  );

  static Future<List<String>> fetchMatchesId() async {
    var querySnapshot = await _ref.get();
    return querySnapshot.docs.map((e) => e.id).toList();
  }

  static Future<Match> fetchMatch(String matchId) async {
    var d = await _ref.doc(matchId).get();
    return d.data();
  }

  static Future<String> addMatch(Match m) async {
    var doc = await _ref.add(m);
    return doc.id;
  }

  static Future<void> editMatch(Match m) async {
    await _ref.doc(m.documentId).set(m);
  }
}
