import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:nutmeg/models/Model.dart';


// todo try to have one change notifier per match rather than one per all the matches
class MatchesModel extends ChangeNotifier {

  var ref = FirebaseFirestore.instance.collection('matches');

  List<Match> matches;

  MatchesModel(this.matches);

  List<Match> getMatches() => matches;

  joinMatch(User user, Match match) {
    DocumentReference documentReference = ref.doc(match.id);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(documentReference);

      if (!snapshot.exists) {
        throw Exception("Match does not exist!");
      }

      Map<String, dynamic> data = snapshot.data();
      List<String> joiningList = List<String>.from(data['joining']);
      if (joiningList.contains(user.uid)) {
        throw Exception("User already joined");
      }

      joiningList.add(user.uid);

      // Perform an update on the document
      transaction.update(documentReference, {'joining': joiningList});
    });
    pull();
    notifyListeners();
  }

  pull() async {
    matches = await _fetchMatches();
    notifyListeners();
  }

  Future<List<Match>> _fetchMatches() async =>
      await ref.get().then((q) => q.docs.map((doc) => Match.fromJson(doc.data(), doc.id)).toList());
}