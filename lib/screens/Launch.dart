import 'package:flutter/material.dart';

import '../model.dart';
import 'MatchDetails.dart';

void main() {
  runApp(new MaterialApp(
    debugShowCheckedModeBanner: false,
    home: new Container(
        decoration: new BoxDecoration(color: Colors.grey.shade400),
        child: Center(
            child: new LaunchWidget(
                newPage: new MatchDetails(Match(
                    DateTime.parse("2020-05-21 18:00:00Z"),
                    new SportCenter("SportCentrum De Pijp", 52.34995155532827,
                        4.894433669187803),
                    "5-aside",
                    10,
                    4,
                    5.50))))),
    theme: new ThemeData(
      primaryColor: Colors.black,
      accentColor: Colors.blueAccent,
      textTheme: TextTheme(
          headline1: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w700, fontSize: 22),
          headline2: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w500, fontSize: 18),
          headline3: TextStyle(
              color: Colors.purple, fontWeight: FontWeight.w700, fontSize: 18),
          bodyText1: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
          bodyText2: TextStyle(
              color: Colors.black, fontSize: 12, fontWeight: FontWeight.w500)),
      fontFamily: "Montserrat",
    ),
  ));
}

Future<String> callAsyncFetch() {
  return Future.delayed(Duration(seconds: 3), () => "hi");
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
    callAsyncFetch().then((data) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => newPage));
    }).catchError((e) {
      Navigator.pop(context, "an error");
    });
  }

  @override
  Widget build(BuildContext context) {
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
