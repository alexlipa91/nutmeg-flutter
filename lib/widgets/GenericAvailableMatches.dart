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

import '../state/AvailableMatchesState.dart';
import '../state/LoadOnceState.dart';
import '../state/MatchesState.dart';
import '../state/UserState.dart';
import 'Badges.dart';
import 'Skeletons.dart';

class GenericAvailableMatchesList extends StatefulWidget {
  final appBarColor;
  final List<String> tabNames;
  final List<Widget> tabContent;
  final Widget emptyStateWidget;
  final RefreshController refreshController;
  final FloatingActionButton floatingActionButton;

  const GenericAvailableMatchesList(
      this.appBarColor,
      this.tabNames,
      this.tabContent,
      this.emptyStateWidget,
      this.refreshController,
      this.floatingActionButton);

  @override
  State<StatefulWidget> createState() => GenericAvailableMatchesListState();
}

class GenericAvailableMatchesListState
    extends State<GenericAvailableMatchesList> {
  @override
  void initState() {
    super.initState();
    refreshPageState(context);
  }

  Future<void> refreshPageState(BuildContext context) async {
    await MatchesController.refreshAll(context);
    Future.wait(context
        .read<MatchesState>()
        .getMatches()
        .map((e) => MatchesController.refreshMatchStatus(context, e)));
    widget.refreshController.refreshCompleted();
  }

  Widget waitingWidget() {
    var waitingWidgets = interleave(
        List<Widget>.filled(3, SkeletonAvailableMatches()),
        SizedBox(
          height: 10,
        ),
        true);
    return Column(children: waitingWidgets);
  }

  @override
  Widget build(BuildContext context) {
    var selected = context.watch<AvailableMatchesUiState>().current;
    if (selected >= widget.tabNames.length) {
      selected = 0;
    }

    WidgetsBinding.instance
        .addObserver(LifecycleEventHandler(resumeCallBack: () async {
      if (mounted) {
        widget.refreshController.requestRefresh();
      }
    }));

    var top = Column(children: [
      MainAppBar(widget.appBarColor),
      Container(
        decoration: BoxDecoration(
            color: widget.appBarColor,
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20))),
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Find football matches in",
                  style: TextPalette.bodyTextInverted),
              Text("Amsterdam", style: TextPalette.h1Inverted),
              SizedBox(height: 24),
              SingleChildScrollView(
                clipBehavior: Clip.none,
                scrollDirection: Axis.horizontal,
                child: Row(
                    children: widget.tabNames.asMap().entries.map((e) {
                  var index = e.key;
                  var title = e.value;

                  var textStyle = (index == selected)
                      ? TextPalette.linkStyle
                      : TextPalette.linkStyleInverted;
                  var color =
                      (index == selected) ? Palette.white : widget.appBarColor;

                  return ElevatedButton(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Text(title, style: textStyle),
                    ),
                    onPressed: () =>
                        context.read<AvailableMatchesUiState>().changeTo(index),
                    style: ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: MaterialStateProperty.all(Size.zero),
                      padding: MaterialStateProperty.all(EdgeInsets.zero),
                      elevation: MaterialStateProperty.all(0),
                      backgroundColor: MaterialStateProperty.all<Color>(color),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50.0))),
                    ),
                  );
                }).toList()),
              )
            ].toList(),
          ),
        ),
      )
    ]);

    return Container(
      color: widget.appBarColor,
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          backgroundColor: Palette.grey_lightest,
          body: SafeArea(
            minimum: EdgeInsets.only(bottom: 16.0),
            child: SmartRefresher(
              enablePullDown: true,
              enablePullUp: false,
              header: MaterialClassicHeader(),
              controller: widget.refreshController,
              onRefresh: () async {
                await refreshPageState(context);
              },
              child: ListView.builder(
                  itemBuilder: (c, i) {
                    var core = (widget.tabContent[selected] == null)
                        ? waitingWidget()
                        : Padding(
                            padding: EdgeInsets.all(16.0),
                            child: widget.tabContent[selected]);

                    var list = List<Widget>.from([top, core]);
                    return list[i];
                  },
                  itemCount: 2),
            ),
          ),
          floatingActionButton: widget.floatingActionButton,
        ),
      ),
    );
  }
}

class GenericMatchInfo extends StatelessWidget {
  static var monthDayFormat = DateFormat('HH:mm');

  final String matchId;
  final double topMargin;
  final Function onTap;
  final RefreshController refreshController;

  GenericMatchInfo(this.matchId, this.onTap, this.refreshController)
      : topMargin = 10;

  GenericMatchInfo.first(this.matchId, this.onTap, this.refreshController)
      : topMargin = 0;

  @override
  Widget build(BuildContext context) {
    var matchesState = context.watch<MatchesState>();
    var match = matchesState.getMatch(matchId);

    var loadOnceState = context.read<LoadOnceState>();

    var sportCenter = (match == null)
        ? null
        : loadOnceState.getSportCenter(match.sportCenterId);
    var sport = (match == null) ? null : loadOnceState.getSport(match.sport);

    return InkWell(
        child: Padding(
          padding: EdgeInsets.only(top: topMargin),
          child: InfoContainer(
              backgroundColor: Palette.white,
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
                                  style: TextPalette.getH3(Palette.grey_dark)),
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
        onTap: () => onTap(context, match.documentId, refreshController));
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

    var shouldShowUserBadge = context.watch<UserState>().isLoggedIn() &&
        match.isUserGoing(context.watch<UserState>().getLoggedUserDetails());

    var badges = [];

    if (shouldShowUserBadge && match.numPlayersGoing() > 1) {
      badges.add(plusPlayers);
    }
    if (shouldShowUserBadge) {
      badges.add(userAvatar);
    }
    if (match.isTest) {
      badges.add(TestBadge());
    }

    var e = 0.0;
    badges.forEach((b) {
      // fixme not sure why we need to do -6 here
      finalWidget =
          badgeIt(finalWidget, b, BadgePosition.bottomEnd(bottom: -6, end: e));
      e += 18;
    });

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

  GenericMatchInfoPast(this.matchId, this.onTap, this.refreshController)
      : topMargin = 10;

  GenericMatchInfoPast.first(this.matchId, this.onTap, this.refreshController)
      : topMargin = 0;

  @override
  Widget build(BuildContext context) {
    var loadOnceState = context.read<LoadOnceState>();

    var match = context.watch<MatchesState>().getMatch(matchId);

    var sportCenter = loadOnceState.getSportCenter(match.sportCenterId);
    var sport = loadOnceState.getSport(match.sport);

    var child = InfoContainer(
      backgroundColor: Palette.white,
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
                Text(dayFormat.format(match.dateTime), style: TextPalette.h4)
              ],
            )),
          ],
        ),
      ),
    );

    return InkWell(
        child: Padding(
          padding: EdgeInsets.only(top: topMargin),
          child: match.isTest
              ? badgeIt(child, TestBadge(),
                  BadgePosition.bottomEnd(bottom: 8, end: 8))
              : child,
        ),
        onTap: () => onTap(context, match.documentId, refreshController));
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
