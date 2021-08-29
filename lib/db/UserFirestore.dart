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
      var doc = await users.doc(userCredential.user.uid).get();

      if (!doc.exists) {
        userDetails = new UserDetails(userCredential.user, false, userCredential.user.photoURL, userCredential.user.displayName);
        await storeUserDetails(userDetails);
      } else {
        userDetails = UserDetails.fromJson(doc.data(), userCredential.user);
      }

      return userDetails;
    }
  }

  static Future<void> storeUserDetails(UserDetails userDetails) =>
      users.doc(userDetails.firebaseUser.uid).set(userDetails.toJson());

  static Future<void> logout() async {
    var gs = GoogleSignIn();
    await gs.disconnect();
    await _auth.signOut();
  }

  static storeStripeId(String uid, String stripeId) async =>
      await users.doc(uid).update({"stripeId": stripeId});

  static User getCurrentFirestoreUser() => _auth.currentUser;
}
