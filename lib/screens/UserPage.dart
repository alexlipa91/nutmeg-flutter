import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/ButtonWidgets.dart';
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

  UserModel u = UserModel();
  await u.login("testtest@gmail.com", "testtest");

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => MatchesModel(getMatches())),
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
                              matches: Map.fromEntries(context
                                  .watch<MatchesModel>()
                                  .getMatches()
                                  .entries
                                  .where((element) => element.value.joining.contains(
                                      context.read<UserModel>().user.uid)))))),
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
  final Map<String, Match> matches;
  final String title;

  const MatchList({Key key, this.matches, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    var open =
        matches.entries.where((element) => element.value.status == MatchStatus.open).toList();
    var played = matches.entries
        .where((element) => element.value.status == MatchStatus.played)
        .toList();

    var children = [];

    children.addAll([
      Text("Upcoming matches", style: themeData.textTheme.headline1),
      SizedBox(height: 30)
    ]);

    if (open.isNotEmpty) {
      children.addAll(open
          .map<Widget>((e) => MatchInfo.withoutBadge(e.key, false))
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
          .map<Widget>((e) => MatchInfo.withoutBadge(e.key, false))
          .toList());
    } else {
      children.addAll([
        Text("No past matches", style: themeData.textTheme.bodyText1),
        SizedBox(height: 30)
      ]);
    }

    children.add(ButtonWithLoaderAndPop(
        text: "Logout",
        onPressedFunction: () => context.read<UserModel>().logout()));

    if (context.read<UserModel>().userDetails.isAdmin) {
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
