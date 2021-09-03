import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../model/Model.dart';


class UserFirestore {

  static CollectionReference users = FirebaseFirestore.instance.collection('users');
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<UserDetails> getSpecificUserDetails(String uid) async {
    var doc = await users.doc(uid).get();
    Map<String, dynamic> data = doc.data();
    return UserDetails.fromJson(data, uid);
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
      var doc = await users.doc(userCredential.user.uid).get();

      if (!doc.exists) {
        userDetails = new UserDetails(userCredential.user.uid, false, userCredential.user.photoURL, userCredential.user.displayName, userCredential.user.email);
        await storeUserDetails(userDetails);
      } else {
        userDetails = UserDetails.fromJson(doc.data(), userCredential.user.uid);
      }

      return userDetails;
    }
  }

  static Future<void> storeUserDetails(UserDetails userDetails) =>
      users.doc(userDetails.documentId).set(userDetails.toJson());

  static Future<void> logout() async {
    var gs = GoogleSignIn();
    await gs.disconnect();
    await _auth.signOut();
  }

  static storeStripeId(String uid, String stripeId) async =>
      await users.doc(uid).update({"stripeId": stripeId});

  static User getCurrentFirestoreUser() => _auth.currentUser;
}
