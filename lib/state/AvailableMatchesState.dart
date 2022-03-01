import 'package:flutter/cupertino.dart';


enum MatchesSelectionStatus {
  ALL,
  MY_GAMES
}

class AvailableMatchesUiState extends ChangeNotifier {

  MatchesSelectionStatus selected = MatchesSelectionStatus.ALL;

  void changeTo(MatchesSelectionStatus newSelection) {
    selected = newSelection;
    notifyListeners();
    print("changing");
  }

  MatchesSelectionStatus getCurrentSelection() => selected;
}
