import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/AppBar.dart';
import 'package:nutmeg/widgets/Buttons.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/Texts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:week_of_year/week_of_year.dart';
import "package:collection/collection.dart";

import 'MatchDetails.dart';

// main widget
class AvailableMatches extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(providers: [
      ChangeNotifierProvider(create: (context) => AvailableMatchesUiState()),
    ], child: AvailableMatchesList());
  }
}

class AvailableMatchesList extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    var matchesState = context.watch<MatchesState>();
    var userState = context.watch<UserState>();
    var uiState = context.watch<AvailableMatchesUiState>();

    var optionSelected = uiState.selected;

    var isLoggedIn = userState.isLoggedIn();

    var widgets = List<Widget>.of([
      MainAppBar(),
      RoundedTopBar(uiState: uiState)
    ]);

    if (!context.watch<AvailableMatchesUiState>().loading) {
      if (optionSelected == "MY GAMES" && !isLoggedIn) {
        widgets.add(Center(
            child: Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text("LOGIN TO JOIN MATCHES", style: TextPalette.h4)),
          ));
      } else {
        widgets.addAll((optionSelected == "ALL")
            ? allGamesWidgets(matchesState)
            : myGamesWidgets(matchesState, userState));
      }
    } else {
      widgets.addAll(List<Widget>.filled(5, MatchInfoSkeleton()));
    }

    return Scaffold(
      backgroundColor: Palette.white,
      // appBar: MainAppBar(),
      body: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => AvailableMatchesUiState()),
        ],
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<AvailableMatchesUiState>().startLoading();

            await MatchesController.refreshAll(matchesState);
            await MatchesController.refreshImages(matchesState);

            context.read<AvailableMatchesUiState>().loadingDone();
          },
          child: CustomScrollView(
            slivers: [
              // MainAppBar(),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return widgets[index];
                  },
                  childCount: widgets.length,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> myGamesWidgets(MatchesState state, UserState userState) {
    var matches = state.getMatches().where((m) {
      var userSubInMatch = m.getUserSub(userState.getUserDetails());
      return userSubInMatch != null &&
          userSubInMatch.status == SubscriptionStatus.going;
    });

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
          widgets.add(
              MatchInfo.first(m.documentId, state.getImageUrl(m.documentId)));
        } else {
          widgets.add(MatchInfo(m.documentId, state.getImageUrl(m.documentId)));
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

  List<Widget> allGamesWidgets(MatchesState state) {
    var matches =
        state.getMatchesInFuture().where((e) => !e.wasCancelled()).toList();

    if (matches.isEmpty) {
      return [TextSeparatorWidget("No upcoming games to display.")];
    }

    var grouped = matches.groupListsBy((m) => m.dateTime.weekOfYear);

    List<int> sortedWeeks = grouped.keys.toList()..sort();

    List<Widget> result = [];

    sortedWeeks.forEach((w) {
      result.add(WeekSeparatorWidget(w));
      grouped[w].sortedBy((e) => e.dateTime).forEachIndexed((index, match) {
        if (index == 0) {
          result.add(MatchInfo.first(
              match.documentId, state.getImageUrl(match.documentId)));
        } else {
          result.add(
              MatchInfo(match.documentId, state.getImageUrl(match.documentId)));
        }
      });
    });

    result.add(result.last);
    result.add(result.last);
    result.add(result.last);
    result.add(result.last);
    result.add(result.last);

    return result;
  }
}

class RoundedTopBar extends StatelessWidget {

  final AvailableMatchesUiState uiState;

  const RoundedTopBar({Key key, this.uiState}) : super(key: key);

  _getAllFunction(BuildContext context) =>
      () => uiState.changeToAll();

  _getMyGamesFunction(BuildContext context) =>
      () => uiState.changeToMyGames();

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
                uiState.getCurrentSelection() ==
                        "ALL"
                    ? Expanded(
                        child: LeftButtonOn("ALL", _getAllFunction(context)))
                    : Expanded(
                        child: LeftButtonOff("ALL", _getAllFunction(context))),
                uiState.getCurrentSelection() ==
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

class MatchInfo extends StatelessWidget {
  static var formatCurrency = NumberFormat.simpleCurrency(name: "EUR");
  static var monthDayFormat = DateFormat('HH:mm');

  final String matchId;
  final double topMargin;
  final String image;

  MatchInfo(this.matchId, this.image) : topMargin = 10;

  MatchInfo.first(this.matchId, this.image) : topMargin = 0;

  @override
  Widget build(BuildContext context) {
    var matchesState = context.watch<MatchesState>();
    var match = matchesState.getMatch(matchId);

    var loadOnceState = context.read<LoadOnceState>();

    var sportCenter = loadOnceState.getSportCenter(match.sportCenter);
    var sport = loadOnceState.getSport(match.sport);

    return InkWell(
        child: Padding(
          padding: EdgeInsets.only(top: topMargin),
          child: InfoContainer(
              child: IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MatchThumbnail(image: image),
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
                                        sport.displayTitle,
                                    style: TextPalette.h2),
                                Expanded(
                                    child: Text(
                                        (match.isFull())
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
                            Text(getFormattedDate(match.dateTime),
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
          // await Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //         builder: (context) => WaitingScreenLight(toRun: () => MatchesController.refresh(matchesState, match.documentId))));
          await Navigator.push(context,
              MaterialPageRoute(builder: (context) => MatchDetails(matchId)));
        });
  }
}

class MatchThumbnail extends StatelessWidget {
  final String image;

  const MatchThumbnail({Key key, this.image}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 60,
        height: 78,
        child: CachedNetworkImage(
          imageUrl: image,
          fadeInDuration: Duration(milliseconds: 0),
          imageBuilder: (context, imageProvider) => Container(
              decoration: BoxDecoration(
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.fill,
            ),
            borderRadius: BorderRadius.all(Radius.circular(15)),
          )),
          // placeholder: (context, url) => placeHolder,
          errorWidget: (context, url, error) => Icon(Icons.error),
        ));
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

// variation of match info for past
class MatchInfoPast extends StatelessWidget {
  static var formatCurrency = NumberFormat.simpleCurrency(name: "EUR");
  static var dayFormat = DateFormat('dd MMM');

  final Match match;
  final double topMargin;

  MatchInfoPast(this.match) : topMargin = 10;

  MatchInfoPast.first(this.match) : topMargin = 0;

  @override
  Widget build(BuildContext context) {
    var matchesState = context.watch<MatchesState>();

    var loadOnceState = context.read<LoadOnceState>();

    var sportCenter = loadOnceState.getSportCenter(match.sportCenter);
    var sport = loadOnceState.getSport(match.sport);

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
                                    sport.displayTitle,
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
                  builder: (context) => MatchDetails(match.documentId)));
          await MatchesController.refresh(matchesState, match.documentId);
        });
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

class AvailableMatchesUiState extends ChangeNotifier {
  bool loading = false;
  String selected = "ALL";

  void changeToAll() => _change("ALL");

  void changeToMyGames() => _change("MY GAMES");

  void _change(String newSelection) {
    print("changing");
    selected = newSelection;
    notifyListeners();
  }

  void loadingDone() {
    loading = false;
    notifyListeners();
  }

  void startLoading() {
    loading = true;
    notifyListeners();
  }

  String getCurrentSelection() => selected;
}
