import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/AppBar.dart';
import 'package:nutmeg/widgets/Buttons.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:provider/provider.dart';
import 'package:week_of_year/week_of_year.dart';
import "package:collection/collection.dart";

import 'MatchDetails.dart';

// use this main for testing only
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  var matchesChangeNotifier = MatchesChangeNotifier();
  var sportCenterChangeNotifier = SportCentersChangeNotifier();

  await matchesChangeNotifier.refresh();
  await sportCenterChangeNotifier.refresh();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => UserChangeNotifier()),
      ChangeNotifierProvider(create: (context) => matchesChangeNotifier),
      ChangeNotifierProvider(create: (context) => sportCenterChangeNotifier),
      ChangeNotifierProvider(create: (context) => LocationChangeNotifier()),
    ],
    child: new MaterialApp(
        debugShowCheckedModeBanner: false, home: AvailableMatches()),
  ));
}

// main widget
class AvailableMatches extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => SelectedTapNotifier()),
        ],
        child: SafeArea(
          child: Container(
            color: Palette.lightGrey,
            child: Column(
              children: [
                MainAppBar(),
                // this must be as high as the app bar (a bit higher is better) because of an annoying issue https://github.com/flutter/flutter/issues/16262
                RoundedTopBar(),
                SizedBox(height: 10),
                Expanded(child: MatchesArea())
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RoundedTopBar extends StatelessWidget {
  _getAllFunction(BuildContext context) =>
      () => context.read<SelectedTapNotifier>().changeToAll();

  _getMyGamesFunction(BuildContext context) =>
      () => context.read<SelectedTapNotifier>().changeToMyGames();

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: Palette.primary,
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20))),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              Text("Find football games in", style: TextPalette.h2White),
              Text("Amsterdam", style: TextPalette.h1White),
              SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                context.watch<SelectedTapNotifier>().getCurrentSelection() ==
                        "ALL"
                    ? Expanded(
                        child: LeftButtonOn("ALL", _getAllFunction(context)))
                    : Expanded(
                        child: LeftButtonOff("ALL", _getAllFunction(context))),
                context.watch<SelectedTapNotifier>().getCurrentSelection() ==
                        "ALL"
                    ? Expanded(
                        child: RightButtonOff(
                            "MY GAMES", _getMyGamesFunction(context)))
                    : Expanded(
                        child: RightButtonOn(
                            "MY GAMES", _getMyGamesFunction(context))),
              ])
            ],
          ),
        ));
  }
}

class News extends StatelessWidget {
  // fixme pass news from db

  final GlobalKey<AnimatedListState> _listKey;

  News(this._listKey);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child: InfoContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text("50% off", style: TextPalette.h1Black),
              Expanded(
                  child: Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                          child: Icon(Icons.close),
                          onTap: () {
                            _listKey.currentState.removeItem(0, (_, animation) {
                              // fixme check if there's something better around
                              return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(-3, 0),
                                    end: Offset(0, 0),
                                  ).animate(animation),
                                  child: News(_listKey));
                            }, duration: Duration(milliseconds: 500));
                            MatchesArea.showNews = false;
                          })))
            ]),
            SizedBox(height: 15),
            Text(
              "All games in Amsterdam are 50% off until Sept 4.",
              style: TextPalette.bodyText2Gray,
            )
          ],
        ),
      )),
    ]);
  }
}

class MatchesArea extends StatelessWidget {
  static bool showNews = true;

  @override
  Widget build(BuildContext context) {
    GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

    var optionSelected = context.watch<SelectedTapNotifier>().selected;
    var isLoggedIn = context.watch<UserChangeNotifier>().isLoggedIn();

    return (optionSelected == "MY GAMES" && !isLoggedIn)
        ? Center(
            child:
                Text("Login to join matches", style: TextPalette.bodyText2Gray),
          )
        : RefreshIndicator(
            onRefresh: () async {
              await context.read<MatchesChangeNotifier>().refresh();
              await context.read<LocationChangeNotifier>().refresh();
            },
            child: Builder(builder: (BuildContext buildContext) {
              var widgets = (optionSelected == "ALL")
                  ? allGamesWidgets(context)
                  : myGamesWidgets(context);

              return AnimatedList(
                key: _listKey,
                initialItemCount:
                    (showNews) ? widgets.length + 1 : widgets.length,
                itemBuilder: (context, index, animation) {
                  if (showNews) {
                    return (index == 0)
                        ? SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(-1, 0),
                              end: Offset(0, 0),
                            ).animate(animation),
                            child: News(_listKey))
                        : widgets[index - 1];
                  }
                  return widgets[index];
                },
              );
            }),
          );
  }

  static List<Widget> myGamesWidgets(BuildContext context) {
    var matches = context.watch<MatchesChangeNotifier>().getMatches().where(
        (m) => m
            .isUserGoing(context.watch<UserChangeNotifier>().getUserDetails()));

    if (matches.isEmpty) {
      return [
        SizedBox(height: 50),
        TextSeparatorWidget("No games to display. Book your first game today.")
      ];
    }

    var now = DateTime.now();
    var past = matches.where((m) => m.dateTime.isBefore(now));
    var future = matches.where((m) => m.dateTime.isAfter(now));

    List<Widget> widgets = [];

    if (past.isNotEmpty) {
      widgets.add(TextSeparatorWidget("Past matches"));
      widgets.addAll(
          past.sortedBy((e) => e.dateTime).map((e) => MatchInfoPast(e)));
    }

    if (future.isNotEmpty) {
      widgets.add(TextSeparatorWidget("Upcoming matches"));
      widgets
          .addAll(future.sortedBy((e) => e.dateTime).map((e) => MatchInfo(e)));
    }

    return widgets;
  }

  static List<Widget> allGamesWidgets(BuildContext context) {
    var matches = context.watch<MatchesChangeNotifier>().getMatchesInFuture();
    var grouped = matches.groupListsBy((m) => m.dateTime.weekOfYear);

    List<int> sortedWeeks = grouped.keys.toList()..sort();

    return sortedWeeks
        .map((w) {
          List<Widget> l = [];
          l.add(WeekSeparatorWidget(w));
          l.addAll(
              grouped[w].sortedBy((e) => e.dateTime).map((e) => MatchInfo(e)));
          return l;
        })
        .flattened
        .toList();
  }
}

