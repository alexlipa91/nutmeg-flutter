import 'package:cached_network_image/cached_network_image.dart';
import "package:collection/collection.dart";
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/AppBar.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/Buttons.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/Texts.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import 'package:week_of_year/week_of_year.dart';

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
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  static List<Widget> getEmptyStateWidgets(AvailableMatchesUiState uiState) {
    var widgets = List<Widget>.from([]);

    var emptyStateImage =
        Image.asset("assets/empty_state/" + uiState.getNextEmptyStateImage());

    widgets.add(Center(child: emptyStateImage));
    widgets.add(Text("No matches so far",
        style: TextPalette.h1Default, textAlign: TextAlign.center));

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    var matchesState = context.watch<MatchesState>();
    var userState = context.watch<UserState>();
    var uiState = context.watch<AvailableMatchesUiState>();

    var optionSelected = uiState.selected;

    var isLoggedIn = userState.isLoggedIn();

    var widgets = List<Widget>.of([
      // if app bar is in Scaffold will have the problem of the white pixel between Scaffold appBar and body
      Align(
        child: MainAppBar(),
        heightFactor: 0.99,
      ),
      RoundedTopBar(uiState: uiState)
    ]);

    if (!context.watch<AvailableMatchesUiState>().loading) {
      if (optionSelected == "MY GAMES" && !isLoggedIn) {
        widgets.addAll(getEmptyStateWidgets(uiState));

        // widgets.add(Center(
        //     child: Padding(
        //         padding: EdgeInsets.only(top: 20),
        //         child: Text("LOGIN TO JOIN MATCHES", style: TextPalette.h4)),
        //   ));
        // widgets.add(Center(
        //   child: Padding(
        //       padding: EdgeInsets.only(top: 20),
        //       child: getEmptyStateImage()),
        // ));
      } else {
        widgets.addAll((optionSelected == "ALL")
            ? allGamesWidgets(matchesState, uiState, userState)
            : myGamesWidgets(matchesState, userState, uiState));
      }
    } else {
      widgets.addAll(List<Widget>.filled(5, MatchInfoSkeleton()));
    }

    return Container(
      color: Palette.primary,
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          backgroundColor: Palette.white,
          // appBar: MainAppBar(),
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider(
                  create: (context) => AvailableMatchesUiState()),
            ],
            child: SmartRefresher(
              enablePullDown: true,
              enablePullUp: false,
              header: MaterialClassicHeader(),
              controller: _refreshController,
              onRefresh: () async {
                context.read<AvailableMatchesUiState>().startLoading();

                await MatchesController.refreshAll(matchesState);
                await MatchesController.refreshImages(matchesState);

                context.read<AvailableMatchesUiState>().loadingDone();
                _refreshController.refreshCompleted();
              },
              child: ListView.builder(
                itemBuilder: (c, i) => widgets[i],
                itemCount: widgets.length,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> myGamesWidgets(MatchesState state, UserState userState,
      AvailableMatchesUiState uiState) {
    var matches = state
        .getMatches()
        .where((m) => m.isUserGoing(userState.getUserDetails()));

    if (matches.isEmpty) {
      return getEmptyStateWidgets(uiState);
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

  List<Widget> allGamesWidgets(MatchesState state,
      AvailableMatchesUiState uiState, UserState userState) {
    var matches = state
        .getMatchesInFuture()
        .where((e) => !e.wasCancelled())
        .where((e) => (!e.documentId.startsWith("test_match_id") ||
            (userState.isLoggedIn() && userState.getUserDetails().isAdmin)))
        .toList();

    if (matches.isEmpty) {
      return getEmptyStateWidgets(uiState);
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

    return result;
  }
}

class RoundedTopBar extends StatelessWidget {
  final AvailableMatchesUiState uiState;

  const RoundedTopBar({Key key, this.uiState}) : super(key: key);

  _getAllFunction(BuildContext context) => () => uiState.changeToAll();

  _getMyGamesFunction(BuildContext context) => () => uiState.changeToMyGames();

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
                uiState.getCurrentSelection() == "ALL"
                    ? Expanded(
                        child: LeftButtonOn("ALL", _getAllFunction(context)))
                    : Expanded(
                        child: LeftButtonOff("ALL", _getAllFunction(context))),
                uiState.getCurrentSelection() == "ALL"
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

    var sportCenter = loadOnceState.getSportCenter(match.sportCenterId);
    var sport = loadOnceState.getSport(match.sport);

    var icons = getIcons(context, match);

    return InkWell(
        child: Padding(
          padding: EdgeInsets.only(top: topMargin, left: 16, right: 16),
          child: InfoContainer(
              child: IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MatchThumbnail(image: image),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                                sportCenter.name +
                                    " - " +
                                    sport.displayTitle +
                                    (match.documentId
                                            .startsWith("test_match_id")
                                        ? " (TESTERS)"
                                        : ""),
                                style: TextPalette.h2),
                          ],
                        ),
                        Text(getFormattedDate(match.dateTime),
                            style: TextPalette.h3),
                        Text(
                            (match.isFull())
                                ? "Full"
                                : (match.maxPlayers - match.numPlayersGoing())
                                        .toString() +
                                    " spots left",
                            style: GoogleFonts.roboto(
                                color: Palette.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w400),
                            textAlign: TextAlign.right),
                      ]),
                ),
                Expanded(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (icons.isNotEmpty)
                                Stack(
                                    alignment: Alignment.centerRight,
                                    clipBehavior: Clip.none,
                                    children: icons)
                            ])
                      ]),
                )
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

  List<Widget> getIcons(BuildContext context, Match match) {
    List<Widget> widgets = [];

    var currentRightOffset = 0.0;

    var isLoggedInAndGoing = context.watch<UserState>().isLoggedIn() &&
        match.isUserGoing(context.watch<UserState>().getUserDetails());

    if (isLoggedInAndGoing && match.numPlayersGoing() > 1) {
      widgets.add(Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(50.0)),
          border: Border.all(
            color: Colors.white,
            width: 2.0,
          ),
        ),
        child: CircleAvatar(
            child: Center(
                child: Text("+" + (match.numPlayersGoing() - 1).toString(),
                    style: GoogleFonts.roboto(
                        color: Palette.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500))),
            radius: 14,
            backgroundColor: Palette.primary),
      ));
      currentRightOffset += 25;
    }

    if (isLoggedInAndGoing) {
      var w = Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(50.0)),
            border: Border.all(
              color: Colors.white,
              width: 2.0,
            ),
          ),
          child: UserAvatar(14, context.read<UserState>().getUserDetails()));

      if (currentRightOffset > 0) {
        widgets.add(Positioned(right: currentRightOffset, child: w));
      } else {
        widgets.add(w);
      }
    }

    print(widgets.length);

    return widgets;
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
      padding: EdgeInsets.only(top: 30, left: 16, right: 16),
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

    var sportCenter = loadOnceState.getSportCenter(match.sportCenterId);
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
                            Text(sportCenter.name + " - " + sport.displayTitle,
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
                  builder: (context) => MatchDetails.past(match.documentId)));
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

  List<String> emptyStateImages = [
    "illustration_01.png",
    "illustration_02.png",
    "illustration_03.png"
  ];
  String lastEmptyStateImageShown;

  void changeToAll() => _change("ALL");

  void changeToMyGames() => _change("MY GAMES");

  void _change(String newSelection) {
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

  String getNextEmptyStateImage() {
    while (emptyStateImages.first == lastEmptyStateImageShown) {
      emptyStateImages.shuffle();
    }

    lastEmptyStateImageShown = emptyStateImages.first;
    return lastEmptyStateImageShown;
  }

  static getEmptyStateImages() =>
      ["illustration_01.png", "illustration_02.png", "illustration_03.png"];
}
