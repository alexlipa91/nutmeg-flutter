import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {

  bool _loadingDone = false;
  String _selectedMatch;

  bool get loadingDone => _loadingDone;
  String get selectedMatch => _selectedMatch;

  void setSelectedMatch(String matchId) {
   _selectedMatch = matchId;
   print("notifying");
   notifyListeners();
  }

  void setLoadingDone() {
    _loadingDone = true;
    notifyListeners();
  }
}
