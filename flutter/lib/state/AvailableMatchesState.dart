import 'package:flutter/cupertino.dart';

class AvailableMatchesUiState extends ChangeNotifier {

  int current = 0;

  void changeTo(int index) {
    current = index;
    notifyListeners();
  }
}

