import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:nutmeg/models/Model.dart';

// todo try to have one change notifier per match rather than one per all the matches
class MatchesModel extends ChangeNotifier {
  var ref = FirebaseFirestore.instance.collection('matches');

  Map<String, Match> matches;

  MatchesModel(this.matches);

  Map<String, Match> getMatches() => matches;

  Map<String, Match> getMatchesByUser(User user) => 
      Map.fromEntries(matches.entries.where((e) => e.value.joining.contains(user.uid)));

  Match getMatch(String id) => matches[id];

  joinMatch(User user, String matchId) async {
    await _alterMatchList(user, matchId, "add");
  }

  leaveMatch(User user, String matchId) async {
    await _alterMatchList(user, matchId, "remove");
  }

  _alterMatchList(User user, String matchId, String op) async {
    print("adding user " + user.uid + " to match " + matchId);
    DocumentReference documentReference = ref.doc(matchId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(documentReference);

      if (!snapshot.exists) {
        throw Exception("Match does not exist!");
      }

      Map<String, dynamic> data = snapshot.data();
      List<String> joiningList = List<String>.from(data['joining']);
      List<String> removedList = data.containsKey('left')
          ? List<String>.from(data['left'])
          : List<String>.empty();

      if (op == "add") {
        joiningList.add(user.uid);
      } else if (op == "remove") {
        joiningList.remove(user.uid);
        removedList.add(user.uid);
      }

      // Perform an update on the document
      transaction.update(documentReference, {'joining': joiningList});
      if (op == "remove") {
        transaction.update(documentReference, {'left': removedList});
      }
    });
    await pull();
  }

  Future<void> pull() async {
    matches = await _fetchMatches();
    notifyListeners();
  }

  Future<Map<String, Match>> _fetchMatches() async {
    var q = await ref.get();
    var entries =
        q.docs.map((doc) => MapEntry(doc.id, Match.fromJson(doc.data())));
    return Map<String, Match>.fromEntries(entries);
  }
}
