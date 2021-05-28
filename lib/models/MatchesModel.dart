import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:nutmeg/models/Model.dart';


class MatchesModel extends ChangeNotifier {

  var ref = FirebaseFirestore.instance.collection('matches');

  List<Match> matches;

  MatchesModel(this.matches);

  joinMatch(String user, Match match) {
    match.joining.add(user);
    notifyListeners();
  }

  pull() async {
    matches = await fetchMatches();
    notifyListeners();
  }

  Future<List<Match>> fetchMatches() async =>
      await ref.get().then((q) => q.docs.map((doc) => Match.fromJson(doc.data(), doc.id)).toList());
}