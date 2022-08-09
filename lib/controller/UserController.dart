import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../api/CloudFunctionsUtils.dart';
import '../model/UserDetails.dart';
import '../state/UserState.dart';
import '../utils/UiUtils.dart';

class UserController {
  static var apiClient = CloudFunctionsClient();

  static Future<UserDetails> initLoggedUser(BuildContext context, String uid) async {
    var userState = context.read<UserState>();
    userState.currentUserId = uid;
    return await refreshLoggedUser(context);
  }

  // this should be called for logged in user only
  static Future<UserDetails> refreshLoggedUser(BuildContext? context) async {
    var userState = context?.read<UserState>();

    // todo refactor this, we set user details in state twice
    var userDetails = await getUserDetails(context!, userState?.currentUserId);
    userState?.setCurrentUserDetails(userDetails);

    return userDetails;
  }

  static Future<UserDetails?> getUserIfAvailable(BuildContext context) async {
    User? u = await FirebaseAuth.instance.authStateChanges().first;

    UserDetails? ud;

    if (u != null) {
      var uid = u.uid;
      try {
        var existingUserDetails = await initLoggedUser(context, uid);
        ud = UserDetails.from(uid, existingUserDetails);
      } catch (e, stack) {
        print("Found firebase user but couldn't load details: " + e.toString());
        print(stack);
      }
    }

    return ud;
  }

  static Future<void> editUser(BuildContext context, UserDetails u) async {
    await apiClient
        .callFunction("edit_user", {"id": u.documentId, "data": u.toJson()});
    context.read<UserState>().setUserDetail(u);
  }

  static Future<void> addUser(UserDetails u) async => await apiClient
      .callFunction("add_user", {"id": u.documentId, "data": u.toJson()});

  static Future<void> saveUserTokensToDb(UserDetails userDetails) async {
    // Save the initial token to the database
    try {
      var token = await FirebaseMessaging.instance.getToken();
      await apiClient.callFunction(
          "store_user_token", {"id": userDetails.getUid(), "token": token});
    } on Exception catch (e, s) {
      print(e);
      print(s);
    }
    // Any time the token refreshes, store this in the database too.
    FirebaseMessaging.instance.onTokenRefresh.listen((t) =>
        _saveTokenToDatabase(userDetails, t));
  }

  static Future<void> _login(
      BuildContext context, UserCredential userCredential) async {
    var userState = context.read<UserState>();

    var uid = userCredential.user?.uid;

    UserDetails userDetails = await getUserDetails(context, uid);

    // check if first time
    if (userDetails is EmptyUserDetails) {
      userDetails = new UserDetails(
          uid!,
          false,
          userCredential.user?.photoURL,
          userCredential.user?.displayName,
          userCredential.user?.email);

      if (userDetails.name == null || userDetails.name == "") {
        var name = await Get.toNamed("/login/enterDetails");
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
    UserController.saveUserTokensToDb(userDetails);
  }

  static Future<void> _saveTokenToDatabase(UserDetails ud, String token) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return;
    }

    UserController.saveUserTokensToDb(ud);
  }

  static Future<void> continueWithGoogle(
      BuildContext context) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    var userCredentials;

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

  static Future<List<UserDetails>> getBatchUserDetails(
      BuildContext context, List<String> uids) async {
    return await Future.wait(uids.map((e) => getUserDetails(context, e)));
  }

  static Future<UserDetails> getUserDetails(
      BuildContext context, String? uid) async {
    var userState = context.read<UserState>();

    var resp = await apiClient.callFunction("get_user", {"id": uid});

    var ud = (resp == null) ? EmptyUserDetails.empty(uid!)
        : UserDetails.fromJson(resp, uid!);
    userState.setUserDetail(ud);

    return ud;
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
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        sourcePath: original.path,
        aspectRatioPresets: [CropAspectRatioPreset.square],
        androidUiSettings: AndroidUiSettings(
            toolbarColor: Palette.primary,
            toolbarWidgetColor: Palette.grey_light,
            initAspectRatio: CropAspectRatioPreset.original,
            activeControlsWidgetColor: Palette.primary,
            lockAspectRatio: false),
        iosUiSettings: IOSUiSettings(
          minimumAspectRatio: 1.0,
        ));
    if (croppedFile == null) return;
    var uploaded = await FirebaseStorage.instance
        .ref("users/" +
            userDetails.documentId +
            "_" +
            DateTime.now().millisecondsSinceEpoch.toString())
        .putFile(croppedFile);
    print(await uploaded.ref.getDownloadURL());
    userDetails.image = await uploaded.ref.getDownloadURL();
    await UserController.editUser(context, userDetails);
  }
}

