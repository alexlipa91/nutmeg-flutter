import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:version/version.dart';

import '../Exceptions.dart';
import '../screens/AvailableMatches.dart';
import '../screens/Launch.dart';
import '../screens/MatchDetails.dart';
import '../screens/PaymentDetailsDescription.dart';
import '../state/LoadOnceState.dart';
import '../state/UserState.dart';
import '../utils/InfoModals.dart';
import '../utils/UiUtils.dart';
import 'MatchesController.dart';
import 'MiscController.dart';
import 'SportCentersController.dart';
import 'SportsController.dart';
import 'UserController.dart';


class LaunchController {

  static var apiClient = CloudFunctionsClient();

  static Future<void> handleLink(Uri deepLink) async {
    print("handling dynamic link " + deepLink.toString());
    if (deepLink.path == "/payment") {
      var outcome = deepLink.queryParameters["outcome"];
      var matchId = deepLink.queryParameters["match_id"];

      var context = navigatorKey.currentContext;

      var found = false;
      Navigator.popUntil(context, (route) {
        found = route.settings.name == MatchDetails.routeName;
        return found;
      });

      if (!found) {
        Navigator.of(context).pushNamed(AvailableMatches.routeName);

        Navigator.of(context).pushNamed(MatchDetails.routeName,
          arguments: ScreenArguments(
              matchId,
              false
          ),
        );
      }

      if (outcome == "success") {
        await MatchesController.refresh(context, matchId);
        PaymentDetailsDescription.communicateSuccessToUser(context, matchId);
      } else {
        await GenericInfoModal(
            title: "Payment Failed!", description: "Please try again")
            .show(context);
      }
      return;
    }
    if (deepLink.path == "/match") {
      var context = navigatorKey.currentContext;
      var match = await MatchesController.refresh(context,
          deepLink.queryParameters["id"]);

      Navigator.of(context).pushReplacementNamed(AvailableMatches.routeName);

      Navigator.pushNamed(
        context,
        MatchDetails.routeName,
        arguments: ScreenArguments(
          match.documentId,
          false,
        ),
      );
      return;
    }
  }

  static Future<void> loadData(BuildContext context) async {
    await Firebase.initializeApp();

    FirebaseRemoteConfig firebaseRemoteConfig = FirebaseRemoteConfig.instance;
    firebaseRemoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: Duration(seconds: 5),
      minimumFetchInterval: Duration.zero,
    ));

    try {
      await firebaseRemoteConfig.fetchAndActivate();
    } catch (e, s) {
      print(e);
      print(s);
    }

    // fetch device model name
    var d = DeviceInfo();
    await d.init();

    // check if update is necessary
    try {
      var current = (await getVersion()).item1;
      var minimumVersionParts = firebaseRemoteConfig.getString(
          "minimum_app_version").split(".");
      var minimumRequired = Version(int.parse(minimumVersionParts[0]),
          int.parse(minimumVersionParts[1]),
          int.parse(minimumVersionParts[2]));
      if (current < minimumRequired)
        throw OutdatedAppException();
    } catch (s, e) {
      print(e); print(s);
    }

    if (kDebugMode) {
      // Force disable Crashlytics collection while doing every day development.
      // Temporarily toggle this to true if you want to test crash reporting in your app.
      if (!kIsWeb) {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(false);
      }
    } else {
      // Handle Crashlytics enabled status when not in Debug,
      // e.g. allow your users to opt-in to crash reporting.
    }

    // check if user is logged in
    var userDetails = await UserController.getUserIfAvailable(context);

    if (userDetails != null) {
      context.read<UserState>().setCurrentUserDetails(userDetails);
      // tell the app to save user tokens
      await UserController.saveUserTokensToDb(userDetails);
    }

    FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    FirebaseMessaging.instance.subscribeToTopic("nutmeg-generic");

    // DATA LOAD
    var futures = [
      SportCentersController.refreshAll(context),
      SportsController.refreshAll(context.read<LoadOnceState>()),
      MiscController.getGifs(context.read<LoadOnceState>())
    ];

    await Future.wait(futures);

    Uri deepLink;

    if (!kIsWeb) {
      // check if coming from link
      final PendingDynamicLinkData data =
      await FirebaseDynamicLinks.instance.getInitialLink();

      deepLink = data?.link;
    }

    if (deepLink != null) {
      handleLink(deepLink);
    } else {
      // await
      Navigator.pushReplacementNamed(context, AvailableMatches.routeName);
    }
  }

  static Future<Tuple2<Version, String>> getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    var versionParts = packageInfo.version.split(".");
    return Tuple2<Version, String>(
        Version(int.parse(versionParts[0]), int.parse(versionParts[1]),
            int.parse(versionParts[2])),
        packageInfo.buildNumber
    );
  }
}