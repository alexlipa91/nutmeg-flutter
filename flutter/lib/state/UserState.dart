import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/model/LocationInfo.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../config/app_config.dart';
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

  bool _isTestMode = AppConfig.testMode;

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
    await CloudFunctionsClient()
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

  Future<void> deleteSportCenter(String sportCenterId) async {
    await CloudFunctionsClient().delete("sportcenters/$sportCenterId");
    _sportCenters?.removeWhere((sc) => sc.placeId == sportCenterId);
    if (_sportCenters != null) {
      _setSportCenters(_sportCenters!);
    }
  }

  // GOOGLE SIGN IN
  GoogleSignIn googleSignIn = GoogleSignIn();

  /// Display name from Apple credential (given + family). Only non-empty on first Apple authorization.
  static String? displayNameFromAppleCredential(
      AuthorizationCredentialAppleID credential) {
    final given = credential.givenName?.trim();
    final family = credential.familyName?.trim();
    final parts = <String>[];
    if (given != null && given.isNotEmpty) parts.add(given);
    if (family != null && family.isNotEmpty) parts.add(family);
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  Future<void> login(
    UserCredential userCredential,
    BuildContext context, {
    /// Name from the identity provider (e.g. Apple fullName on first sign-in only).
    String? oauthDisplayName,
    /// Email from the identity provider (e.g. Apple on first sign-in only).
    String? oauthEmail,
  }) async {
    var uid = userCredential.user?.uid;
    final firebaseUser = userCredential.user;

    UserDetails? userDetails = await UserState._fetchUserDetails(uid!);

    // check if first time
    if (userDetails == null) {
      String? name = firebaseUser?.displayName?.trim();
      if (name == null || name.isEmpty) {
        final fromOauth = oauthDisplayName?.trim();
        name = (fromOauth != null && fromOauth.isNotEmpty) ? fromOauth : null;
      }

      String? email = firebaseUser?.email?.trim();
      if (email == null || email.isEmpty) {
        final fromOauth = oauthEmail?.trim();
        email = (fromOauth != null && fromOauth.isNotEmpty) ? fromOauth : null;
      }

      userDetails = UserDetails(
        uid,
        false,
        firebaseUser?.photoURL,
        name,
        email,
      );

      // Only prompt when we still have no display name (Apple/Google may have provided one).
      if (userDetails.name == null || userDetails.name!.trim().isEmpty) {
        final entered = await Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => EnterDetails()));
        if (entered == null || (entered is String && entered.trim().isEmpty)) {
          await FirebaseAuth.instance.signOut();
          if (await googleSignIn.isSignedIn()) {
            await googleSignIn.disconnect();
          }
          return;
        }
        userDetails.name = entered is String ? entered.trim() : '$entered';
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

      // On iOS, ensure the APNS token is available before requesting FCM token
      if (!kIsWeb) {
        String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        logger.info('APNS token: ${apnsToken != null ? "obtained" : "null"}');
        if (apnsToken == null) {
          // Wait briefly and retry — APNS token can take a moment on first launch
          await Future.delayed(Duration(seconds: 2));
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          logger.info('APNS token retry: ${apnsToken != null ? "obtained" : "still null"}');
        }
      }

      // vapidKey is only needed for web; pass null on native platforms
      final String? vapidKey = kIsWeb
          ? AppConfig.firebaseVapidKey
          : null;

      String? token = await FirebaseMessaging.instance
          .getToken(vapidKey: vapidKey)
          .timeout(Duration(seconds: 10), onTimeout: () {
        logger.info("FCM token request took too long, skipping");
        return null;
      });

      if (token != null) {
        logger.info('FCM token obtained: ${token.substring(0, 5)}...');
        await storeUserToken(token);
      } else {
        logger.warning('FCM token was null — notifications will not work');
      }

      // Show notifications as banners on iOS even when app is in foreground
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

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

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> continueWithApple(BuildContext context) async {
    // To prevent replay attacks with the credential returned from Apple, we
    // include a nonce in the credential request. When signing in with
    // Firebase, the nonce in the id token returned by Apple, is expected to
    // match the sha256 hash of `rawNonce`.
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    // Request credential for the currently signed in Apple account.
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final appleDisplayName =
        UserState.displayNameFromAppleCredential(appleCredential);

    logger.info('Apple sign-in credential received (identityToken set: '
        '${appleCredential.identityToken != null}, fullName set: '
        '${appleDisplayName != null})');

    // Create an `OAuthCredential` from the credential returned by Apple.
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );

    // Sign in the user with Firebase. If the nonce we generated earlier does
    // not match the nonce in `appleCredential.identityToken`, sign in will fail.
    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(oauthCredential);

    final user = userCredential.user;
    if (user != null &&
        appleDisplayName != null &&
        appleDisplayName.isNotEmpty) {
      final existing = user.displayName?.trim();
      if (existing == null || existing.isEmpty) {
        try {
          await user.updateDisplayName(appleDisplayName);
          await user.reload();
        } catch (e, st) {
          logger.warning('updateDisplayName after Apple sign-in failed', e, st);
        }
      }
    }

    await login(
      userCredential,
      context,
      oauthDisplayName: appleDisplayName,
      oauthEmail: appleCredential.email,
    );
  }
}
