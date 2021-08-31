import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/screens/AvailableMatches.dart';
import 'package:provider/provider.dart';


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
    await Firebase.initializeApp();

    // check if user is logged in
    await context.read<UserChangeNotifier>().loadUserIfAvailable();
    await context.read<MatchesChangeNotifier>().refresh();
    await context.read<SportCentersChangeNotifier>().refresh();
    await Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AvailableMatches()));
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
