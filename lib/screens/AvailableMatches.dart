import 'package:badges/badges.dart';
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
import 'package:flutter/foundation.dart';


import 'MatchDetails.dart';

// main widget
class AvailableMatches extends StatelessWidget {
  static const routeName = "/availableMatches";

  @override
  Widget build(BuildContext context) {
    return MultiProvider(providers: [
      ChangeNotifierProvider(create: (context) => AvailableMatchesUiState()),
    ], child: AvailableMatchesList());
  }
}

class AvailableMatchesList extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => AvailableMatchesListState();
}


class AvailableMatchesListState extends State<AvailableMatchesList> {

  var future;

  @override
  void initState() {
    super.initState();
    future = MatchesController.init(context.read<MatchesState>());
  }

  Future<void> refreshPageState(
      MatchesState matchesState) async {
    await MatchesController.refreshAll(matchesState);
    _refreshController.refreshCompleted();
  }

  static Widget getEmptyStateWidget(AvailableMatchesUiState uiState) =>
      Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: Container(
          child: Column(children: [
            Image.asset("assets/empty_state/illustration_"
                + ((uiState.selected == Status.ALL) ? "01" : "02")
                + ".png", height: 400),
            Text("No matches here",
                style: TextPalette.h1Default, textAlign: TextAlign.center)
          ],),
        ),
      );

  var _refreshController = RefreshController(initialRefresh: false);

  @override
  Widget build(BuildContext context) {
    var matchesState = context.watch<MatchesState>();
    var uiState = context.watch<AvailableMatchesUiState>();
    var userState = context.watch<UserState>();
    var loadOnceState = context.read<LoadOnceState>();

    WidgetsBinding.instance.addObserver(LifecycleEventHandler(
        resumeCallBack: () async {
          if (mounted) {
            _refreshController.requestRefresh();
          }
        }));

    var optionSelected = uiState.selected;
    var isLoggedIn = userState.isLoggedIn();

    var topWidgets = List<Widget>.of([
      // if app bar is in Scaffold will have the problem of the white pixel between Scaffold appBar and body
      Align(
        child: MainAppBar(),
        heightFactor: 0.99,
      ),
      RoundedTopBar(uiState: uiState),
    ]);

    List<Widget> matchWidgets;
    if (matchesState.getMatches() != null) {
      if (optionSelected == Status.ALL) {
        matchWidgets = allGamesWidgets(matchesState, uiState, userState,
            loadOnceState, _refreshController);
      } else {
        if (isLoggedIn) {
          matchWidgets = myGamesWidgets(matchesState, userState, uiState,
              loadOnceState, _refreshController);
        } else {
          matchWidgets = [];
        }
      }
    }

    var waitingWidgets = List<Widget>.filled(5, MatchInfoSkeleton());

    return Container(
      color: Palette.primary,
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          backgroundColor: Palette.light,
          // appBar: MainAppBar(),
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider(
                  create: (context) => AvailableMatchesUiState()),
            ],
            child: FutureBuilder(
              builder: (context, snapshot) => SmartRefresher(
                enablePullDown: true,
                enablePullUp: false,
                header: MaterialClassicHeader(),
                controller: _refreshController,
                onRefresh: () async {
                  await refreshPageState(matchesState);
                },
                child: (matchWidgets != null && matchWidgets.isEmpty)
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Column(children: topWidgets),
                          getEmptyStateWidget(uiState)])
                    : ListView.builder(
                        itemBuilder: (c, i) {
                          var coreWidgets =
                              (matchWidgets == null) ? waitingWidgets : matchWidgets;
                          var list = topWidgets + coreWidgets;
                          return list[i];
                        },
                        itemCount: topWidgets.length +
                            ((matchWidgets == null)
                                ? waitingWidgets.length
                                : matchWidgets.length),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> myGamesWidgets(MatchesState state, UserState userState,
      AvailableMatchesUiState uiState, LoadOnceState loadOnceState,
      RefreshController refreshController) {
    var matches = state
        .getMatches()
        .where((e) => (!e.isTest || userState.isTestMode))
        .where((m) => m.isUserGoing(userState.getUserDetails()));

    var now = DateTime.now();

    List<Match> past = matches.where((m) => m.dateTime.isBefore(now)).toList();
    List<Match> future = matches.where((m) => m.dateTime.isAfter(now)).toList();

    List<Widget> widgets = [];

    if (future.isNotEmpty) {
      widgets.add(TextSeparatorWidget("UPCOMING MATCHES"));
      future.sortedBy((e) => e.dateTime).forEachIndexed((index, m) {
        if (index == 0) {
          widgets.add(
              MatchInfo.first(m.documentId,
                  loadOnceState.getSportCenter(m.sportCenterId).thumbnailUrl,
                  refreshController)
          );
        } else {
          widgets.add(MatchInfo(m.documentId,
              loadOnceState.getSportCenter(m.sportCenterId).thumbnailUrl,
              refreshController));
        }
      });
    }

    if (past.isNotEmpty) {
      widgets.add(TextSeparatorWidget("PAST MATCHES"));
      past.sortedBy((e) => e.dateTime).reversed.forEachIndexed((index, m) {
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
      AvailableMatchesUiState uiState, UserState userState,
      LoadOnceState loadOnceState, RefreshController refreshController) {
    var matches = state
        .getMatchesInFuture()
        .where((e) => !e.wasCancelled())
        .where((e) => (!e.isTest || userState.isTestMode))
        .toList();

    var beginningOfCurrentWeek = getBeginningOfTheWeek(DateTime.now());

    // group by delta of days from first day of the week
    var grouped = matches.groupListsBy((m) {
      var durationDifference = getBeginningOfTheWeek(m.dateTime)
          .difference(beginningOfCurrentWeek);
      return durationDifference.inDays ~/ 7;
    });

    List<int> sortedWeeks = grouped.keys.toList()..sort();

    List<Widget> result = [];

    sortedWeeks.forEach((w) {
      result.add(WeekSeparatorWidget(w));
      grouped[w].sortedBy((e) => e.dateTime).forEachIndexed((index, match) {
        if (index == 0) {
          result.add(MatchInfo.first(
              match.documentId, loadOnceState.getSportCenter(match.sportCenterId).thumbnailUrl,
          refreshController));
        } else {
          result.add(
              MatchInfo(match.documentId, loadOnceState.getSportCenter(match.sportCenterId).thumbnailUrl,
              refreshController));
        }
      });
    });

    return result;
  }
}

class RoundedTopBar extends StatelessWidget {
  final AvailableMatchesUiState uiState;

  const RoundedTopBar({Key key, this.uiState}) : super(key: key);

  _getAllFunction(BuildContext context) => () => uiState.changeTo(Status.ALL);

  _getMyGamesFunction(BuildContext context) => () => uiState.changeTo(Status.MY_GAMES);

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
              Text("Find football matches in",
                  style: TextPalette.bodyTextInverted),
              Text("Amsterdam", style: TextPalette.h1Inverted),
              SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                uiState.getCurrentSelection() == Status.ALL
                    ? Expanded(
                        child: LeftButtonOn("ALL", _getAllFunction(context)))
                    : Expanded(
                        child: LeftButtonOff("ALL", _getAllFunction(context))),
                uiState.getCurrentSelection() == Status.MY_GAMES
                    ? Expanded(
                        child: RightButtonOn(
                            "MY MATCHES", _getMyGamesFunction(context)))
                    : Expanded(
                        child: RightButtonOff(
                            "MY MATCHES", _getMyGamesFunction(context))),
              ])
            ],
          ),
        ));
  }
}

