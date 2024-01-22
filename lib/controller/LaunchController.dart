import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/model/UserDetails.dart';
import 'package:nutmeg/screens/EnterDetails.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../Exceptions.dart';
import '../screens/Launch.dart';
import '../state/LoadOnceState.dart';
import '../state/UserState.dart';
import '../utils/LocationUtils.dart';
import '../utils/UiUtils.dart';
import '../utils/Utils.dart';
import 'MiscController.dart';

class LaunchController {
  static bool loadingDone = false;
  static var apiClient = CloudFunctionsClient();
  static String? appVersion;

  static Future<void> handleLink(Uri deepLink) async {
    print("handling dynamic link " + deepLink.toString());
    var fullPath =
        "${deepLink.path}?${deepLink.queryParameters.entries.map((e) => "${e.key}=${e.value}").join("&")}";
    appRouter.go(fullPath);
    // GoRouter.of(navigatorKey.currentContext!).go(fullPath);
  }

  static void _handleMessageFromNotification(RemoteMessage message) async {
    print('message ${message.messageId} opened from notification with data ' +
        message.data.toString());
    GoRouter.of(navigatorKey.currentContext!).go(message.data["route"]);
  }

  static void _setupNotifications(BuildContext context) {
    print("setting up notification handler");

    // FirebaseMessaging.onMessageOpenedApp.listen((m) {
    //   print("called onMsgOpenedApp callback");
    //   _handleMessageFromNotification(m);
    // });

    FirebaseMessaging.onMessage.listen(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    if (!kIsWeb) {
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
        print(error);
      });
    }
  }

  static Future<void> loadData(BuildContext context, String? from) async {
    print("start loading data function");

    var trace = FirebasePerformance.instance.newTrace("launch_app");
    await trace.start();
    final Stopwatch stopwatch = Stopwatch();
    stopwatch.start();

    // fetch device model name
    var d = DeviceInfo();
    d.init();

    List<Future<dynamic>> futures = [
      getVersion(),
      context.read<UserState>().fetchLoggedUserDetails(),
      _loadOnceData(context),
      determinePosition()
    ];
    var futuresData = await Future.wait(futures);

    appVersion = futuresData[0].toString();
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

    if (userDetails != null) {
      context.read<UserState>().setCurrentUserDetails(userDetails);
      trace.putAttribute("user_id", userDetails.documentId);
    }

    // get location
    Position? position = futuresData[3];
    await context.read<UserState>().setLocationInfo(position);

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

    _setupNotifications(context);

    tz.initializeTimeZones();

    print("load data method is done");
    LaunchController.loadingDone = true;

    // install/use app prompt
    if (kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android)) {
      // todo check if app is installed or not
      // print(GoRouter.of(context).location);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: Duration(seconds: 3),
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
          closeIconColor: Palette.white,
          padding: EdgeInsets.all(16),
          content: Text('Use the native app for a better experience',
              style: TextPalette.linkStyleInverted),
          // backgroundColor: Colors.transparent,
          action: SnackBarAction(
            label: 'Use app',
            textColor: Colors.blueAccent,
            onPressed: () =>
                launchUrl(Uri.parse("https://nutmegapp.page.link/store")),
          )));
    }

    // navigate to next screen
    if (deepLink != null) {
      print("navigating with deep link:" + deepLink.toString());
      trace.putAttribute("coming_from_deeplink", true.toString());
      handleLink(deepLink);
    } else if (initialMessage != null) {
      print("navigating with initial message:" + initialMessage.toString());
      trace.putAttribute("coming_from_notification", true.toString());
      _handleMessageFromNotification(initialMessage);
    } else {
      print("normal navigation");
      context.go(from ?? "/");
    }

    trace.setMetric("duration_ms", stopwatch.elapsed.inMilliseconds);
    await trace.stop();
  }

  static Future<void> _loadOnceData(BuildContext context) async {
    print("loading static data");
    var futures = [
      MiscController.getGifs(context.read<LoadOnceState>()),
    ];
    await Future.wait(futures);
    print("loading static done");
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print(
      "Handling a background message: ${message.messageId} with data ${message.data.toString()}");
  if (message.data.containsKey("route")) {
    GoRouter.of(navigatorKey.currentContext!).go(message.data["route"]);
  }
}
