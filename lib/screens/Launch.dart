import 'package:cool_alert/cool_alert.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/screens/AvailableMatches.dart';
import 'package:provider/provider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kDebugMode;


void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => UserChangeNotifier()),
      ChangeNotifierProvider(create: (context) => MatchesChangeNotifier()),
      ChangeNotifierProvider(create: (context) => SportCentersChangeNotifier()),
    ],
    child: new MaterialApp(
      debugShowCheckedModeBanner: false,
      home: new Container(
          decoration: new BoxDecoration(color: Colors.grey.shade400),
          child: Center(child: new LaunchWidget())),
      theme: appTheme,
    ),
  ));
}

class LaunchWidget extends StatelessWidget {
  Future<void> loadData(BuildContext context) async {
    try {
      await Firebase.initializeApp();

      if (kDebugMode) {
        // Force disable Crashlytics collection while doing every day development.
        // Temporarily toggle this to true if you want to test crash reporting in your app.
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
      } else {
        // Handle Crashlytics enabled status when not in Debug,
        // e.g. allow your users to opt-in to crash reporting.
      }

      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

      // check if user is logged in
      await context.read<UserChangeNotifier>().loadUserIfAvailable();
      await context.read<MatchesChangeNotifier>().refresh();
      await context.read<SportCentersChangeNotifier>().refresh();
      await Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => AvailableMatches()));
    } on Exception catch (e, stacktrace) {
      FirebaseCrashlytics.instance.recordError(e, stacktrace, reason: "app launch failed");

      CoolAlert.show(
          context: context,
          type: CoolAlertType.error,
          text: "Something went wrong!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Palette.primary,
        ),
        child: FutureBuilder<void>(
          future: loadData(context),
          builder: (context, snapshot) => Center(
              child:
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Image.asset("assets/nutmeg_white.png", width: 116, height: 46),
                SizedBox(height: 30),
                CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              ])),
        ),
      ),
    );
  }
}
