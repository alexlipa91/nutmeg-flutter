import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutmeg/screens/EnterDetails.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../api/CloudFunctionsUtils.dart';
import '../model/UserDetails.dart';
import '../screens/PlayerOfTheMatch.dart';
import '../state/MatchesState.dart';
import '../state/UserState.dart';
import '../utils/UiUtils.dart';

class UserController {
  static var apiClient = CloudFunctionsClient();

  static Future<void> editUser(BuildContext context, UserDetails u) async {
    await apiClient
        .callFunction("edit_user", {"id": u.documentId, "data": u.toJson()});
    context.read<UserState>().setUserDetail(u);
  }

  static Future<void> addUser(UserDetails u) async => await apiClient
      .callFunction("add_user", {"id": u.documentId, "data": u.toJson()});

  static Future<void> _login(
      BuildContext context, UserCredential userCredential) async {
    var userState = context.read<UserState>();

    var uid = userCredential.user?.uid;

    UserDetails? userDetails = await context.read<UserState>()
        .fetchUserDetails(uid!);

    // check if first time
    if (userDetails == null) {
      userDetails = new UserDetails(
          uid,
          false,
          userCredential.user?.photoURL,
          userCredential.user?.displayName,
          userCredential.user?.email);

      if (userDetails.name == null || userDetails.name == "") {
        var name = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => EnterDetails()));
        if (name == null || name == "") {
          // Navigator.pop(context);
          return null;
        } else {
          userDetails.name = name;
        }
      }

      await addUser(userDetails);
    }

    userState.setCurrentUserDetails(userDetails);
    userState.storeUserToken(await FirebaseMessaging.instance.getToken());
    FirebaseMessaging.instance.onTokenRefresh.listen((t) =>
        userState.storeUserToken(t));

    await context.read<MatchesState>().refreshState(context);
  }

  static Future<void> continueWithGoogle(
      BuildContext context) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    var userCredentials;

    if (kIsWeb) {
      userCredentials = await auth.signInWithPopup(GoogleAuthProvider());
    } else {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      googleSignIn.disconnect();
      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();

      final GoogleSignInAuthentication? googleSignInAuthentication =
      await googleSignInAccount?.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication?.accessToken,
        idToken: googleSignInAuthentication?.idToken,
      );
      userCredentials = await auth.signInWithCredential(credential);
    }
    await _login(context, userCredentials);
  }

  static Future<void> continueWithFacebook(
      BuildContext context) async {
    var userCred;

    if (kIsWeb) {
      // Create a new provider
      FacebookAuthProvider facebookProvider = FacebookAuthProvider();

      facebookProvider.addScope('email');
      facebookProvider.setCustomParameters({
        'display': 'popup',
      });

      // Once signed in, return the UserCredential
      userCred = await FirebaseAuth.instance.signInWithPopup(facebookProvider);
    } else {
      // Trigger the sign-in flow
      final LoginResult loginResult = await FacebookAuth.instance.login();

      // Create a credential from the access token
      final OAuthCredential facebookAuthCredential = FacebookAuthProvider
          .credential(loginResult.accessToken?.token ?? "");

      // Once signed in, return the UserCredential
      userCred = await FirebaseAuth.instance
          .signInWithCredential(facebookAuthCredential);
    }
    await _login(context, userCred);
  }

  static Future<void> continueWithApple(
      BuildContext context) async {
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

    return _login(context, userCredential);
  }

  static Future<void> logout(UserState userState) async {
    await FirebaseAuth.instance.signOut();
    userState.logout();
  }

  // how many users 'the current logged-in user' needs to still rate in match 'matchId'
  static Future<List<String>> getUsersToRateInMatchForLoggedUser(
      BuildContext context, String matchId) async {
    var userId = context.read<UserState>().currentUserId;

    var resp = await apiClient.callFunction(
        "get_users_to_rate", {"match_id": matchId, "user_id": userId});

    List<String> users = List<String>.from([]);
    resp?.values.first.forEach((r) {
      users.add(r);
    });

    return users;
  }

  static Future<void> updloadPicture(
      BuildContext context, UserDetails userDetails) async {
    var original = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (original == null) return;
    File? croppedFile = await ImageCropper().cropImage(
        maxHeight: 512,
        maxWidth: 512,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        sourcePath: original.path,
        aspectRatioPresets: [CropAspectRatioPreset.square],
        androidUiSettings: AndroidUiSettings(
            toolbarColor: Palette.primary,
            toolbarWidgetColor: Palette.grey_light,
            initAspectRatio: CropAspectRatioPreset.original,
            activeControlsWidgetColor: Palette.primary,
            lockAspectRatio: true),
        iosUiSettings: IOSUiSettings(
          minimumAspectRatio: 1.0,
        ));
    if (croppedFile == null) return;
    var uploaded = await FirebaseStorage.instance
        .ref("users/" + userDetails.documentId)
        .putFile(croppedFile);
    print(await uploaded.ref.getDownloadURL());
    userDetails.image = await uploaded.ref.getDownloadURL();
    await UserController.editUser(context, userDetails);
  }

  static Future<void> showPotmIfNotSeen(BuildContext context,
      String matchId, String userId) async {
    var prefs = await SharedPreferences.getInstance();
    var preferencePath = "potm_screen_showed_" + matchId + "_" + userId;
    var seen = prefs.getBool(preferencePath) ?? false;

    if (!seen) {
      await Navigator.push(context,
          MaterialPageRoute(builder: (context) => PlayerOfTheMatch()));
      prefs.setBool(preferencePath, true);
    }
  }
}

