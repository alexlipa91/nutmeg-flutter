import 'package:badges/badges.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/AppBar.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/Texts.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';

import '../state/LoadOnceState.dart';
import '../state/MatchesState.dart';
import '../state/UserState.dart';


class GenericAvailableMatchesList extends StatefulWidget {
  final RoundedTopBar roundedTopBar;
  final Function getGamesWidget;
  final Function getEmptyStateWidget;
  final RefreshController refreshController;
  final appBarColor;

  const GenericAvailableMatchesList(this.roundedTopBar, this.getGamesWidget,
      this.getEmptyStateWidget, this.refreshController, this.appBarColor);

  @override
  State<StatefulWidget> createState() => GenericAvailableMatchesListState(
      roundedTopBar,
      getGamesWidget,
      getEmptyStateWidget,
      refreshController,
      appBarColor
  );
}

class GenericAvailableMatchesListState extends State<GenericAvailableMatchesList> {
  final RoundedTopBar roundedTopBar;
  final Function getGamesWidget;
  final Function getEmptyStateWidget;
  final RefreshController refreshController;
  final appBarColor;

  GenericAvailableMatchesListState(this.roundedTopBar, this.getGamesWidget,
      this.getEmptyStateWidget, this.refreshController, this.appBarColor);

  @override
  void initState() {
    super.initState();
    refreshPageState(context);
  }

  Future<void> refreshPageState(BuildContext context) async {
    await MatchesController.refreshAll(context);
    Future.wait(
        context.read<MatchesState>().getMatches()
            .map((e) => MatchesController.refreshMatchStatus(context, e.documentId)));
    refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    var matchesState = context.watch<MatchesState>();

    WidgetsBinding.instance
        .addObserver(LifecycleEventHandler(resumeCallBack: () async {
      if (mounted) {
        refreshController.requestRefresh();
      }
    }));

    var topWidgets = List<Widget>.of([
      // if app bar is in Scaffold will have the problem of the white pixel between Scaffold appBar and body
      Align(
        child: MainAppBar(appBarColor),
        heightFactor: 0.99,
      ),
      roundedTopBar,
    ]);

    List<Widget> matchWidgets;
    if (matchesState.getMatches() != null) {
      matchWidgets = getGamesWidget(context, refreshController);
    }

    var waitingWidgets = List<Widget>.filled(5, MatchInfoSkeleton());

    return Container(
      color: Palette.primary,
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          backgroundColor: Palette.light,
          // appBar: MainAppBar(),
          body: FutureBuilder(
            builder: (context, snapshot) => SmartRefresher(
              enablePullDown: true,
              enablePullUp: false,
              header: MaterialClassicHeader(),
              controller: refreshController,
              onRefresh: () async {
                await refreshPageState(context);
              },
              child: (matchWidgets != null && matchWidgets.isEmpty)
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                          Column(children: topWidgets),
                          getEmptyStateWidget(context)
                        ])
                  : ListView.builder(
                      itemBuilder: (c, i) {
                        var coreWidgets = (matchWidgets == null)
                            ? waitingWidgets
                            : matchWidgets;
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
    );
  }
}

class RoundedTopBar extends StatelessWidget {

  final Function getButtons;
  final Color color;

  const RoundedTopBar({Key key, this.getButtons, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: color,
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
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: getButtons(context))
            ],
          ),
        ));
  }
}

class GenericMatchInfo extends StatelessWidget {
  static var monthDayFormat = DateFormat('HH:mm');

  final String matchId;
  final double topMargin;
  final Function onTap;
  final RefreshController refreshController;

  GenericMatchInfo(this.matchId, this.onTap, this.refreshController) : topMargin = 10;

  GenericMatchInfo.first(this.matchId, this.onTap, this.refreshController) : topMargin = 0;

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
              backgroundColor:
                  (match.isTest) ? Colors.orangeAccent : Palette.white,
              child: applyBadges(
                  context,
                  match,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MatchThumbnail(image: sportCenter.thumbnailUrl),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                      sportCenter.name +
                                          " - " +
                                          sport.displayTitle,
                                      style: TextPalette.h2),
                                ],
                              ),
                              SizedBox(
                                height: 12,
                              ),
                              Text(getFormattedDate(match.dateTime),
                                  style: TextPalette.getH3(Palette.mediumgrey)),
                              SizedBox(
                                height: 8,
                              ),
                              (match.isFull())
                                  ? Text("Full",
                                      style: TextPalette.bodyText,
                                      textAlign: TextAlign.right)
                                  : Text(
                                      (match.maxPlayers -
                                                  match.numPlayersGoing())
                                              .toString() +
                                          " spots left",
                                      style: TextPalette.bodyTextPrimary,
                                      textAlign: TextAlign.right),
                            ]),
                      ),
                    ],
                  ))),
        ),
        onTap: () => onTap(context, match.documentId, refreshController)
    );
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
        child:
            UserAvatar(14, context.read<UserState>().getLoggedUserDetails()));
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
        toAnimate: false,
        badgeContent: content,
        child: child,
        badgeColor: Colors.transparent,
        borderSide: BorderSide.none,
        elevation: 0,
        position: position);

    var shouldShowUserBadge = context.watch<UserState>().isLoggedIn() &&
        match.isUserGoing(context.watch<UserState>().getLoggedUserDetails());

    var shouldShowBoth = shouldShowUserBadge && match.numPlayersGoing() > 1;

    // fixme not sure why we need to do -6 here
    if (shouldShowBoth) {
      finalWidget = badgeIt(finalWidget, userAvatar,
          BadgePosition.bottomEnd(bottom: -6, end: 18));
      finalWidget = badgeIt(finalWidget, plusPlayers,
          BadgePosition.bottomEnd(bottom: -6, end: 0));
    } else if (shouldShowUserBadge) {
      finalWidget = badgeIt(
          finalWidget, userAvatar, BadgePosition.bottomEnd(bottom: -6, end: 0));
    }

    return finalWidget;
  }
}

// variation of match info for past
class GenericMatchInfoPast extends StatelessWidget {
  static var dayFormat = DateFormat('dd MMM');

  final String matchId;
  final double topMargin;
  final Function onTap;
  final RefreshController refreshController;

  GenericMatchInfoPast(this.matchId, this.onTap, this.refreshController) : topMargin = 10;

  GenericMatchInfoPast.first(this.matchId, this.onTap, this.refreshController) : topMargin = 0;

  @override
  Widget build(BuildContext context) {
    var loadOnceState = context.read<LoadOnceState>();

    var match = context.watch<MatchesState>().getMatch(matchId);

    var sportCenter = loadOnceState.getSportCenter(match.sportCenterId);
    var sport = loadOnceState.getSport(match.sport);

    return InkWell(
        child: Padding(
          padding: EdgeInsets.only(top: topMargin, right: 16, left: 16),
          child: InfoContainer(
            backgroundColor: (match.isTest) ? Colors.orange : Palette.white,
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
                                  sportCenter.name + " - " + sport.displayTitle,
                                  style: TextPalette.h2),
                              SizedBox(height: 10),
                              Text(sportCenter.name,
                                  style: TextPalette.bodyText),
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
          ),
        ),
        onTap: () => onTap(context, match.documentId, refreshController)
      );
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
