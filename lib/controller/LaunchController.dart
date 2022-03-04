import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:provider/provider.dart';
import 'package:version/version.dart';

import '../Exceptions.dart';
import '../screens/Launch.dart';
import '../screens/PaymentDetailsDescription.dart';
import '../state/LoadOnceState.dart';
import '../state/UserState.dart';
import '../utils/InfoModals.dart';
import '../utils/UiUtils.dart';
import '../utils/Utils.dart';
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

      var targetRoute = "/match/" + matchId;
      if (Get.currentRoute != targetRoute)
        Get.toNamed(targetRoute);

      if (outcome == "success") {
        PaymentDetailsDescription.communicateSuccessToUser(context, matchId);
      } else {
        await GenericInfoModal(
                title: "Payment Failed!", description: "Please try again")
            .show(context);
      }
      return;
    }
    if (deepLink.path == "/match") {
      var targetRoute = "/match/" + deepLink.queryParameters["id"];
      if (Get.currentRoute != targetRoute)
        Get.toNamed(targetRoute);
      return;
    }
  }

  static void handleMessageFromNotification(RemoteMessage message) async {
    print('message opened from notification');
    var targetRoute = "/match/" + message.data["match_id"];
    if (Get.currentRoute != targetRoute)
      Get.toNamed(targetRoute);
  }

  static void setupNotifications() {
    // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessageOpenedApp.listen(handleMessageFromNotification);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });
  }

  static Future<void> loadData(BuildContext context) async {
    print("start loading data function");
    await Firebase.initializeApp();

    var trace = FirebasePerformance.instance.newTrace("launch-app");
    final stopwatch = Stopwatch()..start();

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
      trace.putAttribute("app_version", current.toString());
      var minimumVersionParts =
          firebaseRemoteConfig.getString("minimum_app_version").split(".");
      var minimumRequired = Version(int.parse(minimumVersionParts[0]),
          int.parse(minimumVersionParts[1]), int.parse(minimumVersionParts[2]));
      if (current < minimumRequired) throw OutdatedAppException();
    } catch (s, e) {
      print(e);
      print(s);
    }

    if (kDebugMode) {
      // Force disable Crashlytics collection while doing every day development.
      // Temporarily toggle this to true if you want to test crash reporting in your app.
      if (!kIsWeb) {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(false);
      }
    }

    setupNotifications();

    // check if user is logged in
    var userDetails = await UserController.getUserIfAvailable(context);

    if (userDetails != null) {
      context.read<UserState>().setCurrentUserDetails(userDetails);
      // tell the app to save user tokens
      await UserController.saveUserTokensToDb(userDetails);
      trace.putAttribute("user_id", userDetails?.documentId);
    }

    // request permissions
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

    // load static data
    await loadOnceData(context);

    // check if coming from link
    Uri deepLink;

    if (!kIsWeb) {
      final PendingDynamicLinkData data =
          await FirebaseDynamicLinks.instance.getInitialLink();

      deepLink = data?.link;
    }

    // check if coming from notification
    RemoteMessage initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (deepLink != null) {
      print("navigating with deep link:" + deepLink.toString());
      trace.putAttribute("coming_from_deeplink", true.toString());
      handleLink(deepLink);
    } else if (initialMessage != null) {
      print("navigating with initial message:" + initialMessage.toString());
      trace.putAttribute("coming_from_notification", true.toString());
      handleMessageFromNotification(initialMessage);
    } else {
      print("navigating with normal startup");
      Get.offAndToNamed("/home");
    }

    trace.setMetric('duration_ms', stopwatch.elapsed.inMilliseconds);
    trace.stop();
  }

  static Future<void> loadOnceData(BuildContext context) async {
    var futures = [
      SportCentersController.refreshAll(context),
      SportsController.refreshAll(context.read<LoadOnceState>()),
      MiscController.getGifs(context.read<LoadOnceState>())
    ];
    await Future.wait(futures);
  }
}
