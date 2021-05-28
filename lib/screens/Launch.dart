import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/models/MatchesModel.dart';
import 'package:nutmeg/models/UserModel.dart';
import 'package:nutmeg/Utils.dart';
import 'package:nutmeg/screens/AvailableMatches.dart';
import 'package:provider/provider.dart';

void main() {

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => UserModel()),
      ChangeNotifierProvider(create: (context) => MatchesModel([]))
    ],
    child: new MaterialApp(
      debugShowCheckedModeBanner: false,
      home: new Container(
          decoration: new BoxDecoration(color: Colors.grey.shade400),
          child:
              Center(child: new LaunchWidget(newPage: new AvailableMatches()))),
      theme: appTheme,
    ),
  ));
}

Future<void> callAsyncFetch(BuildContext context) {
  return Future.delayed(Duration(seconds: 1), () async {
    await Firebase.initializeApp();
    await context.read<MatchesModel>().pull();
  });
}

class LaunchWidget extends StatefulWidget {
  final Widget newPage;

  const LaunchWidget({Key key, this.newPage}) : super(key: key);

  @override
  _LaunchWidgetState createState() => _LaunchWidgetState(newPage);
}

class _LaunchWidgetState extends State<LaunchWidget> {
  final Widget newPage;

  _LaunchWidgetState(this.newPage);

  @override
  void initState() {
    super.initState();
    callAsyncFetch(context).then((data) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => newPage));
    }).catchError((e) {
      Navigator.pop(context, "an error");
    });
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
