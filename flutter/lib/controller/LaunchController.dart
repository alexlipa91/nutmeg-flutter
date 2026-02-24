import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/config/app_config.dart';
import 'package:nutmeg/controller/MiscController.dart';
import 'package:nutmeg/l10n/app_localizations.dart';
import 'package:nutmeg/main.dart';
import 'package:nutmeg/state/LoadOnceState.dart';
import 'package:nutmeg/screens/EnterDetails.dart';
import 'package:nutmeg/state/MatchesState.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';
import 'package:nutmeg/utils/navigate_url.dart';
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
  static const String _androidPlayStoreUrl =
      "https://play.google.com/store/apps/details?id=com.nutmeg.nutmeg";
  static bool _androidInstallBannerShown = false;

  /// Notifies GoRouter to re-evaluate redirects after loading completes.
  static final ValueNotifier<bool> loadingNotifier = ValueNotifier(false);

  /// The original URL the user intended to visit before being redirected to /launch.
  static String? pendingRedirect;
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

    // Handle notification tap when app is in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logger
          .info('Notification tapped (app was in background): ${message.data}');
      if (message.data.containsKey("route")) {
        _handleMessageFromNotification(message);
      }
    });

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

  static String _getPlatform() {
    if (kIsWeb) return "web";
    if (defaultTargetPlatform == TargetPlatform.iOS) return "ios";
    if (defaultTargetPlatform == TargetPlatform.android) return "android";
    return "unknown";
  }

  static Future<Map<String, dynamic>> _buildCurrentAppInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return {
      "app_version": "${packageInfo.version}+${packageInfo.buildNumber}",
      if (AppConfig.commitSha.isNotEmpty) "commit_sha": AppConfig.commitSha,
      if (AppConfig.commitTimestampEpoch.isNotEmpty)
        "commit_timestamp": AppConfig.commitTimestampEpoch,
      "last_updated": DateTime.now().toUtc().toIso8601String(),
    };
  }

  static Future<void> storeAppInfo(UserState userState) async {
    var userDetails = userState.getLoggedUserDetails();
    if (userDetails == null) return;

    var platform = _getPlatform();
    var currentAppInfo = await _buildCurrentAppInfo();

    logger.info("Storing app info for $platform: $currentAppInfo");
    try {
      await apiClient.post("users/${userDetails.documentId}",
          {"app_info.$platform": currentAppInfo});
    } catch (e, s) {
      logger.severe("Failed to store app info", e, s);
    }
  }

  static void _maybeShowAndroidInstallBanner() {
    if (_androidInstallBannerShown ||
        !kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messenger = scaffoldMessengerKey.currentState;
      if (messenger == null || _androidInstallBannerShown) return;
      final context = navigatorKey.currentContext;
      final l10n = context != null ? AppLocalizations.of(context) : null;

      _androidInstallBannerShown = true;
      messenger.showMaterialBanner(MaterialBanner(
        content: Text(l10n?.androidInstallBannerMessage ??
            "Install the Nutmeg app for a better experience."),
        leading: Icon(Icons.android),
        actions: [
          TextButton(
            onPressed: () => navigateToUrl(_androidPlayStoreUrl),
            child: Text(l10n?.androidInstallBannerDownload ?? "Download"),
          ),
          TextButton(
            onPressed: messenger.hideCurrentMaterialBanner,
            child: Text(l10n?.androidInstallBannerLater ?? "Later"),
          ),
        ],
      ));
    });
  }

  static Future<void> loadData(BuildContext context) async {
    logger.info("start loading data function");
    logger.info(
        "TEST_MODE=${AppConfig.testMode}, BACKEND_URL=${AppConfig.backendUrl}");

    trackAppVersion();

    // fetch device model name
    var d = DeviceInfo();
    d.init();

    var userState = context.read<UserState>();
    var matchesState = context.read<MatchesState>();

    await userState.fetchLoggedUserDetails();
    await matchesState.fetchLocation();

    storeAppInfo(userState);

    // preload GIFs for join-match celebration
    MiscController.getGifs(context.read<LoadOnceState>());

    FirebaseRemoteConfig firebaseRemoteConfig = FirebaseRemoteConfig.instance;
    await firebaseRemoteConfig.setDefaults({
      "allow_users_to_mark_payments": true,
      "allow_nutmeg_managed_payments": false,
    });
    await firebaseRemoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: Duration(seconds: 5),
      minimumFetchInterval: Duration(minutes: 1),
    ));

    try {
      await firebaseRemoteConfig.fetchAndActivate();
    } catch (e, s) {
      logger.severe("Error fetching and activating remote config", e, s);
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

    // navigate to next screen
    if (deepLink != null) {
      logger.info("navigating with deep link:" + deepLink.toString());
      handleLink(deepLink);
    } else if (initialMessage != null) {
      logger
          .info("navigating with initial message:" + initialMessage.toString());
      _handleMessageFromNotification(initialMessage);
    } else {
      // Trigger GoRouter to re-evaluate redirects; it will navigate to pendingRedirect
      loadingNotifier.value = !loadingNotifier.value;
    }

    _maybeShowAndroidInstallBanner();

    // trace.setMetric("duration_ms", stopwatch.elapsed.inMilliseconds);
    // await trace.stop();
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  logger.info(
      "Handling a background message: ${message.messageId} with data ${message.data.toString()}");
}
