import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/utils/LocationUtils.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../model/SportCenter.dart';
import '../model/UserDetails.dart';
import '../screens/EnterDetails.dart';
import 'MatchesState.dart';


class UserState extends ChangeNotifier {
  // hold current user id
  String? currentUserId;
  bool _isTestMode = false;

  // holds state for all users' data (both logged in user and others)
  Map<String, UserDetails> _usersDetails = Map();

  UserDetails? getLoggedUserDetails() => _usersDetails[currentUserId];

  void setCurrentUserDetails(UserDetails u) {
    currentUserId = u.documentId;
    if (u.getIsAdmin()) {
      _isTestMode = true;
    }
    setUserDetail(u);
  }

  void setUserDetail(UserDetails u) {
    _usersDetails[u.documentId] = u;
    notifyListeners();
  }

  UserDetails? getUserDetail(String uid) => _usersDetails[uid];

  bool get isTestMode => _isTestMode;

  void setTestMode(bool value) {
    _isTestMode = value;
    notifyListeners();
  }

  bool isLoggedIn() => currentUserId != null;

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if(await googleSignIn.isSignedIn()) {
      await googleSignIn.disconnect();
    }
    currentUserId = null;
    _sportCenters = null;
    notifyListeners();
    print("logged out");
  }

  // user sport centers
  List<SportCenter>? _sportCenters;

  Future<UserDetails?> fetchLoggedUserDetails() async {
    // use this to navigate as another user for testing
    // return fetchUserDetails("bQHD0EM265V6GuSZuy1uQPHzb602");

    User? u = await FirebaseAuth.instance.authStateChanges().first;

    if (u == null) {
      return null;
    }

    return fetchUserDetails(u.uid);
  }

  Future<UserDetails> getOrFetch(String uid) async {
    var u = _usersDetails[uid] ?? (await fetchUserDetails(uid));
    return u!;
  }

  Future<UserDetails?> fetchUserDetails(String uid) async {
    var resp = await CloudFunctionsClient().get("users/$uid");

    var ud = (resp == null) ? null : UserDetails.fromJson(resp, uid);
    if (ud != null)
      setUserDetail(ud);

    return ud;
  }

  Future<void> editUser(Map<String, dynamic> data) async {
    await CloudFunctionsClient().post("users/${currentUserId!}", data);
    await fetchLoggedUserDetails();
  }

  Future<void> storeUserToken(String? token) async {
    if (token == null) {
      return;
    }
    CloudFunctionsClient().post("users/${currentUserId!}/tokens", {
      "token": token
    });
  }

  Future<List<SportCenter>> fetchLoggedUserSportCenters() async {
    Map<String, dynamic> data = await CloudFunctionsClient()
        .get("sportcenters", args: {"user": currentUserId!})
        ?? {};

    _sportCenters = data.entries.map((e) => SportCenter
        .fromJson(Map<String, dynamic>.from(e.value), e.key))
        .toList();

    notifyListeners();
    return _sportCenters!;
  }

  List<SportCenter>? getSportCenters() => _sportCenters;

  // user location
  late LocationInfo _deviceLocationInfo;

  void setCustomLocationInfo(LocationInfo l) {
    _deviceLocationInfo = l;
    notifyListeners();
  }

  Future<void> setLocationInfo(Position? position) async {
    if (position != null)
      _deviceLocationInfo = await fetchLocationInfo(position.latitude, position.longitude);
    else
      _deviceLocationInfo = LocationInfo("NL", "Amsterdam", 52.3676, 4.9041,
          "ChIJVXealLU_xkcRja_At0z9AGY");
  }

  LocationInfo getLocationInfo() =>
      _usersDetails[currentUserId]?.location ?? _deviceLocationInfo;

  GoogleSignIn googleSignIn = GoogleSignIn();

  Future<void> continueWithGoogle(
      BuildContext context) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    var userCredentials;

    if (kIsWeb) {
      userCredentials = await auth.signInWithPopup(GoogleAuthProvider());
    } else {
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

  Future<void> _login(
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

      userDetails.name = "";

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

      await CloudFunctionsClient().post("users/$uid/add", userDetails.toJson());
    }

    userState.setCurrentUserDetails(userDetails);
    userState.storeUserToken(await FirebaseMessaging.instance.getToken());
    FirebaseMessaging.instance.onTokenRefresh.listen((t) =>
        userState.storeUserToken(t));

    context.read<MatchesState>().refreshState(context);
  }

  Future<void> continueWithFacebook(
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

  Future<void> continueWithApple(
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
}

class LocationInfo {

  // these are city coordinates:
  double lat;
  double lng;
  String country;
  String city;
  String placeId;

  LocationInfo(this.country, this.city, this.lat, this.lng, this.placeId);

  LocationInfo.fromJson(Map<String, dynamic> json):
      country = json["country"],
      city = json["city"],
      lat = json["lat"],
      lng = json["lng"],
      placeId = json["place_id"];

  Map<String, dynamic> toJson() => {
    "country": country,
    "city": city,
    "lat": lat,
    "lng": lng,
    "place_id": placeId
  };

  String getText() => "$city, $country";
}