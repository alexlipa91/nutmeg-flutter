import 'package:flutter/material.dart';
import 'package:nutmeg/models/Model.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/models/MatchesModel.dart';
import 'package:nutmeg/models/UserModel.dart';
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
        5.50,
        MatchStatus.open),
    Match(
        2,
        DateTime.parse("2020-05-27 18:00:00Z"),
        new SportCenter("Het Marnix", 52.37814776657895, 4.878418555693728),
        "5-aside",
        10,
        [],
        6.0,
        MatchStatus.open),
    Match(
        3,
        DateTime.parse("2020-05-27 19:00:00Z"),
        new SportCenter(
            "SportCentrum Zuidplas", 51.985700943649064, 4.658921084515437),
        "5-aside",
        10,
        ["a", "b", "c", "d"],
        7.00,
        MatchStatus.open),
  ];
}

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => UserModel()),
      ChangeNotifierProvider(create: (context) => MatchesModel(getMatches())),
    ],
    child: new MaterialApp(home: new AvailableMatches(), theme: appTheme),
  ));
}

class AvailableMatches extends StatelessWidget {

  _getMatchesWidget(List<Match> matches) {
    _isSameDay(DateTime a, DateTime b) {
      return a.day == b.day && a.month == b.month && a.year == b.year;
    }

    var widgets = [];
    for(int i = 0; i < matches.length; i++) {
      widgets.add(MatchInfo.withBadge(matches[i].id,
          i == 0 || !_isSameDay(matches[i].dateTime, matches[i-1].dateTime)));
    }

    return List<MatchInfo>.from(widgets);
  }

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
                    contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                    hintText: 'Amsterdam',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32.0))),
              ),
            ),
            Expanded(
              child: Consumer<MatchesModel>(builder: (context, matches, child) {
                return RefreshIndicator(
                  onRefresh: () {
                    return matches.refresh();
                  },
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    children: _getMatchesWidget(matches.matches)
                    // matches.matches
                    //     .map((e) => MatchInfo.withBadge(e.id, true))
                    //     .toList(),
                  ),
                );
              }),
            ),
          ])),
    ));
  }
}

class MatchInfo extends StatelessWidget {
  static var dateFormat = new DateFormat("MMMM dd");

  int matchId;
  bool showGoingWidget;
  bool showDate;

  MatchInfo.withoutBadge(int matchId, bool showDate) {
    this.matchId = matchId;
    this.showGoingWidget = false;
    this.showDate = showDate;
  }

  MatchInfo.withBadge(int matchId, bool showDate) {
    this.matchId = matchId;
    this.showGoingWidget = true;
    this.showDate = showDate;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return InkWell(
      child: Consumer2<MatchesModel, UserModel>(
          builder: (context, matches, user, child) {
        Match match = matches.getMatch(matchId);

        return Container(
          color: Colors.transparent,
          padding: EdgeInsets.all(15.0),
          child: Column(
            children: [
              if (showDate) Row(
                children: [
                  Text(dateFormat.format(match.dateTime), style: themeData.textTheme.headline1),
                  SizedBox(height: 10.0),
                ],
              ),
              SizedBox(height: 10.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      match.sportCenter.name,
                      style: themeData.textTheme.bodyText1),
                  Text(DateFormat('HH:mm').format(match.dateTime),
                      style: themeData.textTheme.bodyText1)
                ],
              ),
              SizedBox(height: 10.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(match.sport, style: themeData.textTheme.bodyText2),
                  if(showGoingWidget && user.isLoggedIn() && match.joining.contains(user.user.uid))
                    Container(
                      decoration: new BoxDecoration(color: Colors.green),
                      child: Padding(
                          padding: EdgeInsets.all(5),
                          child: Text("Going",
                              style: new TextStyle(color: Colors.white))))
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
      }),
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => MatchDetails(matchId)));
      },
      splashColor: Colors.white,
    );
  }
}