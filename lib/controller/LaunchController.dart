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
import 'package:go_router/go_router.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/model/UserDetails.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
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
import 'UserController.dart';

import 'package:flutter/foundation.dart' show kIsWeb;


class LaunchController {
  static bool loadingDone = false;
  static var apiClient = CloudFunctionsClient();

  static Future<void> handleLink(Uri deepLink, [bool start = false]) async {
    print("handling dynamic link " + deepLink.toString());
    var context = navigatorKey.currentContext;

    if (deepLink.path == "/payment") {
      var outcome = deepLink.queryParameters["outcome"];
      var matchId = deepLink.queryParameters["match_id"];

      // context.read<AppState>().setStack(
      //     List<NutmegPage>.from([NutmegPage.HOME, NutmegPage.MATCH]), matchId);

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
      // context.read<AppState>().setStack(
      //     List<NutmegPage>.from([NutmegPage.HOME, NutmegPage.MATCH]),
      //     deepLink.queryParameters["id"]);
      return;
    }
  }

  static void handleMessageFromNotification(
      BuildContext context, RemoteMessage message) async {
    print('message ${message.messageId} opened from notification with data '
        + message.data.toString());

    // context.read<AppState>().setStack(
    //     List<NutmegPage>.from([NutmegPage.HOME, NutmegPage.MATCH]),
    //     message.data["match_id"]);
  }

  static void setupNotifications(BuildContext context) {
    print("setting up notification handler");

    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      print("called onMsgOpenedApp callback");
      handleMessageFromNotification(context, m);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });

    if (!kIsWeb) {
      Future<Null> Function(PendingDynamicLinkData? dynamicLink) future =
          (PendingDynamicLinkData? dynamicLink) async {
        final Uri? deepLink = dynamicLink?.link;

        if (deepLink != null) {
          LaunchController.handleLink(deepLink);
        }
      };

      FirebaseDynamicLinks.instance.onLink(
          onSuccess: future, onError: (OnLinkErrorException e) async {
        print(e.message);
      });
    }
  }

  static Future<void> loadData(BuildContext context,
      String? from) async {
    print("start loading data function");
    await Firebase.initializeApp();

    var trace = FirebasePerformance.instance.newTrace("launch_app");
    trace.start();

    // fetch device model name
    var d = DeviceInfo();
    d.init();

    List<Future<dynamic>> futures = [
      getVersion(),
      UserController.getUserIfAvailable(context),
      loadOnceData(context)
    ];
    var futuresData = await Future.wait(futures);

    UserDetails? availableUserDetails = futuresData[1];

    if (!kIsWeb) {
      FirebaseRemoteConfig firebaseRemoteConfig = FirebaseRemoteConfig.instance;
      await firebaseRemoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: Duration(seconds: 5),
        minimumFetchInterval: Duration(minutes: 1),
      ));

      try {
        await firebaseRemoteConfig.fetchAndActivate();
      } catch (e, s) {
        print(e);
        print(s);
      }

      Tuple2<Version, String> minimumVersion = futuresData[0];

      var current = (minimumVersion).item1;
      trace.putAttribute("app_version", current.toString());
      var minimumVersionParts =
      firebaseRemoteConfig.getString("minimum_app_version").split(".");
      var minimumRequired = Version(int.parse(minimumVersionParts[0]),
          int.parse(minimumVersionParts[1]), int.parse(minimumVersionParts[2]));
      if (current < minimumRequired) throw OutdatedAppException();
    }

    if (kDebugMode) {
      // Force disable Crashlytics collection while doing every day development.
      // Temporarily toggle this to true if you want to test crash reporting in your app.
      if (!kIsWeb) {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(false);
      }
    }

    // check if user is logged in
    var userDetails = availableUserDetails;

    // fixme force users without name
    if (userDetails != null &&
        (userDetails.name == null || userDetails.name == "")) {
      var name = await Get.toNamed("/login/enterDetails");
      if (name == null || name == "") {
        // Navigator.pop(context);
        // SystemNavigator.pop();
        return null;
      } else {
        userDetails.name = name;
        UserController.editUser(context, userDetails);
      }
    }

    if (userDetails != null) {
      context.read<UserState>().setCurrentUserDetails(userDetails);
      trace.putAttribute("user_id", userDetails.documentId);
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

    // check if coming from link
    Uri? deepLink;

    if (!kIsWeb) {
      final PendingDynamicLinkData? data =
          await FirebaseDynamicLinks.instance.getInitialLink();

      deepLink = data?.link;
    }

    // check if coming from notification
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (deepLink != null) {
      print("navigating with deep link:" + deepLink.toString());
      trace.putAttribute("coming_from_deeplink", true.toString());
      handleLink(deepLink, true);
    } else if (initialMessage != null) {
      print("navigating with initial message:" + initialMessage.toString());
      trace.putAttribute("coming_from_notification", true.toString());
      handleMessageFromNotification(context, initialMessage);
    }

    setupNotifications(context);

    trace.stop();

    print("load data method is done");

    LaunchController.loadingDone = true;
    print(from);
    context.go(from ?? "/");
  }

  static Future<void> loadOnceData(BuildContext context) async {
    print("loading static data");
    var futures = [
      MiscController.getGifs(context.read<LoadOnceState>())
    ];
    await Future.wait(futures);
    print("loading static done");
  }
}
