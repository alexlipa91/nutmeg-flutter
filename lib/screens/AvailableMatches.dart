import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/AppBar.dart';
import 'package:nutmeg/widgets/Buttons.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/Texts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
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
      extendBodyBehindAppBar: true,
      body: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => SelectedTapNotifier()),
        ],
        child: Container(
          color: Palette.light,
          child: Column(
            children: [
              MainAppBar(),
              RoundedTopBar(),
              Expanded(child: MatchesArea())
            ],
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
          padding: EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Find football games in",
                  style: TextPalette.bodyTextInverted),
              Text("Amsterdam", style: TextPalette.h1Inverted),
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
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ContainerTitleText(text: "50% off"),
              Expanded(
                  child: Align(
                alignment: Alignment.topRight,
                child: InkWell(
                    child: Icon(Icons.close, size: 18),
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
                      MatchesAreaState.showNews = false;
                    }),
              ))
            ]),
            // SizedBox(height: 15),
            Text(
              "All games in Amsterdam are 50% off until Sept 4.",
              style: TextPalette.bodyText,
            )
          ],
        ),
      )),
    ]);
  }
}

class MatchesArea extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MatchesAreaState();
}

class MatchesAreaState extends State<MatchesArea> {
  bool isLoading = false;

  static bool showNews = true;

  @override
  Widget build(BuildContext context) {
    GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

    var optionSelected = context.watch<SelectedTapNotifier>().selected;
    var isLoggedIn = context.watch<UserChangeNotifier>().isLoggedIn();

    return (optionSelected == "MY GAMES" && !isLoggedIn)
        ? Center(
            child: Text("Login to join matches", style: TextPalette.bodyText),
          )
        : RefreshIndicator(
            onRefresh: () async {
              setState(() {
                isLoading = true;
              });
              await context.read<MatchesChangeNotifier>().refresh();
              setState(() {
                isLoading = false;
              });
            },
            child: Builder(builder: (BuildContext buildContext) {
              var widgets;
              if (!isLoading) {
                widgets = (optionSelected == "ALL")
                    ? allGamesWidgets(context)
                    : myGamesWidgets(context);
              } else {
                widgets = List<Widget>.filled(5, MatchInfoSkeleton());
              }

              return AnimatedList(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
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
        TextSeparatorWidget("No games to display. Book your first game today.")
      ];
    }

    var now = DateTime.now();

    List<Match> past = matches.where((m) => m.dateTime.isBefore(now)).toList();
    List<Match> future = matches.where((m) => m.dateTime.isAfter(now)).toList();

    List<Widget> widgets = [];

    if (future.isNotEmpty) {
      widgets.add(TextSeparatorWidget("UPCOMING GAMES"));
      future.sortedBy((e) => e.dateTime).forEachIndexed((index, m) {
        if (index == 0) {
          widgets.add(MatchInfo.first(m));
        } else {
          widgets.add(MatchInfo(m));
        }
      });
    }

    if (past.isNotEmpty) {
      widgets.add(TextSeparatorWidget("PAST GAMES"));
      past.sortedBy((e) => e.dateTime).forEachIndexed((index, m) {
        if (index == 0) {
          widgets.add(MatchInfoPast.first(m));
        } else {
          widgets.add(MatchInfoPast(m));
        }
      });
    }

    return widgets;
  }

  static List<Widget> allGamesWidgets(BuildContext context) {
    var matches = context.watch<MatchesChangeNotifier>().getMatchesInFuture();

    var grouped = matches.groupListsBy((m) => m.dateTime.weekOfYear);

    List<int> sortedWeeks = grouped.keys.toList()..sort();

    List<Widget> result = [];

    sortedWeeks.forEach((w) {
      result.add(WeekSeparatorWidget(w));
      grouped[w].sortedBy((e) => e.dateTime).forEachIndexed((index, match) {
        if (index == 0) {
          result.add(MatchInfo.first(match));
        } else {
          result.add(MatchInfo(match));
        }
      });
    });

    return result;
  }
}

// widget of info for a single match
class MatchInfo extends StatelessWidget {
  static var formatCurrency = NumberFormat.simpleCurrency(name: "EUR");
  static var monthDayFormat = DateFormat('HH:mm');

  final Match match;
  final double topMargin;

  MatchInfo(this.match) : topMargin = 10;

  MatchInfo.first(this.match) : topMargin = 0;

  @override
  Widget build(BuildContext context) {
    var sportCenter = context
        .read<SportCentersChangeNotifier>()
        .getSportCenter(match.sportCenter);

    return InkWell(
        child: Padding(
          padding: EdgeInsets.only(top: topMargin),
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
                        borderRadius: BorderRadius.all(Radius.circular(10)))),
                Expanded(
                  child: Container(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 16),
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
                                    style: TextPalette.h2),
                                Expanded(
                                    child: Text(
                                        (match.numPlayersGoing() ==
                                                match.maxPlayers)
                                            ? "Full"
                                            : (match.maxPlayers -
                                                        match.numPlayersGoing())
                                                    .toString() +
                                                " spots left",
                                        style: GoogleFonts.roboto(
                                            color: Palette.mediumgrey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400),
                                        textAlign: TextAlign.right))
                              ],
                            ),
                            Text(match.getFormattedDate(),
                                style: TextPalette.h3),
                            Text(sportCenter.name,
                                style: TextPalette.bodyTextOneLine),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ),
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

class MatchInfoSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 30),
      child: InfoContainer(
          child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey[300],
              highlightColor: Colors.grey[100],
              child: Container(
                  width: 60,
                  height: 78,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(10)))),
            ),
            Expanded(
              child: Container(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300],
                      highlightColor: Colors.grey[100],
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List<Widget>.filled(
                            3,
                            Row(
                              children: [
                                Expanded(
                                    child: Container(
                                  height: 10,
                                  width: 100,
                                  color: Colors.white,
                                ))
                              ],
                            ),
                          )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }
}

class MatchInfoPast extends StatelessWidget {
  static var formatCurrency = NumberFormat.simpleCurrency(name: "EUR");
  static var dayFormat = DateFormat('dd MMM');

  final Match match;
  final double topMargin;

  MatchInfoPast(this.match) : topMargin = 10;

  MatchInfoPast.first(this.match) : topMargin = 0;

  @override
  Widget build(BuildContext context) {
    var sportCenter = context
        .read<SportCentersChangeNotifier>()
        .getSportCenter(match.sportCenter);

    return InkWell(
        child: Padding(
          padding: EdgeInsets.only(top: topMargin),
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
                                style: TextPalette.h2),
                            SizedBox(height: 10),
                            Text(sportCenter.name, style: TextPalette.bodyText),
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
                        style: TextPalette.h4)
                  ],
                )),
              ],
            ),
          )),
        ),
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
      padding: EdgeInsets.only(top: 32, bottom: 16),
      child: Text(text, style: TextPalette.h4),
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
      return "THIS WEEK";
    }
    if (currentWeek + 1 == weekNumber) {
      return "NEXT WEEK";
    }
    return "IN MORE THAN TWO WEEKS";
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
