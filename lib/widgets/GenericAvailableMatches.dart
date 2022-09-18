import 'dart:math';

import 'package:badges/badges.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/controller/SportCentersController.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/model/SportCenter.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/AppBar.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/RefresherWithObserverWidget.dart';
import 'package:nutmeg/widgets/Texts.dart';
import 'package:provider/provider.dart';

import '../state/AvailableMatchesState.dart';
import '../state/LoadOnceState.dart';
import '../state/MatchesState.dart';
import '../state/UserState.dart';
import 'Badges.dart';
import 'Skeletons.dart';

class GenericAvailableMatchesList extends StatefulWidget {
  final appBarColor;
  final List<String?> tabNames;
  final List<Widget?> tabContent;
  final Widget? emptyStateWidget;
  final FloatingActionButton? floatingActionButton;
  final Widget? titleWidget;

  const GenericAvailableMatchesList(
      this.appBarColor,
      this.tabNames,
      this.tabContent,
      this.emptyStateWidget,
      this.floatingActionButton,
      this.titleWidget);

  @override
  State<StatefulWidget> createState() => GenericAvailableMatchesListState();
}

class GenericAvailableMatchesListState
    extends State<GenericAvailableMatchesList> {

  Future<void> refreshPageState(BuildContext context) async {
    print('refreshing page state');
    var matches = await context.read<MatchesState>().fetchMatches();
    Future.wait(matches
        .map((e) => e.sportCenterId)
        .where((s) => s != null)
        .toSet()
        .map((s) => SportCentersController.refresh(context, s!)));
  }

  Widget waitingWidget() {
    var waitingWidgets = interleave(
        List<Widget>.filled(5, SkeletonAvailableMatches()),
        SizedBox(
          height: 24,
        ));

    return Column(children: waitingWidgets);
  }

  @override
  Widget build(BuildContext context) {
    var selected = context.watch<AvailableMatchesUiState>().current;
    if (selected >= widget.tabNames.length) {
      selected = 0;
    }

    var top = Column(children: [
      MainAppBar(widget.appBarColor),
      Container(
        decoration: BoxDecoration(
            // add this shadow so that the separator between appbar and top container is not visible
            boxShadow: [
              BoxShadow(
                color: widget.appBarColor,
                blurRadius: 0.0,
                spreadRadius: 0.0,
                offset: Offset(0, -5),
              )
            ],
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
              widget.titleWidget!,
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
                      child: Text(title!, style: textStyle),
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
          body: RefresherWithObserverWidget(
            child: ListView.builder(
                padding: EdgeInsets.zero,
                physics: AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                itemBuilder: (c, i) {
                  var core = (widget.tabContent[selected] == null)
                      ? waitingWidget()
                      : widget.tabContent[selected];

                  var list = List<Widget>.from([
                    top,
                    Padding(
                        padding:
                        EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
                        child: core),
                    SizedBox(
                        height: max(16.0, MediaQuery.of(context).padding.bottom)
                    )
                  ]);
                  return list[i];
                },
                itemCount: 3),
            refreshState: () => refreshPageState(context), initState: null),
          floatingActionButton: widget.floatingActionButton,
        ),
      ),
    );
  }
}

class GenericMatchInfo extends StatelessWidget {
  static var monthDayFormat = DateFormat('HH:mm');

  final Match match;
  final SportCenter sportCenter;

  final double topMargin;
  final Function onTap;

  GenericMatchInfo(this.match, this.sportCenter, this.onTap)
      : topMargin = 10;

  GenericMatchInfo.first(this.match, this.sportCenter, this.onTap)
      : topMargin = 0;

  @override
  Widget build(BuildContext context) {
    return InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
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
                      MatchThumbnail(image: sportCenter.getThumbnailUrl()),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              (sportCenter.getCourtType() == null)
                                  ? Skeletons.mText
                                  : Row(
                                      children: [
                                        Text(
                                            sportCenter.getName() +
                                                " - " +
                                                sportCenter.getCourtType()!,
                                            style: TextPalette.h2),
                                      ],
                                    ),
                              SizedBox(
                                height: 8,
                              ),
                              Text(getFormattedDateWithHour(match.dateTime),
                                  style: TextPalette.getBodyText(Palette.grey_dark)),
                              SizedBox(
                                height: 6,
                              ),
                              (match.status == MatchStatus.unpublished) ?
                                Text("Not Published",
                                  style: TextPalette.getBodyText(
                                      Palette.darkWarning)) :
                              (match.status == MatchStatus.cancelled)
                                  ? Text("Cancelled",
                                      style: TextPalette.getBodyText(
                                          Palette.destructive))
                                  : (match.isFull())
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
        onTap: () => onTap(context, match.documentId));
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
                      fontSize: 9,
                      fontWeight: FontWeight.w500))),
          radius: 14,
          backgroundColor: Palette.primary),
    );

    var finalWidget = w;

    var shouldShowUserBadge = context.watch<UserState>().isLoggedIn() &&
        match.isUserGoing(context.watch<UserState>().getLoggedUserDetails()!);

    var badges = [];

    if (shouldShowUserBadge) {
      badges.add(userAvatar);
    }
    if (shouldShowUserBadge && match.numPlayersGoing() > 1) {
      badges.add(plusPlayers);
    }
    if (match.isTest) {
      badges.add(TestBadge());
    }

    var e = 18.0 * (badges.length - 1);
    badges.forEach((b) {
      // fixme not sure why we need to do -6 here
      finalWidget =
          badgeIt(finalWidget, b, BadgePosition.bottomEnd(bottom: -6, end: e));
      e -= 18;
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

  GenericMatchInfoPast(this.matchId, this.onTap)
      : topMargin = 10;

  GenericMatchInfoPast.first(this.matchId, this.onTap)
      : topMargin = 0;

  @override
  Widget build(BuildContext context) {
    var loadOnceState = context.read<LoadOnceState>();

    var match = context.watch<MatchesState>().getMatch(matchId);

    if (match == null)
      return Container();

    var sportCenter = match.sportCenter ?? loadOnceState.getSportCenter(match.sportCenterId!)!;

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
                        Text(sportCenter.getName() + " - " + sportCenter.getCourtType()!,
                            style: TextPalette.h2),
                        SizedBox(height: 8),
                        Text(sportCenter.getName(), style: TextPalette.bodyText),
                        if (match.status == MatchStatus.cancelled)
                          Padding(padding: EdgeInsets.only(top: 8), child:
                            Text("Canceled",
                                style: TextPalette.getBodyText(Palette.destructive)))
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
        onTap: () => onTap(context, match.documentId));
  }
}

class MatchThumbnail extends StatelessWidget {
  final String image;
  final double height;

  const MatchThumbnail({this.height = 78, required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 60,
        height: height,
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
