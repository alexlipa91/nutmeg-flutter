import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../model/Model.dart';


class UserFirestore {

  static CollectionReference users = FirebaseFirestore.instance.collection('users');
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<UserDetails> getSpecificUserDetails(String uid) async {
    return await users.doc(uid).get().then((value) {
      Map<String, dynamic> data = value.data();
      return UserDetails.fromJson(data, null);
    });
  }

  static Future<User> login(String email, String password) async {
    return _auth
        .signInWithEmailAndPassword(email: email, password: password)
        .then((value) => value.user);
  }

  static Future<UserDetails> loginWithGoogle() async {
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

      var userDetails;

      // check if first time
      await users.doc(userCredential.user.uid).get().then((doc) {
        if (!doc.exists) {
          userDetails = new UserDetails(userCredential.user, false, userCredential.user.photoURL, userCredential.user.displayName);
        } else {
          userDetails = UserDetails.fromJson(doc.data(), userCredential.user);
        }
        return !doc.exists;
      }).then((shouldInsert) {
        if (shouldInsert) {
          users.doc(userCredential.user.uid).set(userDetails.toJson());
        }
      });

      return userDetails;
    }
  }

  static Future<void> logout() async {
    var gs = GoogleSignIn();
    await gs.disconnect();
    await _auth.signOut();
  }

  static storeStripeId(String uid, String stripeId) async =>
      await users.doc(uid).update({"stripeId": stripeId});
}
