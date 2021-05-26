import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/models/MatchesModel.dart';
import 'package:nutmeg/models/UserModel.dart';
import 'package:nutmeg/screens/AddMatch.dart';
import 'package:nutmeg/screens/Login.dart';
import 'package:provider/provider.dart';

import '../Utils.dart';
import 'AvailableMatches.dart';
import 'package:nutmeg/models/Model.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  var matches = [
    Match(
        DateTime.parse("2020-05-21 18:00:00Z"),
        SportCenter.fromId("ChIJ3zv5cYsJxkcRAr4WnAOlCT4"),
        Sport.fiveAsideFootball,
        10,
        ["a", "b"],
        5.50,
        MatchStatus.open),
    Match(
        DateTime.parse("2020-05-27 18:00:00Z"),
        SportCenter.fromId("ChIJM6a0ddoJxkcRsw7w54kvDD8"),
        Sport.fiveAsideFootball,
        10,
        [],
        6.0,
        MatchStatus.open),
    Match(
        DateTime.parse("2020-05-27 19:00:00Z"),
        SportCenter.fromId("ChIJYVFYYbrTxUcRMSYDU4GLg5k"),
        Sport.fiveAsideFootball,
        10,
        ["a", "b", "c", "d"],
        7.00,
        MatchStatus.open),
  ];

  UserModel u = UserModel();
  await u.login("testtest@gmail.com", "testtest");

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => MatchesModel(matches)),
      ChangeNotifierProvider(create: (context) => u),
    ],
    child: new MaterialApp(
      home: UserPage(),
      theme: appTheme,
    ),
  ));
}

class UserPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    print("Building " + this.runtimeType.toString());

    final ThemeData themeData = Theme.of(context);

    return SafeArea(
            child: Container(
                decoration: new BoxDecoration(color: Colors.grey.shade400),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Expanded(flex: 1, child: UserImage()),
                  Text("Name", style: themeData.textTheme.headline1),
                  Divider(height: 50),
                  Expanded(
                      flex: 3,
                      child: Container(
                          decoration:
                              new BoxDecoration(color: Colors.grey.shade400),
                          child: MatchList(
                              matches: context
                                  .watch<MatchesModel>()
                                  .matches
                                  .where((element) => element.joining.contains(
                                      context.read<UserModel>().user.uid))
                                  .toList()))),
                ])));
  }
}

class UserImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: new BoxDecoration(color: Colors.grey.shade400),
        margin: EdgeInsets.all(30),
        child: CircleAvatar(
            backgroundColor: Colors.purple,
            radius: 40,
            child: FittedBox(
                child: Text(
                    context.read<UserModel>().user.email[0].toUpperCase(),
                    style: TextStyle(color: Colors.white, fontSize: 45))
            )));
  }
}

class MatchList extends StatelessWidget {
  final List<Match> matches;
  final String title;

  const MatchList({Key key, this.matches, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    var open =
        matches.where((element) => element.status == MatchStatus.open).toList();
    var played = matches
        .where((element) => element.status == MatchStatus.played)
        .toList();

    var children = [];

    children.addAll([
      Text("Upcoming matches", style: themeData.textTheme.headline1),
      SizedBox(height: 30)
    ]);

    if (open.isNotEmpty) {
      children.addAll(open
          .map<Widget>((e) => MatchInfo.withoutBadge(e, false))
          .toList());
    } else {
      children.addAll([
        Text("No upcoming matches", style: themeData.textTheme.bodyText1),
        SizedBox(height: 30)
      ]);
    }

    children.addAll([
      Text("Past Matches", style: themeData.textTheme.headline1),
      SizedBox(height: 30)
    ]);

    if (played.isNotEmpty) {
      children.addAll(played
          .map<Widget>((e) => MatchInfo.withoutBadge(e, false))
          .toList());
    } else {
      children.addAll([
        Text("No past matches", style: themeData.textTheme.bodyText1),
        SizedBox(height: 30)
      ]);
    }

    children.add(LogoutButton());

    if (context.read<UserModel>().isAdmin) {
      children.add(LoginOptionButton(text: "Add match",
          onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => new AddMatch()));
      }));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
          child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List<Widget>.from(children)),
      )),
    );
  }
}

class LogoutButton extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<LogoutButton> {
  bool _isSigningOut = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Container(
      margin: EdgeInsets.all(30.0),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
                onPressed: () async {
                  setState(() {
                    _isSigningOut = true;
                  });

                  await context.read<UserModel>().logout();
                  await Future.delayed(Duration(milliseconds: 500));

                  setState(() {
                    _isSigningOut = false;
                  });

                  Navigator.pop(context);
                },
                child: _isSigningOut
                    ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                    : Text(
                  "Logout",
                ),
                style: ButtonStyle(
                    side: MaterialStateProperty.all(
                        BorderSide(width: 2, color: Colors.grey)),
                    foregroundColor: MaterialStateProperty.all(Colors.black),
                    backgroundColor: MaterialStateProperty.all(Colors.grey),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        )),
                    padding: MaterialStateProperty.all(
                        EdgeInsets.symmetric(vertical: 10, horizontal: 50)),
                    textStyle: MaterialStateProperty.all(
                        themeData.textTheme.headline3))),
          )
        ],
      ),
    );
  }
}

