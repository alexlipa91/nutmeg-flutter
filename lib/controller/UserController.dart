import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nutmeg/controller/PromotionController.dart';
import 'package:nutmeg/db/UserFirestore.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/screens/admin/Matches.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

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

        await UserController.saveUserTokensToDb();

        return UserDetails.from(u.uid, existingUserDetails);
      } catch (e) {
        print("Found firebase user but couldn't load details: " + e.toString());
      }
    }
    return null;
  }

  static Future<void> saveUserTokensToDb() async {
    // Get the token each time the application loads
    String token = await FirebaseMessaging.instance.getToken();

    // Save the initial token to the database
    await _saveTokenToDatabase(token);

    // Any time the token refreshes, store this in the database too.
    FirebaseMessaging.instance.onTokenRefresh.listen(_saveTokenToDatabase);
  }

  static Future<AfterLoginCommunication> _login(UserState userState, UserCredential userCredential) async {
    UserDetails userDetails =
        await UserFirestore.getSpecificUserDetails(userCredential.user.uid);

    var afterLoginComm;

    // check if first time
    if (userDetails == null) {
      userDetails = new UserDetails(
          userCredential.user.uid,
          false,
          userCredential.user.photoURL,
          userCredential.user.displayName,
          userCredential.user.email);

      // check if need to give credits todo generalize
      int credits = await PromotionController.giveFreeCreditsAtLogin();
      if (credits > 0) {
        userDetails.creditsInCents = userDetails.creditsInCents + credits;
        afterLoginComm = AfterLoginCommunication();
        afterLoginComm.text = MatchInfo.formatCurrency.format(credits / 100) +
            " were added to your account.\nJoin a match and use them to pay";
      }
      await UserFirestore.storeUserDetails(userDetails);
      await UserController.saveUserTokensToDb();
    }

    userState.setUserDetails(userDetails);
    return afterLoginComm;
  }

  static Future<void> _saveTokenToDatabase(String token) async {
    // Assume user is logged in for this example
    String userId = FirebaseAuth.instance.currentUser.uid;
    if (userId == null) {
      return;
    }

    print("saving token " + token + " for user " + userId);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
      'tokens': FieldValue.arrayUnion([token]),
    });
  }

  static Future<AfterLoginCommunication> continueWithGoogle(
      UserState userState) async {
    FirebaseAuth auth = FirebaseAuth.instance;

    final GoogleSignIn googleSignIn = GoogleSignIn();
    googleSignIn.disconnect();
    final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();

    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    return await _login(userState, await auth.signInWithCredential(credential));
  }

  static Future<AfterLoginCommunication> continueWithFacebook(UserState userState) async {
    // Trigger the sign-in flow
    final LoginResult loginResult = await FacebookAuth.instance.login();

    // Create a credential from the access token
    final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(loginResult.accessToken.token);

    // Once signed in, return the UserCredential
    var userCred = await FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
    return await _login(userState, userCred);
  }

  static Future<void> logout(UserState userState) async {
    await UserFirestore.logout();
    userState.setUserDetails(null);
  }
}

class AfterLoginCommunication {
  String text;
}
