import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutmeg/db/SubscriptionsFirestore.dart';
import 'package:nutmeg/model/Model.dart';


class MatchesFirestore {

  static var _ref = FirebaseFirestore.instance.collection('matches').withConverter<Match>(
    fromFirestore: (snapshot, _) => Match.fromJson(snapshot.data(), snapshot.id),
    toFirestore: (match, _) => match.toJson(),
  );

  static Future<void> editMatch(Match m) async {
    await _ref.doc(m.documentId).set(m);
  }
}
