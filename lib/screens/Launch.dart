import 'package:flutter/material.dart';
import 'package:nutmeg/Authentication.dart';
import 'package:nutmeg/Utils.dart';
import 'package:nutmeg/screens/AvailableMatches.dart';
import 'package:provider/provider.dart';


void main() {
  runApp(ChangeNotifierProvider(
    create: (context) => UserModel(),
    child: new MaterialApp(
      debugShowCheckedModeBanner: false,
      home: new Container(
          decoration: new BoxDecoration(color: Colors.grey.shade400),
          child: Center(
              child: new LaunchWidget(
                  newPage: new AvailableMatches(matches: getMatches())))),
      theme: appTheme,
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
