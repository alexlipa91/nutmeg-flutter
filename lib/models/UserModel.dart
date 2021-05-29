import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserModel extends ChangeNotifier {
  final CollectionReference users = FirebaseFirestore.instance.collection('users');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User user;
  bool isAdmin = false;

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
    googleSignIn.disconnect();
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
      await getUserMetadata();

      notifyListeners();
      return user.uid;
    }
  }

  Future<void> getUserMetadata() {
    users.doc(user.uid).get().then((doc) {
      if (doc.exists) {
        Map<String, dynamic> metadata = doc.data();
        if (metadata.containsKey("isAdmin")) {
          isAdmin = metadata["isAdmin"];
        } else {
          isAdmin = false;
        }
      } else {
        isAdmin = false;
      }
    });
  }

  bool isLoggedIn() {
    return user != null;
  }

  Future<void> logout() async {
    var gs = GoogleSignIn();
    gs.disconnect();
    _auth.signOut();
    user = null;
    notifyListeners();
  }
}
