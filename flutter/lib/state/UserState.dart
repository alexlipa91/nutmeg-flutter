import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/model/LocationInfo.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../model/SportCenter.dart';
import '../model/UserDetails.dart';
import '../screens/EnterDetails.dart';

final logger = CrashlyticsLogger('UserState');

class UserState extends ChangeNotifier {
  static Future<UserDetails?> _fetchUserDetails(String uid) async {
    logger.info('Fetching user details for $uid');
    var resp = await CloudFunctionsClient().get("users/$uid");

    return (resp == null) ? null : UserDetails.fromJson(resp, uid);
  }

  // hold current user id
  UserDetails? _usersDetails;

  UserDetails? _previousUserDetails;

  bool _isTestMode = false;

  UserDetails? getLoggedUserDetails() => _usersDetails;

  String? getLoggedUserId() => _usersDetails?.documentId;

  bool get isTestMode => _isTestMode;

  bool isLoggedIn() => _usersDetails != null;

  List<SportCenter>? getSportCenters() => _sportCenters;

  void notifyListeners({String? reason = "unknown"}) {
    logger
        .info('UserState ${this.hashCode} notifying listeners because $reason');
    super.notifyListeners();
  }

  bool haveUserChanged() {
    if (_previousUserDetails?.getUid() != _usersDetails?.getUid()) {
      return true;
    }
    if (_previousUserDetails?.location != _usersDetails?.location) {
      return true;
    }
    return false;
  }

  // SETTERS that trigger a notifyListeners
  void setTestMode(bool isTestMode) {
    _isTestMode = isTestMode;
    notifyListeners(reason: "setTestMode");
  }

  void _setCurrentUserDetails(UserDetails? u) {
    if (u?.getIsAdmin() ?? false) {
      _isTestMode = true;
    }
    _previousUserDetails = _usersDetails;
    _usersDetails = u;
    notifyListeners(reason: "setCurrentUserDetails");
  }

  void _setSportCenters(List<SportCenter> sportCenters) {
    _sportCenters = sportCenters;
    notifyListeners(reason: "setSportCenters");
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.disconnect();
    }
    _setCurrentUserDetails(null);
    _sportCenters = null;

    // force refresh token to invalidate cached token
    await FirebaseAuth.instance.currentUser?.getIdToken(true);

    notifyListeners();
  }

  Future<void> setLocation(LocationInfo location) async {
    _usersDetails?.location = location;
    notifyListeners(reason: "setLocation");

    await editUser({"location": location.toJson()});
  }

  // user sport centers
  List<SportCenter>? _sportCenters;

  Future<void> fetchLoggedUserDetails() async {
    User? u = await FirebaseAuth.instance.authStateChanges().first;

    if (u == null) {
      return null;
    }

    var ud = await _fetchUserDetails(u.uid);
    if (ud != null) _setCurrentUserDetails(ud);
  }

  Future<void> editUser(Map<String, dynamic> data) async {
    // TODO: maybe we should not fetch the user details again
    await CloudFunctionsClient().post("users/${getLoggedUserId()!}", data);
    await fetchLoggedUserDetails();
  }

  Future<void> storeUserToken(String token) async {
    logger.info('Storing user token: $token');
    CloudFunctionsClient()
        .post("users/${getLoggedUserId()!}/tokens", {"token": token});
  }

  Future<void> fetchLoggedUserSportCenters() async {
    Map<String, dynamic> data = await CloudFunctionsClient()
            .get("sportcenters", args: {"user": getLoggedUserId()!}) ??
        {};

    _sportCenters = data.entries
        .map((e) =>
            SportCenter.fromJson(Map<String, dynamic>.from(e.value), e.key))
        .toList();

    if (_sportCenters != null) {
      _setSportCenters(_sportCenters!);
    } else {
      logger.severe('sportcenters not found for user ${getLoggedUserId()}');
    }
  }

  // GOOGLE SIGN IN
  GoogleSignIn googleSignIn = GoogleSignIn();

  Future<void> login(
      UserCredential userCredential, BuildContext context) async {
    var uid = userCredential.user?.uid;

    UserDetails? userDetails = await UserState._fetchUserDetails(uid!);

    // check if first time
    if (userDetails == null) {
      userDetails = new UserDetails(uid, false, userCredential.user?.photoURL,
          userCredential.user?.displayName, userCredential.user?.email);

      userDetails.name = "";

      if (userDetails.name == null || userDetails.name == "") {
        var name = await Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => EnterDetails()));
        if (name == null || name == "") {
          // Navigator.pop(context);
          return null;
        } else {
          userDetails.name = name;
        }
      }

      await CloudFunctionsClient().post("users/$uid/add", userDetails.toJson());
    }

    await askForNotificationPermissionAndStoreToken();

    _setCurrentUserDetails(userDetails);
  }

  Future<void> askForNotificationPermissionAndStoreToken() async {
    if (!isLoggedIn()) {
      return;
    }

    NotificationSettings currentSettings =
        await FirebaseMessaging.instance.getNotificationSettings();

    logger.info(
        'Current notification settings: ${currentSettings.authorizationStatus.name}');

    if (currentSettings.authorizationStatus ==
            AuthorizationStatus.notDetermined) {
      logger.info('Requesting notification permissions for the first time');
      currentSettings = await FirebaseMessaging.instance.requestPermission();
      logger.info(
          'Permission result: ${currentSettings.authorizationStatus.name}');
    }

    if (currentSettings.authorizationStatus == AuthorizationStatus.authorized ||
        currentSettings.authorizationStatus == AuthorizationStatus.provisional) {
      logger.info('Requesting FCM token');

      const vapidKey = String.fromEnvironment('FIREBASE_VAPID_KEY');
      String? token = await FirebaseMessaging.instance
          .getToken(vapidKey: vapidKey)
          .timeout(Duration(seconds: 5), onTimeout: () {
        logger.info("FCM token request took too long, skipping");
        return null;
      });

      if (token != null) {
        logger.info('FCM token obtained: ${token.substring(0, 5)}...');
        await storeUserToken(token);
      }

      // Listen for token refreshes so the backend always has the latest token
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        logger.info('FCM token refreshed: ${newToken.substring(0, 5)}...');
        storeUserToken(newToken);
      });
    }
  }

  Future<void> continueWithEmail(
      BuildContext context, String email, String password,
      {required bool isNewUser}) async {
    UserCredential userCred;
    if (isNewUser) {
      userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
    } else {
      userCred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
    }
    await login(userCred, context);
  }

  Future<void> continueWithApple(BuildContext context) async {
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

    await login(userCredential, context);
  }
}
