import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../router/AppRouter.dart';

class AppState extends ChangeNotifier {

  bool loadingDone = false;
  NutmegPage page;
  String selectedMatch;

  void setSelectedMatch(String matchId) {
   selectedMatch = matchId;
   notifyListeners();
  }

  void setLoadingDone() {
    loadingDone = true;
    notifyListeners();
  }

  void setPage(NutmegPage p) {
    print("setting page to $p");
    page = p;
    notifyListeners();
  }

  @override
  String toString() {
    return 'AppState{loadingDone: $loadingDone, page: $page, selectedMatch: $selectedMatch}';
  }
}
