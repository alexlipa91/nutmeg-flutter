import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/controller/SportCentersController.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/screens/MatchDetails.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/screens/AvailableMatches.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/foundation.dart';

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
        ChangeNotifierProvider(
            create: (context) => SportCentersState()),
      ],
      child: new MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        home: new Container(
            decoration: new BoxDecoration(color: Colors.grey.shade400),
            child: Center(child: new LaunchWidget())),
        theme: appTheme,
      ),
    ));
  }, (Object error, StackTrace stackTrace) {
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
    initDynamicLinks();
  }

  Future<void> handleLink(Uri deepLink) async {
    if (deepLink.queryParameters.containsKey("id")) {
      print("handling link ");

      // todo check if propagates updates
      var match = navigatorKey.currentContext.read<MatchesState>().getMatch(deepLink.queryParameters["id"]);

      Navigator.pushReplacement(
          navigatorKey.currentContext,
          MaterialPageRoute(
              builder: (context) => MatchDetails(match.documentId)));
    }
  }

  void initDynamicLinks() {
    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
          final Uri deepLink = dynamicLink?.link;

          if (deepLink != null) {
            handleLink(deepLink);
          }
        },
        onError: (OnLinkErrorException e) async {
          print(e.message);
        }
    );
  }

  Future<void> loadData(BuildContext context) async {
    print("app initialization tasks running");
    await Firebase.initializeApp();

    if (kDebugMode) {
      // Force disable Crashlytics collection while doing every day development.
      // Temporarily toggle this to true if you want to test crash reporting in your app.
      if (!kIsWeb) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
      }
    } else {
      // Handle Crashlytics enabled status when not in Debug,
      // e.g. allow your users to opt-in to crash reporting.
    }

    // check if user is logged in
    var userDetails = await UserController.getUserIfAvailable();
    if (userDetails != null) {
      context.read<UserState>().setUserDetails(userDetails);
    }

    await MatchesController.refreshAll(context.read<MatchesState>());
    await SportCentersController.refreshAll(context.read<SportCentersState>());
    await Future.delayed(Duration(seconds: 1));

    // check if coming from link
    final PendingDynamicLinkData data = await FirebaseDynamicLinks.instance.getInitialLink();

    final Uri deepLink = data?.link;

    if (deepLink != null) {
      await handleLink(deepLink);
    } else {
      await Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => AvailableMatches()));
    }
  }

  @override
  Widget build(BuildContext context) {
    var getVersionFuture = () async {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String version = packageInfo.version;
      String code = packageInfo.buildNumber;
      return version + " " + code;
    };

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Palette.primary,
        ),
        child: FutureBuilder<void>(
          future: loadData(context).catchError((err, stacktrace) {
            print(err);
            defaultErrorMessage(err, context);
          }),
          builder: (context, snapshot) => (snapshot.hasError)
              ? Text(snapshot.error.toString(),
                  style: TextPalette.linkStyleInverted)
              : Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Image.asset("assets/nutmeg_white.png",
                          width: 116, height: 46),
                      SizedBox(height: 30),
                      CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white)),
                      FutureBuilder<String>(
                          future: getVersionFuture(),
                          builder: (context, snapshot) => Text(
                              (snapshot.hasData)
                                  ? snapshot.data
                                  : "loading version number",
                              style: TextPalette.linkStyleInverted))
                    ])),
        ),
      ),
    );
  }
}
