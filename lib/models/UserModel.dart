import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User user;

  UserModel();

  Future<void> login(String email, String password) async {
    return _auth
        .signInWithEmailAndPassword(email: email, password: password)
        .then((value) {
          user = value.user;
          notifyListeners();
        });
  }

  Future<String> loginWithGoogle() async {
    FirebaseAuth auth = FirebaseAuth.instance;

    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();

    if (googleSignInAccount != null) {
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      final UserCredential userCredential =
          await auth.signInWithCredential(credential);

      user = userCredential.user;
      notifyListeners();

      return user.uid;
    }
  }

  bool isLoggedIn() {
    return user != null;
  }

  void logout() {
    user = null;
    notifyListeners();
  }
}
