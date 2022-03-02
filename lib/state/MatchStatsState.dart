import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class MatchStatState extends ChangeNotifier {

  final Map<String, double> ratings = Map();
  final Map<String, int> numberOfVotes = Map();

  void setRatings(Map<String, List<int>> ratingsLists) {
    ratingsLists.forEach((key, _) {
      var votesList = (ratingsLists[key] ?? []).where((v) => v > 0);
      numberOfVotes[key] = votesList.length;
      if (votesList.isNotEmpty) {
        ratings[key] = votesList.reduce((a, b) => a + b) / votesList.length;
      }
    });
    notifyListeners();
  }
}