class MatchInfo extends StatelessWidget {
  static var monthDayFormat = DateFormat('HH:mm');

  final String matchId;
  final double topMargin;
  final String image;
  final RefreshController refreshController;

  MatchInfo(this.matchId, this.image, this.refreshController) : topMargin = 10;

  MatchInfo.first(this.matchId, this.image, this.refreshController) : topMargin = 0;

  @override
  Widget build(BuildContext context) {
    var matchesState = context.watch<MatchesState>();
    var match = matchesState.getMatch(matchId);

    var loadOnceState = context.read<LoadOnceState>();

    var sportCenter = loadOnceState.getSportCenter(match.sportCenterId);
    var sport = loadOnceState.getSport(match.sport);

    return InkWell(
        child: Padding(
          padding: EdgeInsets.only(top: topMargin, left: 16, right: 16),
          child: InfoContainer(
              backgroundColor: (match.isTest) ? Colors.orangeAccent : Palette.white,
              child: applyBadges(context, match, Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MatchThumbnail(image: image),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(sportCenter.name + " - " + sport.displayTitle,
                                  style: TextPalette.h2),
                            ],
                          ),
                          SizedBox(height: 12,),
                          Text(getFormattedDate(match.dateTime),
                              style:
                              TextPalette.getH3(Palette.mediumgrey
                            )
                          ),
                          SizedBox(height: 8,),
                          (match.isFull())
                              ? Text("Full",
                                  style: TextPalette.bodyText,
                                  textAlign: TextAlign.right)
                              : Text(
                                  (match.maxPlayers - match.numPlayersGoing())
                                          .toString() +
                                      " spots left",
                                  style: TextPalette.bodyTextPrimary,
                                  textAlign: TextAlign.right),
                        ]),
                  ),
                ],
              ))),
        ),
        onTap: () async {
          await Navigator.pushNamed(
            context,
            MatchDetails.routeName,
            arguments: ScreenArguments(
              match.documentId,
              false,
            ),
          );
          await refreshController.requestRefresh();
        });
  }

  Widget applyBadges(BuildContext context, Match match, Widget w) {
    var userAvatar = Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(50.0)),
          border: Border.all(
            color: Colors.white,
            width: 2.0,
          ),
        ),
        child: UserAvatar(14, context.read<UserState>().getUserDetails()));
    var plusPlayers = Container(
      width: 26,
      height: 26,
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
                      fontSize: 10,
                      fontWeight: FontWeight.w500))),
          radius: 14,
          backgroundColor: Palette.primary),
    );

    var finalWidget = w;

    var badgeIt = (child, content, position) => Badge(
        badgeContent: content,
        child: child,
        badgeColor: Colors.transparent,
        borderSide: BorderSide.none,
        elevation: 0,
        position: position);

    var shouldShowUserBadge = context.watch<UserState>().isLoggedIn() &&
        match.isUserGoing(context.watch<UserState>().getUserDetails());

    var shouldShowBoth =
        shouldShowUserBadge && match.numPlayersGoing() > 1;

    // fixme not sure why we need to do -6 here
    if (shouldShowBoth) {
      finalWidget = badgeIt(finalWidget, userAvatar, BadgePosition.bottomEnd(bottom: -6, end: 18));
      finalWidget = badgeIt(finalWidget, plusPlayers, BadgePosition.bottomEnd(bottom: -6, end: 0));
    } else if (shouldShowUserBadge) {
      finalWidget = badgeIt(finalWidget, userAvatar, BadgePosition.bottomEnd(bottom: -6, end: 0));
    }

    return finalWidget;
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
            borderRadius: BorderRadius.all(Radius.circular(10)),
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
          padding: EdgeInsets.only(top: topMargin, right: 16, left: 16),
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
          ),
              backgroundColor: (match.isTest) ? Palette.white : Palette.white,
          ),
        ),
        onTap: () async {
          // fixme why it doesn't rebuild here?
          await Navigator.pushNamed(
            context,
            MatchDetails.routeName,
            arguments: ScreenArguments(
              match.documentId,
              true,
            ),
          );
          await MatchesController.refresh(matchesState, match.documentId);
        });
  }
}

class WeekSeparatorWidget extends StatelessWidget {
  final int weekDelta;

  const WeekSeparatorWidget(this.weekDelta);

  @override
  Widget build(BuildContext context) => TextSeparatorWidget(_getWeekDesc());

  _getWeekDesc() {
    if (weekDelta == 0) {
      return "THIS WEEK";
    }
    if (weekDelta == 1) {
      return "NEXT WEEK";
    }
    return "IN MORE THAN TWO WEEKS";
  }
}

enum Status {
  ALL,
  MY_GAMES
}

class AvailableMatchesUiState extends ChangeNotifier {

  Status selected = Status.ALL;

  void changeTo(Status newSelection) {
    selected = newSelection;
    notifyListeners();
  }

  Status getCurrentSelection() => selected;
}

class LifecycleEventHandler extends WidgetsBindingObserver {
  final AsyncCallback resumeCallBack;

  LifecycleEventHandler({
    this.resumeCallBack,
  });

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        if (resumeCallBack != null) {
          await resumeCallBack();
        }
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.detached:
        break;
    }
  }
}