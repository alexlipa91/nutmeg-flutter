import 'package:flutter/material.dart';
import 'package:nutmeg/models/Model.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/models/MatchesModel.dart';
import 'package:nutmeg/models/UserModel.dart';
import 'package:nutmeg/screens/MatchDetails.dart';
import 'package:provider/provider.dart';

import '../Utils.dart';

Map<String, Match> getMatches() {
  return {
    "1": Match(
        DateTime.parse("2020-05-21 18:00:00Z"),
        SportCenter.fromId("ChIJ3zv5cYsJxkcRAr4WnAOlCT4"),
        Sport.fiveAsideFootball,
        10,
        ["a", "b"],
        5.50,
        MatchStatus.open),
    "2": Match(
        DateTime.parse("2020-05-27 18:00:00Z"),
        SportCenter.fromId("ChIJM6a0ddoJxkcRsw7w54kvDD8"),
        Sport.fiveAsideFootball,
        10,
        [],
        6.0,
        MatchStatus.open),
    "3": Match(
        DateTime.parse("2020-05-27 19:00:00Z"),
        SportCenter.fromId("ChIJYVFYYbrTxUcRMSYDU4GLg5k"),
        Sport.fiveAsideFootball,
        10,
        ["a", "b", "c", "d"],
        7.00,
        MatchStatus.open),
  };
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

  final String loadingErrorMessage;

  const AvailableMatches({Key key, this.loadingErrorMessage}) : super(key: key);

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
            Expanded(child: (loadingErrorMessage != null) ?
            Text(loadingErrorMessage) : RefreshIndicatorStateful()),
          ])),
    ));
  }
}

class RefreshIndicatorStateful extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => RefreshIndicatorState();
}

class RefreshIndicatorState extends State<RefreshIndicatorStateful>
    with WidgetsBindingObserver {

  String fetchMatchesError;

  _getMatchesWidget(Map<String, Match> matches) {
    var entries = matches.entries.toList();
    entries.sort((a, b) => a.value.dateTime.compareTo(b.value.dateTime));

    var widgets = [];
    for (int i = 0; i < entries.length; i++) {
      widgets.add(MatchInfo.withBadge(entries[i].key,
          i == 0 || !isSameDay(matches[i].dateTime, matches[i - 1].dateTime)));
    }

    return List<MatchInfo>.from(widgets);
  }

  AppLifecycleState _appLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _appLifecycleState = state;
    });
    if (_appLifecycleState == AppLifecycleState.resumed) {
      refresh();
    }
  }

  Future<void> refresh() async {
    try {
      await context.read<MatchesModel>().pull();
    } on Exception catch (err) {
      print("Caught in refresh " + err.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        onRefresh: () async => await refresh(),
        child: (fetchMatchesError != null) ? Text(fetchMatchesError) : ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(8),
            children:
                _getMatchesWidget(context.watch<MatchesModel>().getMatches())));
  }
}

class MatchInfo extends StatelessWidget {
  static var dateFormat = new DateFormat("MMMM dd");

  String matchId;
  bool showGoingWidget;
  bool showDate;

  MatchInfo.withoutBadge(String matchId, bool showDate) {
    this.matchId = matchId;
    this.showGoingWidget = false;
    this.showDate = showDate;
  }

  MatchInfo.withBadge(String matchId, bool showDate) {
    this.matchId = matchId;
    this.showGoingWidget = true;
    this.showDate = showDate;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    Match match = context.watch<MatchesModel>().getMatch(matchId);

    return InkWell(
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.all(15.0),
        child: Column(
          children: [
            if (showDate)
              Row(
                children: [
                  Text(dateFormat.format(match.dateTime),
                      style: themeData.textTheme.headline1),
                  SizedBox(height: 10.0),
                ],
              ),
            SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(match.sportCenter.getName(),
                    style: themeData.textTheme.bodyText1),
                Text(DateFormat('HH:mm').format(match.dateTime),
                    style: themeData.textTheme.bodyText1)
              ],
            ),
            SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(match.sport.toString(),
                    style: themeData.textTheme.bodyText2),
                if (showGoingWidget &&
                    context.watch<UserModel>().isLoggedIn() &&
                    match.joining.contains(context.read<UserModel>().user.uid))
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
                        match.maxPlayers.toString(),
                    style: themeData.textTheme.bodyText2)
              ],
            )
          ],
        ),
      ),
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => MatchDetails(matchId)));
      },
      splashColor: Colors.white,
    );
  }
}
