import 'package:flutter/cupertino.dart';


class LoginStatusChangeNotifier extends ChangeNotifier {
  bool _isSigningIn = false;

  bool get isSigningIn => _isSigningIn;

  void setIsSigningIn(bool value) {
    _isSigningIn = value;
    notifyListeners();
  }
}
