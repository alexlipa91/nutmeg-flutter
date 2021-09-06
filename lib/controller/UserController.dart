import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nutmeg/db/UserFirestore.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';

class UserController {
  static Future<void> refresh(UserState userState) async {
    var userDetails = await UserFirestore.getSpecificUserDetails(
        userState.getUserDetails().getUid());
    userState.setUserDetails(userDetails);
  }

  static getUserDetails(String id) => UserFirestore.getSpecificUserDetails(id);

  static Future<UserDetails> getUserIfAvailable() async {
    User u = UserFirestore.getCurrentFirestoreUser();

    if (u != null) {
      try {
        var existingUserDetails =
            await UserFirestore.getSpecificUserDetails(u.uid);
        return UserDetails.from(u.uid, existingUserDetails);
      } catch (e) {
        print("Found firebase user but couldn't load details: " + e.toString());
      }
    }
    return null;
  }

  static Future<void> loginWithGoogle(UserState userState) async {
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

      // check if first time
      UserDetails userDetails =
          await UserFirestore.getSpecificUserDetails(userCredential.user.uid);

      if (userDetails != null) {
        userDetails = new UserDetails(
            userCredential.user.uid,
            false,
            userCredential.user.photoURL,
            userCredential.user.displayName,
            userCredential.user.email);
        await UserFirestore.storeUserDetails(userDetails);
      }

      userState.setUserDetails(userDetails);
    }
  }

  static Future<void> logout(UserState userState) async {
    await UserFirestore.logout();
    userState.setUserDetails(null);
  }
}
