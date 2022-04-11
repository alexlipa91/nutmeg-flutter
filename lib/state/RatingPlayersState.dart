import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class RatingPlayersState extends ChangeNotifier {

  final List<String> toRate;

  int current = 0;
  double currentScore = -1;

  RatingPlayersState(this.toRate);

  String getCurrent() => toRate[current];

  double getCurrentScore() => currentScore;

  bool isLast() => current + 1 == toRate.length;

  void next() {
    if (current + 1 < toRate.length) {
      current++;
    }
    currentScore = -1;
    notifyListeners();
  }

  void setCurrentScore(double score) {
    currentScore = score;
    notifyListeners();
  }
}
