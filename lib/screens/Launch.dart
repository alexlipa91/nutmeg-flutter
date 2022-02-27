// @dart=2.9
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/controller/MiscController.dart';
import 'package:nutmeg/controller/SportCentersController.dart';
import 'package:nutmeg/controller/SportsController.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/screens/AvailableMatches.dart';
import 'package:nutmeg/screens/MatchDetails.dart';
import 'package:nutmeg/screens/PaymentDetailsDescription.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:version/version.dart';

import '../Exceptions.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized(); //imp line need to be added first

  if (!kIsWeb) {
    FlutterError.onError = (FlutterErrorDetails details) async {
      print("*** CAUGHT FROM FRAMEWORK ***");
      await FirebaseCrashlytics.instance.recordFlutterError(details);
    };
  }

  runZonedGuarded(() {
    runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserState()),
        ChangeNotifierProvider(create: (context) => MatchesState()),
        ChangeNotifierProvider(create: (context) => LoadOnceState()),
      ],
      child: new MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        home: new Container(
            decoration: new BoxDecoration(color: Colors.grey.shade400),
            child: Center(child: new LaunchWidget())),
        theme: new ThemeData(
            primaryColor: Palette.primary,
            accentColor: Palette.light
        ),
        routes: {
          AvailableMatches.routeName: (context) => AvailableMatches(),
          MatchDetails.routeName: (context) => MatchDetails(),
        },
      ),
    ));
  }, (Object error, StackTrace stackTrace) async {
    print("**** ZONED EXCEPTION ****");
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  });
}

class LaunchWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LaunchWidgetState();
}

class LaunchWidgetState extends State<LaunchWidget> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      initDynamicLinks();
    }
    loadData(context)
        .catchError((e, s) => ErrorHandlingUtils.handleError(e, s, context));
  }

  Future<void> handleLink(Uri deepLink) async {
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
        await MatchesController.refresh(context.read<MatchesState>(), context.read<UserState>(), matchId);
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

      var matchesState = context.read<MatchesState>();

      await MatchesController.init(matchesState);

      var match = matchesState.getMatch(deepLink.queryParameters["id"]);

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

  void initDynamicLinks() {
    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
      final Uri deepLink = dynamicLink?.link;

      if (deepLink != null) {
        handleLink(deepLink);
      }
    }, onError: (OnLinkErrorException e) async {
      print(e.message);
    });
  }

  Future<void> loadData(BuildContext context) async {
    await Firebase.initializeApp();

    FirebaseRemoteConfig firebaseRemoteConfig = FirebaseRemoteConfig.instance;
    firebaseRemoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: Duration(seconds: 5),
      minimumFetchInterval: Duration.zero,
    ));

    await firebaseRemoteConfig.fetchAndActivate();

    // fetch device model name
    var d = DeviceInfo();
    await d.init();

    // check if update is necessary
    var current = (await getVersion()).item1;
    var minimumVersionParts = firebaseRemoteConfig.getString("minimum_app_version").split(".");
    var minimumRequired = Version(int.parse(minimumVersionParts[0]),
        int.parse(minimumVersionParts[1]),
        int.parse(minimumVersionParts[2]));

    if (current < minimumRequired)
      throw OutdatedAppException();

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
    var userDetails = await UserController.getUserIfAvailable();

    if (userDetails != null) {
      context.read<UserState>().setUserDetails(userDetails);
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
      SportCentersController.refreshAll(context.read<LoadOnceState>()),
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

  @override
  Widget build(BuildContext context) {
    var images = Row(children: [
      Expanded(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            Align(
                alignment: Alignment.topLeft,
                child: SvgPicture.asset('assets/launch/blob_top_left.svg')),
            SvgPicture.asset('assets/launch/blob_middle_middle.svg',
                width: MediaQuery.of(context).size.width),
            Align(
                alignment: Alignment.bottomRight,
                child: SvgPicture.asset('assets/launch/blob_bottom_right.svg'))
          ]))
    ]);

    var mainWidgets =
        Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/nutmeg_white.png", width: 116, height: 46),
                SizedBox(height: 30),
                CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              ],
            )
          ],
        ),
      )
    ]);

    return Scaffold(
        body: Container(
            decoration: BoxDecoration(
              color: Palette.primary,
            ),
            child: Stack(children: [images, mainWidgets])
        )
    );
  }
}
