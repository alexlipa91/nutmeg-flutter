import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/models/MatchesModel.dart';
import 'package:nutmeg/models/UserModel.dart';
import 'package:provider/provider.dart';

import '../Utils.dart';
import 'AvailableMatches.dart';
import 'package:nutmeg/models/Model.dart';

import 'Login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  var matches = [
    Match(
        1,
        DateTime.parse("2020-05-21 18:00:00Z"),
        new SportCenter(
            "SportCentrum De Pijp", 52.34995155532827, 4.894433669187803),
        "5-aside",
        10,
        ["a", "b"],
        5.50,
        MatchStatus.open),
    Match(
        2,
        DateTime.parse("2020-05-22 18:00:00Z"),
        new SportCenter(
            "SportCentrum De Pijp", 52.34995155532827, 4.894433669187803),
        "5-aside",
        10,
        ["a", "b"],
        5.50,
        MatchStatus.canceled),
    Match(
        3,
        DateTime.parse("2020-05-12 18:00:00Z"),
        new SportCenter(
            "SportCentrum De Pijp", 52.34995155532827, 4.894433669187803),
        "5-aside",
        10,
        ["a", "b"],
        5.50,
        MatchStatus.played),
    Match(
        3,
        DateTime.parse("2020-05-11 18:00:00Z"),
        new SportCenter(
            "SportCentrum De Pijp", 52.34995155532827, 4.894433669187803),
        "5-aside",
        10,
        ["a", "b"],
        5.50,
        MatchStatus.played)
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
    return Column(
        children: [
          Text(context.watch<UserModel>().user.email[0].toUpperCase()),
          TextButton(
              child: Text("Logout"),
              onPressed: () {
                context.read<UserModel>().logout();
                Navigator.pop(context);
              })
    ]);
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
          .map<Widget>((e) => MatchInfo.withoutBadge(e.id, false))
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
          .map<Widget>((e) => MatchInfo.withoutBadge(e.id, false))
          .toList());
    } else {
      children.addAll([
        Text("No past matches", style: themeData.textTheme.bodyText1),
        SizedBox(height: 30)
      ]);
    }

    children.add(LoginOptionButton(
        text: "Logout",
        onTap: () {
          context.read<UserModel>().logout();
          Navigator.pop(context);
        }));

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
