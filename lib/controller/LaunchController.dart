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
import '../utils/UiUtils.dart';
import '../utils/Utils.dart';
import 'MiscController.dart';
import 'UserController.dart';


class LaunchController {
  static bool loadingDone = false;
  static var apiClient = CloudFunctionsClient();

  static Future<void> handleLink(Uri deepLink) async {
    print("handling dynamic link " + deepLink.toString());
    var fullPath = "${deepLink.path}?${deepLink.queryParameters
        .entries.map((e) => "${e.key}=${e.value}").join("&")}";
    GoRouter.of(appRouter.navigator!.context).go(fullPath);
  }

  static void _handleMessageFromNotification(RemoteMessage message) async {
    print('message ${message.messageId} opened from notification with data '
        + message.data.toString());
    GoRouter.of(appRouter.navigator!.context).go(message.data["route"]);
  }

  static void _setupNotifications(BuildContext context) {
    print("setting up notification handler");

    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      print("called onMsgOpenedApp callback");
      _handleMessageFromNotification(m);
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

      FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
        future(dynamicLinkData);
      }).onError((error) {
        print(error);
      });
    }
  }

  static Future<void> loadData(BuildContext context,
      String? from) async {
    print("start loading data function");

    var trace = FirebasePerformance.instance.newTrace("launch_app");
    trace.start();

    // fetch device model name
    var d = DeviceInfo();
    d.init();

    List<Future<dynamic>> futures = [
      getVersion(),
      UserController.getUserIfAvailable(context),
      _loadOnceData(context),
      _determinePosition()
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
      var name = await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => EnterDetails()));
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
    if (kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS
        || defaultTargetPlatform == TargetPlatform.android)) {
      // todo check if app is installed or not
      // print(GoRouter.of(context).location);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 15),
          elevation: 0,
          padding: EdgeInsets.all(16),
          content: Text('Use the native app for a better experience',
              style: TextPalette.linkStyleInverted),
          // backgroundColor: Colors.transparent,
          action: SnackBarAction(
            label: 'Download',
            textColor: Colors.blueAccent,
            onPressed: () => launchUrl(Uri.parse("https://nutmegapp.page.link/store")),
          )
        )
      );
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
    trace.stop();
  }

  static Future<void> _loadOnceData(BuildContext context) async {
    print("loading static data");
    var futures = [
      MiscController.getGifs(context.read<LoadOnceState>()),
      context.read<LoadOnceState>().fetchSportCenters(),
    ];
    await Future.wait(futures);
    print("loading static done");
  }

  static Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      print('Location services are disabled.');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        print('Location permissions are denied');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      print('Location permissions are permanently denied, we cannot request permissions.');
      return null;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }
}
