import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:logging/logging.dart';

import '../model/SportCenter.dart';
import '../model/UserDetails.dart';
import '../screens/EnterDetails.dart';

final logger = Logger('UserState');

class UserState extends ChangeNotifier {
  static Future<UserDetails?> _fetchUserDetails(String uid) async {
    logger.info('fetching user details for $uid');
    var resp = await CloudFunctionsClient().get("users/$uid");

    return (resp == null) ? null : UserDetails.fromJson(resp, uid);
  }

  // hold current user id
  UserDetails? _usersDetails;

  String? _previousUserId;

  bool _isTestMode = false;

  UserDetails? getLoggedUserDetails() => _usersDetails;

  String? getLoggedUserId() => _usersDetails?.documentId;

  bool get isTestMode => _isTestMode;

  bool isLoggedIn() => _usersDetails != null;

  List<SportCenter>? getSportCenters() => _sportCenters;

  void notifyListeners() {
    logger.info('UserState ${this.hashCode} notifying listeners');
    print(_usersDetails?.documentId);
    super.notifyListeners();
  }

  bool haveUserChanged() {
    return _previousUserId != _usersDetails?.documentId;
  }

  // SETTERS that trigger a notifyListeners
  void setTestMode(bool isTestMode) {
    _isTestMode = isTestMode;
    notifyListeners();
  }

  void _setCurrentUserDetails(UserDetails? u) {
    if (u?.getIsAdmin() ?? false) {
      _isTestMode = true;
    }
    _previousUserId = _usersDetails?.documentId;
    _usersDetails = u;
    notifyListeners();
  }

  void _setSportCenters(List<SportCenter> sportCenters) {
    _sportCenters = sportCenters;
    notifyListeners();
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

  // user sport centers
  List<SportCenter>? _sportCenters;

  Future<void> fetchLoggedUserDetails() async {
    // uncomment this to navigate as another user for testing
    // return fetchUserDetails("bQHD0EM265V6GuSZuy1uQPHzb602");

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
    logger.config('storing user token: $token');
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

    _setCurrentUserDetails(userDetails);
  }

  Future<void> continueWithFacebook(BuildContext context) async {
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
      final OAuthCredential facebookAuthCredential =
          FacebookAuthProvider.credential(loginResult.accessToken?.token ?? "");

      // Once signed in, return the UserCredential
      userCred = await FirebaseAuth.instance
          .signInWithCredential(facebookAuthCredential);
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
