import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:nutmeg/models/Model.dart';

// todo try to have one change notifier per match rather than one per all the matches
class MatchesModel extends ChangeNotifier {

  var _ref = FirebaseFirestore.instance.collection('matches').withConverter<Match>(
      fromFirestore: (snapshot, _) => Match.fromJson(snapshot.id, snapshot.data()),
      toFirestore: (match, _) => match.toJson()
  );

  Iterable<Match> _matches;

  Iterable<Match> getMatches() => _matches;

  Match getMatch(String id) => _matches.firstWhere((e) => e.id == id);

  Future<void> update() async {
    _matches = await _fetchMatches();
    notifyListeners();
  }

  Future<Iterable<Match>> _fetchMatches() async =>
      await _ref.get().then((q) => q.docs.map((doc) => doc.data()));
}
