import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/models/MatchesModel.dart';
import 'package:nutmeg/models/SubscriptionsModel.dart';
import 'package:nutmeg/models/UserModel.dart';
import 'package:nutmeg/Utils.dart';
import 'package:nutmeg/screens/AvailableMatches.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => UserModel()),
      ChangeNotifierProvider(create: (context) => SubscriptionsBloc()),
      ChangeNotifierProvider(create: (context) => MatchesModel()),
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
  return Future.delayed(Duration(seconds: 1), () async {
    await Firebase.initializeApp();
    await context.read<MatchesModel>().update();
    await context.read<SubscriptionsBloc>().update();
  });
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
        .then((data) => Future<String>.value(null)) // no error message here
        .catchError((onError) => onError.toString())
        .then((errorMessage) => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider(
                    create: (context) => FilterButtonState(FilterOption.ALL),
                    child: AvailableMatches()))));
  }

  @override
  Widget build(BuildContext context) {
    print("Building " + this.runtimeType.toString());

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          image: DecorationImage(
            image: AssetImage("assets/running_football.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}
