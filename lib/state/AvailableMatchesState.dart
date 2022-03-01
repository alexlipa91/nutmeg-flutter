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
  }

  MatchesSelectionStatus getCurrentSelection() => selected;
}

enum MatchesAdminSelectionStatus {
  UPCOMING,
  PAST
}

class AvailableMatchesAdminUiState extends ChangeNotifier {

  MatchesAdminSelectionStatus selected = MatchesAdminSelectionStatus.UPCOMING;

  void changeTo(MatchesAdminSelectionStatus newSelection) {
    selected = newSelection;
    notifyListeners();
  }

  MatchesAdminSelectionStatus getCurrentSelection() => selected;
}
