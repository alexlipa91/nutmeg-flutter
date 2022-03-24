import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class MatchStatState extends ChangeNotifier {

  final Map<String, double> ratings = Map();
  final Map<String, int> numberOfVotes = Map();
  final Map<String, int> numberOfSkips = Map();

  void setRatings(List<String> usersGoing, Map<String, List<int>> ratingsLists) {
    usersGoing.forEach((user) {
      numberOfSkips[user] = (ratingsLists[user] ?? []).where((v) => v < 0).length;
      var votesList = (ratingsLists[user] ?? []).where((v) => v > 0);
      numberOfVotes[user] = votesList.length;
      if (votesList.isNotEmpty) {
        ratings[user] = votesList.reduce((a, b) => a + b) / votesList.length;
      } else {
        ratings[user] = 0;
      }
    });
    notifyListeners();
  }
}
