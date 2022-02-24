import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nutmeg/controller/CloudFunctionsUtils.dart';
import 'package:nutmeg/controller/PromotionController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class UserController {
  static Future<UserDetails> refreshCurrentUser(UserState userState) async {
    var userDetails = await getUserDetails(userState.getUserDetails().getUid());
    userState.setUserDetails(userDetails);
    return userDetails;
  }

  static Future<UserDetails> getUserIfAvailable() async {
    User u = FirebaseAuth.instance.currentUser;

    if (u != null) {
      try {
        var userId = u.uid;

        var existingUserDetails = await getUserDetails(userId);

        if (existingUserDetails == null) {
          return null;
        }

        return UserDetails.from(userId, existingUserDetails);
      } catch (e, stack) {
        print("Found firebase user but couldn't load details: " + e.toString());
        print(stack);
      }
    }
    return null;
  }

  static Future<void> editUser(UserDetails u) async =>
      await CloudFunctionsUtils.callFunction(
          "edit_user", {"id": u.documentId, "data": u.toJson()});

  static Future<void> addUser(UserDetails u) async =>
      await CloudFunctionsUtils.callFunction("add_user", {
        "id": u.documentId,
        "data": u.toJson()});

  static Future<void> saveUserTokensToDb(UserDetails userDetails) async {
    // Get the token each time the application loads
    String token = await FirebaseMessaging.instance.getToken();

    // Save the initial token to the database
    await CloudFunctionsUtils.callFunction("store_user_token",
        {"id": userDetails.getUid(), "token": token});

    // Any time the token refreshes, store this in the database too.
    FirebaseMessaging.instance.onTokenRefresh.listen(_saveTokenToDatabase);
  }

  static Future<AfterLoginCommunication> _login(
      UserState userState, UserCredential userCredential) async {
    var uid = userCredential.user.uid;

    UserDetails userDetails = await getUserDetails(uid);

    var afterLoginComm;

    // check if first time
    if (userDetails == null) {
      userDetails = new UserDetails(uid, false, userCredential.user.photoURL,
          userCredential.user.displayName, userCredential.user.email);

      // check if need to give credits todo generalize
      int credits = await PromotionController.giveFreeCreditsAtLogin();
      if (credits > 0) {
        userDetails.creditsInCents = userDetails.creditsInCents + credits;
        afterLoginComm = AfterLoginCommunication();
        afterLoginComm.text = formatCurrency(credits) +
            " were added to your account.\nJoin a match and use them to pay";
      }
      await addUser(userDetails);
    }

    userState.setUserDetails(userDetails);
    await UserController.saveUserTokensToDb(userDetails);
    return afterLoginComm;
  }

  static Future<void> _saveTokenToDatabase(String token) async {
    // Assume user is logged in for this example
    String userId = FirebaseAuth.instance.currentUser.uid;
    if (userId == null) {
      return;
    }

    print("saving token " + token + " for user " + userId);
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
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

  static Future<AfterLoginCommunication> continueWithFacebook(
      UserState userState) async {
    // Trigger the sign-in flow
    final LoginResult loginResult = await FacebookAuth.instance.login();

    // Create a credential from the access token
    final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(loginResult.accessToken.token);

    // Once signed in, return the UserCredential
    var userCred = await FirebaseAuth.instance
        .signInWithCredential(facebookAuthCredential);
    return await _login(userState, userCred);
  }

  static Future<AfterLoginCommunication> continueWithApple(
      UserState userState) async {
    // To prevent replay attacks with the credential returned from Apple, we
    // include a nonce in the credential request. When signing in in with
    // Firebase, the nonce in the id token returned by Apple, is expected to
    // match the sha256 hash of `rawNonce`.
    // final rawNonce = generateNonce();
    // final nonce = sha256ofString(rawNonce);

    // Request credential for the currently signed in Apple account.
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      // nonce: nonce,
    );

    // Create an `OAuthCredential` from the credential returned by Apple.
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      // rawNonce: rawNonce,
    );

    // Sign in the user with Firebase. If the nonce we generated earlier does
    // not match the nonce in `appleCredential.identityToken`, sign in will fail.
    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(oauthCredential);

    return _login(userState, userCredential);
  }

  static Future<UserDetails> getUserDetails(String uid) async {
    var resp = await CloudFunctionsUtils.callFunction("get_user", {"id": uid});

    if (resp == null) {
      return null;
    }

    return UserDetails.fromJson(resp, uid);
  }

  static Future<void> logout(UserState userState) async {
    await FirebaseAuth.instance.signOut();
    userState.setUserDetails(null);
  }
}

class AfterLoginCommunication {
  String text;
}
