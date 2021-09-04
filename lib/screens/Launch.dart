import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/screens/AvailableMatches.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/foundation.dart';

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
        ChangeNotifierProvider(create: (context) => UserChangeNotifier()),
        ChangeNotifierProvider(create: (context) => MatchesChangeNotifier()),
        ChangeNotifierProvider(
            create: (context) => SportCentersChangeNotifier()),
      ],
      child: new MaterialApp(
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

class LaunchWidget extends StatelessWidget {
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
    await context.read<UserChangeNotifier>().loadUserIfAvailable();
    await context.read<MatchesChangeNotifier>().refresh();
    await context.read<SportCentersChangeNotifier>().refresh();
    await Future.delayed(Duration(seconds: 3));

    await Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => AvailableMatches()));
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
