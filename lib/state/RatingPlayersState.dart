import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../model/MatchRatings.dart';


class RatingPlayersState extends ChangeNotifier {

  final List<String> toRate;

  int current = 0;
  double currentScore = -1;
  Set<Skills> selectedSkills = Set.of([]);

  RatingPlayersState(this.toRate);

  String getCurrent() => toRate[current];

  double getCurrentScore() => currentScore;

  bool isLast() => current + 1 == toRate.length;

  void next() {
    if (current + 1 < toRate.length) {
      current++;
    }
    currentScore = -1;
    selectedSkills = Set.of([]);
    notifyListeners();
  }

  void setCurrentScore(double score) {
    currentScore = score;
    notifyListeners();
  }

  void selectSkill(Skills s) {
    selectedSkills.add(s);
    notifyListeners();
  }

  void unselectSkill(Skills s) {
    selectedSkills.remove(s);
    notifyListeners();
  }
}

class RatingPlayersMultiState extends ChangeNotifier {

  final List<String> toRate;
  final List<int> scores;

  RatingPlayersMultiState(this.toRate) :
    scores = List<int>.filled(toRate.length, -1);

  int getCurrentScore(int i) => scores[i];

  void setScore(int i, int score) {
    scores[i] = score;
    notifyListeners();
  }

  Map<String, int> getScored() {
    var m = {};
    toRate.asMap().keys.forEach((i) {
      m[toRate[i]] = scores[i];
    });
    return Map<String, int>.from(m);
  }
}
