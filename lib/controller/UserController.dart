import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nutmeg/controller/PromotionController.dart';
import 'package:nutmeg/db/UserFirestore.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/screens/admin/Matches.dart';

class UserController {

  static Future<UserDetails> refresh(UserState userState) async {
    var userDetails = await UserFirestore.getSpecificUserDetails(
        userState.getUserDetails().getUid());
    userState.setUserDetails(userDetails);
    return userDetails;
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

  static Future<AfterLoginCommunication> loginWithGoogle(UserState userState) async {
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

      var afterLoginComm;

      if (userDetails == null) {
        userDetails = new UserDetails(userCredential.user.uid, false,
            userCredential.user.photoURL, userCredential.user.displayName, userCredential.user.email);

        // check if need to give credits todo generalize
        int credits = await PromotionController.giveFreeCreditsAtLogin();
        if (credits > 0) {
          userDetails.creditsInCents = userDetails.creditsInCents + credits;
          afterLoginComm = AfterLoginCommunication();
          afterLoginComm.text = MatchInfo.formatCurrency.format(credits / 100) + " were added to your account.\nJoin a match and use them to pay";
        }
        await UserFirestore.storeUserDetails(userDetails);
      }

      print("setting " + userDetails.toString());
      userState.setUserDetails(userDetails);
      return afterLoginComm;
    }
    return null;
  }

  static Future<void> logout(UserState userState) async {
    await UserFirestore.logout();
    userState.setUserDetails(null);
  }
}

class AfterLoginCommunication {
  String text;
}
