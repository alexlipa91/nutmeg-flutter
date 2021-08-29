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

Future<void> callAsyncFetch(BuildContext context) {
  Future<void> Function() loadFunction = () async {
    await Firebase.initializeApp();

    // check if user is logged in
    await context.read<UserChangeNotifier>().loadUserIfAvailable();

    await context.read<MatchesChangeNotifier>().refresh();
    await context.read<SportCentersChangeNotifier>().refresh();
  };

  return Future.delayed(Duration(seconds: 1), loadFunction);
}

class LaunchWidget extends StatefulWidget {
  @override
  _LaunchWidgetState createState() => _LaunchWidgetState();
}

class _LaunchWidgetState extends State<LaunchWidget> {

  @override
  void initState() {
    super.initState();
    callAsyncFetch(context)
        .then((matches) => matches) // no error message here
        .catchError((onError) => onError.toString())
        .then((matches) => Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => AvailableMatches())));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Palette.primary,
        ),
        child: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.asset("assets/nutmeg_white.png", width: 116, height: 46),
          SizedBox(height: 30),
          CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
        ])),
      ),
    );
  }
}
