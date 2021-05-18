import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class UserModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User user;

  UserModel();

  Future<String> login(String email, String password) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password)
        .then((value) => value.user.uid);
  }

  bool isLoggedIn() {
    return user != null;
  }

  void logout() {
    // user = null;
    // notifyListeners();
  }
}
