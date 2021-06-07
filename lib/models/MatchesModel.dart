import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:nutmeg/models/Model.dart';


class MatchesModel extends ChangeNotifier {

  var _ref = FirebaseFirestore.instance
      .collection('matches')
      .withConverter<Match>(
          fromFirestore: (snapshot, _) =>
              Match.fromJson(snapshot.id, snapshot.data()),
          toFirestore: (match, _) => match.toJson());

  Iterable<Match> _matches = Iterable.empty();

  Iterable<Match> getMatches() => _matches;


  Match getMatch(String matchId) => _matches.firstWhere((e) => e.id == matchId);

  Future<void> update() async {
    _matches = await _ref.get().then((q) => q.docs.map((d) => d.data()));
    notifyListeners();
  }
}
