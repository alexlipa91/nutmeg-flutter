import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'Model.dart';


class UserModel extends ChangeNotifier {

  static CollectionReference users = FirebaseFirestore.instance.collection('users');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<String> getImageUrl(String uid) async {
    return await users.doc(uid).get().then((value) {
      Map<String, dynamic> data = value.data();
      return data['image'].toString();
    });
  }

  User user;
  UserDetails userDetails;

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

      // check if first time
      await users.doc(user.uid).get().then((doc) {
        if (!doc.exists) {
          userDetails = new UserDetails(false, user.photoURL, user.displayName);
        } else {
          userDetails = UserDetails.fromJson(doc.data());
        }
        return !doc.exists;
      }).then((shouldInsert) {
        if (shouldInsert) {
          users.doc(user.uid).set(userDetails.toJson());
        }
      });

      notifyListeners();
      return user.uid;
    }
  }

  bool isLoggedIn() {
    return user != null;
  }

  Future<void> logout() async {
    print("logout");
    var gs = GoogleSignIn();
    gs.disconnect();
    _auth.signOut();
    user = null;
    notifyListeners();
  }
}
