import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'Model.dart';

class UserModel extends ChangeNotifier {

  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  User _user;

  User getUser() => _user;

  // Future<void> loginWithEmail(String email, String password) async {
  //   return _auth
  //       .signInWithEmailAndPassword(email: email, password: password)
  //       .then((value) {
  //     user = value.user;
  //     notifyListeners();
  //   });
  // }

  Future<void> loginWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    googleSignIn.disconnect();
    final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();

    if (googleSignInAccount != null) {
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final firebase_auth.AuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      final firebase_auth.UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      firebase_auth.User firebaseUser = userCredential.user;

      // check if first time
      await users.doc(firebaseUser.uid).get().then((doc) {
        if (!doc.exists) {
          _user = new User(firebaseUser, false);
        } else {
          _user = User.fromJson(firebaseUser.uid, doc.data());
        }
        return !doc.exists;
      }).then((shouldInsert) {
        if (shouldInsert) {
          users.doc(_user.id).set(_user.toJson());
        }
      });

      notifyListeners();
    }
  }

  bool isLoggedIn() => _user != null;

  Future<void> logout() async {
    var gs = GoogleSignIn();
    gs.disconnect();
    _auth.signOut();
    _user = null;
    notifyListeners();
  }

  String getUserId() => (_user == null) ? null : _user.id;
}
