import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:nutmeg/model/UserDetails.dart';


class RatingPlayersState extends ChangeNotifier {

  final List<UserDetails> toRate;

  int current = 0;
  double currentScore = -1;

  RatingPlayersState(this.toRate);

  UserDetails getCurrent() => toRate[current];

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
    print(currentScore);
    notifyListeners();
  }
}