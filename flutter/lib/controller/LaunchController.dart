import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/controller/MiscController.dart';
import 'package:nutmeg/main.dart';
import 'package:nutmeg/state/LoadOnceState.dart';
import 'package:nutmeg/screens/EnterDetails.dart';
import 'package:nutmeg/state/MatchesState.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../state/UserState.dart';
import '../utils/UiUtils.dart';

final logger = CrashlyticsLogger('LaunchController');

class LaunchController {
  static bool loadingDone = false;
  static var apiClient = CloudFunctionsClient();
  static String? appVersion;
  static Future<void> handleLink(Uri deepLink) async {
    logger.info("Handling dynamic link " + deepLink.toString());
    var fullPath =
        "${deepLink.path}?${deepLink.queryParameters.entries.map((e) => "${e.key}=${e.value}").join("&")}";
    appRouter.go(fullPath);
    // GoRouter.of(navigatorKey.currentContext!).go(fullPath);
  }

  static void _handleMessageFromNotification(RemoteMessage message) async {
    logger.info(
        'message ${message.messageId} opened from notification with data ' +
            message.data.toString());
    GoRouter.of(navigatorKey.currentContext!).go(message.data["route"]);
  }

  static void setupNotificationsHandler(BuildContext context) async {
    logger.info("setting up notification handler");

    // TODO deal with notifications on foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logger.info('Got a message whilst in the foreground!');
      logger.info('Message data: ${message.data}');

      if (message.notification != null) {
        logger.info(
            'Message also contained a notification: ${message.notification}');
      }
    });
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    if (!kIsWeb) {
      // Your existing mobile dynamic links setup
      Future<Null> Function(PendingDynamicLinkData? dynamicLink) future =
          (PendingDynamicLinkData? dynamicLink) async {
        final Uri? deepLink = dynamicLink?.link;

        if (deepLink != null) {
          LaunchController.handleLink(deepLink);
        }
      };

      FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
        future(dynamicLinkData);
      }).onError((error) {
        logger.severe("Error on dynamic link", error);
      });
    }
  }

  static Future<void> trackAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;
    await FirebaseAnalytics.instance.logEvent(name: "app_started", parameters: {
      "app_version": packageInfo.version,
    });
    logger.info("Logged app_started event with version ${packageInfo.version}");
  }

  static Future<void> loadData(BuildContext context, String? from) async {
    logger.info("start loading data function");

    trackAppVersion();

    // fetch device model name
    var d = DeviceInfo();
    d.init();

    var userState = context.read<UserState>();
    var matchesState = context.read<MatchesState>();

    await userState.fetchLoggedUserDetails();
    await matchesState.fetchLocation();

    // preload GIFs for join-match celebration
    MiscController.getGifs(context.read<LoadOnceState>());

    if (!kIsWeb) {
      FirebaseRemoteConfig firebaseRemoteConfig = FirebaseRemoteConfig.instance;
      await firebaseRemoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: Duration(seconds: 5),
        minimumFetchInterval: Duration(minutes: 1),
      ));

      try {
        await firebaseRemoteConfig.fetchAndActivate();
      } catch (e, s) {
        logger.severe("Error fetching and activating remote config", e, s);
      }

      // Tuple2<Version, String> minimumVersion = futuresData[0];

      // var current = (minimumVersion).item1;
      // // trace.putAttribute("app_version", current.toString());
      // var minimumVersionParts =
      //     firebaseRemoteConfig.getString("minimum_app_version").split(".");
      // var minimumRequired = Version(int.parse(minimumVersionParts[0]),
      //     int.parse(minimumVersionParts[1]), int.parse(minimumVersionParts[2]));
      // if (current < minimumRequired) throw OutdatedAppException();
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
    var userDetails = userState.getLoggedUserDetails();
    // fixme force users without name
    if (userDetails != null &&
        (userDetails.name == null || userDetails.name == "")) {
      var name = await Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => EnterDetails()));
      if (name == null || name == "") {
        // Navigator.pop(context);
        // SystemNavigator.pop();
        return null;
      } else {
        await context.read<UserState>().editUser({"name": name});
      }
    }

    // request permissions FIXME
    // FirebaseMessaging.instance.requestPermission(
    //   alert: true,
    //   announcement: false,
    //   badge: true,
    //   carPlay: false,
    //   criticalAlert: false,
    //   provisional: false,
    //   sound: true,
    // );

    // check if coming from link
    Uri? deepLink;

    if (!kIsWeb) {
      final PendingDynamicLinkData? data =
          await FirebaseDynamicLinks.instance.getInitialLink();

      deepLink = data?.link;
    }

    // NOTIFICATIONS STUFF
    // check if coming from notification
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    context.read<UserState>().askForNotificationPermissionAndStoreToken();
    setupNotificationsHandler(context);

    tz.initializeTimeZones();

    logger.info("load data method is done");
    LaunchController.loadingDone = true;

    // install/use app prompt
    // if (kIsWeb &&
    //     (defaultTargetPlatform == TargetPlatform.iOS ||
    //         defaultTargetPlatform == TargetPlatform.android)) {
    //   // todo check if app is installed or not
    //   // print(GoRouter.of(context).location);

    //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //       duration: Duration(seconds: 3),
    //       elevation: 0,
    //       behavior: SnackBarBehavior.floating,
    //       showCloseIcon: true,
    //       closeIconColor: Palette.white,
    //       padding: EdgeInsets.all(16),
    //       content: Text('Use the native app for a better experience',
    //           style: TextPalette.linkStyleInverted),
    //       // backgroundColor: Colors.transparent,
    //       action: SnackBarAction(
    //         label: 'Use app',
    //         textColor: Colors.blueAccent,
    //         onPressed: () =>
    //             launchUrl(Uri.parse("https://nutmegapp.page.link/store")),
    //       )));
    // }

    // navigate to next screen
    if (deepLink != null) {
      logger.info("navigating with deep link:" + deepLink.toString());
      // trace.putAttribute("coming_from_deeplink", true.toString());
      handleLink(deepLink);
    } else if (initialMessage != null) {
      logger
          .info("navigating with initial message:" + initialMessage.toString());
      // trace.putAttribute("coming_from_notification", true.toString());
      _handleMessageFromNotification(initialMessage);
    } else {
      context.go(from ?? "/");
    }

    // trace.setMetric("duration_ms", stopwatch.elapsed.inMilliseconds);
    // await trace.stop();
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  logger.info(
      "Handling a background message: ${message.messageId} with data ${message.data.toString()}");
  if (message.data.containsKey("route")) {
    GoRouter.of(navigatorKey.currentContext!).go(message.data["route"]);
  }
}
