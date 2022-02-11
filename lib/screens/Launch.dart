import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/controller/SportCentersController.dart';
import 'package:nutmeg/controller/SportsController.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/screens/MatchDetails.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/screens/AvailableMatches.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/foundation.dart';

import 'MatchDetailsModals.dart';

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
        theme: appTheme,
        routes: {
          AvailableMatches.routeName: (context) => AvailableMatches(),
          MatchDetails.routeName: (context) => MatchDetails(),
        },
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
    if (!kIsWeb) {
      initDynamicLinks();
    }
  }

  Future<void> handleLink(Uri deepLink) async {
    print("handling dynamic link " + deepLink.toString());
    if (deepLink.path == "/payment") {
      var outcome = deepLink.queryParameters["outcome"];
      var matchId = deepLink.queryParameters["match_id"];

      var context = navigatorKey.currentContext;

      if (outcome == "success") {
        // fixme
        // Navigator.popUntil(context, (route) =>
        //   route.settings.name == MatchDetails.routeName
        //     ||
        //   route.isFirst
        // );

        // print(ModalRoute.of(context));

        // if (ModalRoute.of(context).isFirst) {
        //   await Navigator.of(context).pushNamedAndRemoveUntil(
        //       MatchDetails.routeName,
        //           (route) => route.isCurrent && route.settings.name == MatchDetails.routeName
        //           ? false
        //           : true,
        //     arguments: ScreenArguments(
        //       matchId,
        //       false
        //     ),
        //   );
        // }

        // Navigator.of(context).pushNamedAndRemoveUntil(
        //     MatchDetails.routeName,
        //         (route) => route.isCurrent && route.settings.name == MatchDetails.routeName
        //         ? false
        //         : true,
        //   arguments: ScreenArguments(
        //     matchId,
        //     false
        //   ),
        // );

        // Navigator.pushAndRemoveUntil(
        //     context,
        //     MaterialPageRoute(builder: (context) => MatchDetails(matchId)),
        //     (Route<dynamic> route) => route.isFirst
        // );

        await MatchesController.refresh(context.read<MatchesState>(), matchId);

        Navigator.pop(context);
        await communicateSuccessToUser(context, matchId);
      } else {
        Navigator.pop(context);

        await GenericInfoModal(
            title: "Payment Failed!",
            body: "Please try again or contact us for support")
            .show(context);
      }

      return;
    }
    if (deepLink.path == "/match") {
      print("handling link ");

      // todo check if propagates updates
      var match = navigatorKey.currentContext
          .read<MatchesState>()
          .getMatch(deepLink.queryParameters["id"]);

      await Navigator.pushNamed(
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
    print("app initialization tasks running");
    await Firebase.initializeApp();

    // fetch device model name
    var d = DeviceInfo();
    await d.init();

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

    await MatchesController.refreshAll(context.read<MatchesState>());
    await MatchesController.refreshImages(context.read<MatchesState>());

    await SportCentersController.refreshAll(context.read<LoadOnceState>());
    await SportsController.refreshAll(context.read<LoadOnceState>());
    await Future.delayed(Duration(seconds: 1));

    Uri deepLink;

    if (!kIsWeb) {
      // check if coming from link
      final PendingDynamicLinkData data =
          await FirebaseDynamicLinks.instance.getInitialLink();

      deepLink = data?.link;
    }

    if (deepLink != null) {
      await handleLink(deepLink);
    } else {
      await Navigator.pushReplacementNamed(context, AvailableMatches.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    var getVersionFuture = () async {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String version = packageInfo.version;
      return version;
    };

    return Scaffold(
        body: Container(
            decoration: BoxDecoration(
              color: Palette.primary,
            ),
            child: FutureBuilder<void>(
                future: loadData(context)
                //     .timeout(Duration(seconds: 20),
                //     onTimeout: () async {
                //   print("timeout");
                //   GenericInfoModal(
                //           title: "Something went wrong!",
                //           body: "Please check your connection")
                //       .show(context);
                //       // .then((value) => Navigator.of(context).pop());
                // })
                    .catchError((err, stacktrace) {
                  print(err);
                  print(stacktrace);
                  GenericInfoModal(
                          title: "Something went wrong!",
                          body: "Please contact us for support")
                      .show(context);
                }),
                builder: (context, snapshot) => (snapshot.hasError)
                    ? Text(snapshot.error.toString(),
                        style: TextPalette.linkStyleInverted)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset("assets/nutmeg_white.png",
                                          width: 116, height: 46),
                                      SizedBox(height: 30),
                                      CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white)),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FutureBuilder<String>(
                                      future: getVersionFuture(),
                                      builder: (context, snapshot) => Padding(
                                            padding:
                                                EdgeInsets.only(bottom: 20),
                                            child: Text(
                                                (snapshot.hasData)
                                                    ? snapshot.data
                                                    : "loading version number",
                                                style: TextPalette
                                                    .linkStyleInverted),
                                          )),
                                ])
                          ]))));
  }
}
