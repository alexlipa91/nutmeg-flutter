import 'package:flutter/material.dart';
import 'package:nutmeg/Model.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/models/MatchesModel.dart';
import 'package:nutmeg/screens/MatchDetails.dart';
import 'package:provider/provider.dart';

import '../Utils.dart';

List<Match> getMatches() {
  return [
    Match(
        1,
        DateTime.parse("2020-05-21 18:00:00Z"),
        new SportCenter(
            "SportCentrum De Pijp", 52.34995155532827, 4.894433669187803),
        "5-aside",
        10,
        ["a", "b"],
        5.50),
    Match(
        2,
        DateTime.parse("2020-05-27 18:00:00Z"),
        new SportCenter("Het Marnix", 52.37814776657895, 4.878418555693728),
        "5-aside",
        10,
        [],
        6.0),
    Match(
        3,
        DateTime.parse("2020-05-31 18:00:00Z"),
        new SportCenter(
            "SportCentrum Zuidplas", 51.985700943649064, 4.658921084515437),
        "5-aside",
        10,
        ["a", "b", "c", "d"],
        7.00),
  ];
}

void main() {
  runApp(new MaterialApp(
      home: new AvailableMatches(),
      theme: appTheme));
}

class AvailableMatches extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    print("Building " + this.runtimeType.toString());

    final ThemeData themeData = Theme.of(context);

    return SafeArea(
        child: Container(
      decoration: new BoxDecoration(color: Colors.grey.shade400),
      child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: getAppBar(context),
          body: Column(children: [
            Container(
              margin: EdgeInsets.all(30.0),
              child: TextField(
                enabled: false,
                style: themeData.textTheme.headline3,
                decoration: InputDecoration(
                    contentPadding:
                        EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                    hintText: 'Amsterdam',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32.0))),
              ),
            ),
            Expanded(
              child:
                  Consumer<MatchesModel>(builder: (context, matches, child) {
                return ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8),
                  children: matches.matches
                      .map((e) => MatchInfo(matchId: e.id))
                      .toList(),
                );
              }),
            ),
          ])),
    ));
  }
}

class MatchInfo extends StatelessWidget {
  final int matchId;

  const MatchInfo({Key key, this.matchId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return InkWell(
      child: Consumer<MatchesModel>(
        builder: (context, matches, child) {
          Match match = matches.getMatch(matchId);

          return Container(
            color: Colors.transparent,
            padding: EdgeInsets.all(15.0),
            child: Column(
              children: [
                SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(match.sportCenter.name,
                        style: themeData.textTheme.bodyText1),
                    Text(DateFormat('HH:mm').format(match.dateTime),
                        style: themeData.textTheme.bodyText1)
                  ],
                ),
                SizedBox(height: 10.0),
                Row(
                  children: [
                    Text(match.sport, style: themeData.textTheme.bodyText2)
                  ],
                ),
                SizedBox(height: 10.0),
                Row(
                  children: [
                    Text(
                        match.joining.length.toString() +
                            " / " +
                            match.total.toString(),
                        style: themeData.textTheme.bodyText2)
                  ],
                )
              ],
            ),
          );
        }
      ),
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => MatchDetails(matchId)));
      },
      splashColor: Colors.white,
    );
  }
}
