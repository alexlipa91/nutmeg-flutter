import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/screens/admin/AddOrEditMatch.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/AppBar.dart';
import 'package:nutmeg/widgets/Buttons.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/Texts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import "package:collection/collection.dart";


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
    child:
        new MaterialApp(debugShowCheckedModeBanner: false, home: AdminAvailableMatches()),
  ));
}

// main widget
class AdminAvailableMatches extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => SelectedTapNotifier()),
        ],
        child: SafeArea(
          child: Container(
            color: Palette.light,
            child: Column(
              children: [
                AdminAreaAppBar(),
                RoundedTopBar(),
                Expanded(child: MatchesArea())
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) => Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      RoundedButton("ADD MATCH", () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => AddOrEditMatch()));
                      }),
                      RoundedButton("ADD SPORT CENTER", () {}),
                    ],
                  ));
        },
        child: Icon(Icons.add, color: Colors.white, size: 29),
        backgroundColor: Palette.primary,
        tooltip: 'Capture Picture',
        elevation: 5,
        splashColor: Colors.grey,
      ),
    );
  }
}

class RoundedTopBar extends StatelessWidget {
  _getUpcomingFunction(BuildContext context) =>
      () => context.read<SelectedTapNotifier>().change(Selection.UPCOMING);

  _getPastFunction(BuildContext context) =>
      () => context.read<SelectedTapNotifier>().change(Selection.PAST);

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
                        Selection.UPCOMING
                    ? Expanded(
                        child: LeftButtonOn(
                            "UPCOMING", _getUpcomingFunction(context)))
                    : Expanded(
                        child: LeftButtonOff(
                            "UPCOMING", _getUpcomingFunction(context))),
                context.watch<SelectedTapNotifier>().getCurrentSelection() ==
                        Selection.UPCOMING
                    ? Expanded(
                        child:
                            RightButtonOff("PAST", _getPastFunction(context)))
                    : Expanded(
                        child:
                            RightButtonOn("PAST", _getPastFunction(context))),
              ])
            ],
          ),
        ));
  }
}

class MatchesArea extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MatchesAreaState();
}

class MatchesAreaState extends State<MatchesArea> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    var matches = context.watch<MatchesChangeNotifier>().getMatches();
    var now = DateTime.now();

    GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

    var optionSelected = context.watch<SelectedTapNotifier>().selected;

    return RefreshIndicator(
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
          widgets = (optionSelected == Selection.UPCOMING)
              ? getGamesWidgets(context,
                  matches.where((m) => m.dateTime.isAfter(now)).toList())
              : getGamesWidgets(context,
                  matches.where((m) => m.dateTime.isBefore(now)).toList());
        } else {
          widgets = List<Widget>.filled(5, MatchInfoSkeleton());
        }

        return AnimatedList(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            key: _listKey,
            initialItemCount: widgets.length,
            itemBuilder: (context, index, animation) => widgets[index]);
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
          widgets.add(MatchInfo.first(m));
        } else {
          widgets.add(MatchInfo(m));
        }
      });
    }

    return widgets;
  }

  static List<Widget> getGamesWidgets(
      BuildContext context, List<Match> matches) {
    List<Widget> result = [];

    matches.sortedBy((e) => e.dateTime).forEachIndexed((index, match) {
      if (index == 0) {
        result.add(MatchInfo.first(match));
      } else {
        result.add(MatchInfo(match));
      }
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
                            Text(
                                match.status
                                    .toString()
                                    .split(".")
                                    .last
                                    .toUpperCase(),
                                style: TextPalette.linkStyle),
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
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => AddOrEditMatch(match: match)));
          await context.read<MatchesChangeNotifier>().refresh();
        });
  }
}

// skeleton for loading
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

enum Selection { UPCOMING, PAST }

// utility to manage the change between all/my games
class SelectedTapNotifier extends ChangeNotifier {
  Selection selected = Selection.UPCOMING;

  void change(Selection newSelection) {
    selected = newSelection;
    notifyListeners();
  }

  Selection getCurrentSelection() => selected;
}