// widget of info for a single match
class MatchInfo extends StatelessWidget {
  static var formatCurrency = NumberFormat.simpleCurrency(name: "EUR");
  static var monthDayFormat = DateFormat('HH:mm');

  final Match match;

  MatchInfo(this.match);

  @override
  Widget build(BuildContext context) {
    var sportCenter = context
        .read<SportCentersChangeNotifier>()
        .getSportCenter(match.sportCenter);

    return InkWell(
        child: InfoContainer(
            child: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  width: 60,
                  height: 78,
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage(
                              "assets/sportcentertest_thumbnail.png")),
                      color: Colors.grey,
                      borderRadius: BorderRadius.all(Radius.circular(15)))),
              Expanded(
                child: Container(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                  sportCenter.neighbourhood +
                                      " - " +
                                      match.sport.getDisplayTitle(),
                                  style: TextPalette.h2Black),
                              Expanded(
                                  child: Text(
                                      (match.numPlayersGoing() ==
                                              match.maxPlayers)
                                          ? "Full"
                                          : (match.maxPlayers -
                                                      match.numPlayersGoing())
                                                  .toString() +
                                              " spots left",
                                      style: TextPalette.bodyText2Gray,
                                      textAlign: TextAlign.right))
                            ],
                          ),
                          Text(match.getFormattedDate(),
                              style: TextPalette.bodyText2Black),
                          Text(sportCenter.name,
                              style: TextPalette.bodyText2Gray),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Container(
              //     child: Column(
              //   children: [
              //     Text(
              //         (match.numPlayersGoing() == match.maxPlayers)
              //             ? "Full"
              //             : (match.maxPlayers - match.numPlayersGoing())
              //                     .toString() +
              //                 " spots left",
              //         style: TextPalette.bodyText2Gray)
              //   ],
              // )),
            ],
          ),
        )),
        onTap: () async {
          // fixme why it doesn't rebuild here?
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MatchDetails(context
                      .watch<MatchesChangeNotifier>()
                      .getMatch(match.documentId))));
          await context.read<MatchesChangeNotifier>().refresh();
        });
  }
}

class MatchInfoPast extends StatelessWidget {
  static var formatCurrency = NumberFormat.simpleCurrency(name: "EUR");
  static var dayFormat = DateFormat('dd MMM');

  final Match match;

  // fixme currently passing null, we need to figure it out in the UI
  // LocationData locationData;

  MatchInfoPast(this.match);

  @override
  Widget build(BuildContext context) {
    var sportCenter = context
        .read<SportCentersChangeNotifier>()
        .getSportCenter(match.sportCenter);

    return InkWell(
        child: InfoContainer(
            child: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              sportCenter.neighbourhood +
                                  " - " +
                                  match.sport.getDisplayTitle(),
                              style: TextPalette.h2Black),
                          SizedBox(height: 10),
                          Text(sportCenter.name,
                              style: TextPalette.bodyText2Gray),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                  child: Column(
                children: [
                  Text(dayFormat.format(match.dateTime),
                      style: TextPalette.primaryInButton)
                ],
              )),
            ],
          ),
        )),
        onTap: () async {
          // fixme why it doesn't rebuild here?
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MatchDetails(context
                      .watch<MatchesChangeNotifier>()
                      .getMatch(match.documentId))));
          await context.read<MatchesChangeNotifier>().refresh();
        });
  }
}

class TextSeparatorWidget extends StatelessWidget {
  final String text;

  const TextSeparatorWidget(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 3),
      child: Text(text,
          style: TextStyle(
              color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w400)),
    );
  }
}

class WeekSeparatorWidget extends StatelessWidget {
  final int weekNumber;

  const WeekSeparatorWidget(this.weekNumber);

  @override
  Widget build(BuildContext context) => TextSeparatorWidget(_getWeekDesc());

  _getWeekDesc() {
    var currentWeek = DateTime.now().weekOfYear;

    if (currentWeek == weekNumber) {
      return "This week";
    }
    if (currentWeek + 1 == weekNumber) {
      return "Next week";
    }
    return "In more than two weeks";
  }
}

// utility to manage the change between all/my games
class SelectedTapNotifier extends ChangeNotifier {
  String selected = "ALL";

  void changeToAll() => _change("ALL");

  void changeToMyGames() => _change("MY GAMES");

  void _change(String newSelection) {
    selected = newSelection;
    notifyListeners();
  }

  String getCurrentSelection() => selected;
}
