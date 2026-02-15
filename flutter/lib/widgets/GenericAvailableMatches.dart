import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/model/SportCenter.dart';
import 'package:nutmeg/state/MatchState.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/AppBar.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/Texts.dart';
import 'package:provider/provider.dart';
import 'package:nutmeg/l10n/app_localizations.dart';

import '../state/AvailableMatchesState.dart';
import '../state/UserState.dart';
import '../utils/LocationUtils.dart';
import 'Skeletons.dart';

class GenericAvailableMatchesList extends StatefulWidget {
  final appBarColor;
  final List<String?> tabNames;
  final List<Widget?> tabContent;
  final Widget? emptyStateWidget;
  final FloatingActionButton? floatingActionButton;
  final Widget? titleWidget;
  final Function refreshState;
  final Map<int, IconData>? tabIcons;
  final int? separatorBeforeIndex;

  const GenericAvailableMatchesList(
      this.appBarColor,
      this.tabNames,
      this.tabContent,
      this.emptyStateWidget,
      this.floatingActionButton,
      this.titleWidget,
      this.refreshState,
      {this.tabIcons, this.separatorBeforeIndex});

  @override
  State<StatefulWidget> createState() => GenericAvailableMatchesListState();
}

class GenericAvailableMatchesListState
    extends State<GenericAvailableMatchesList> {
  final logger = CrashlyticsLogger("GenericAvailableMatchesList");

  void initState() {
    logger.info("GenericAvailableMatchesList initState");
    super.initState();
    widget.refreshState();
  }

  Widget waitingWidget() => ListOfMatchesSkeleton(repeatFor: 3);

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
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 1100),
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
                      children: widget.tabNames.asMap().entries.expand((e) {
                    var index = e.key;
                    var title = e.value;

                    var isSelected = index == selected;
                    var textStyle = isSelected
                        ? TextPalette.linkStyle
                        : TextPalette.linkStyleInverted;
                    var color =
                        isSelected ? Palette.white : widget.appBarColor;
                    var icon = widget.tabIcons?[index];

                    var buttonChild = icon != null
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon,
                                  size: 15,
                                  color: isSelected
                                      ? Palette.primary
                                      : Palette.white),
                              SizedBox(width: 6),
                              Text(title!, style: textStyle),
                            ],
                          )
                        : Text(title!, style: textStyle);

                    var items = <Widget>[];

                    // insert separator before this tab if needed
                    if (widget.separatorBeforeIndex != null &&
                        index == widget.separatorBeforeIndex) {
                      items.add(Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          width: 1,
                          height: 20,
                          color: Palette.white.withValues(alpha: 0.4),
                        ),
                      ));
                    }

                    items.add(ElevatedButton(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: buttonChild,
                      ),
                      onPressed: () =>
                          context.read<AvailableMatchesUiState>().changeTo(index),
                      style: ButtonStyle(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: WidgetStateProperty.all(Size.zero),
                        padding: WidgetStateProperty.all(EdgeInsets.zero),
                        elevation: WidgetStateProperty.all(0),
                        backgroundColor: WidgetStateProperty.all<Color>(color),
                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50.0))),
                      ),
                    ));

                    return items;
                  }).toList()),
                )
              ].toList(),
            ),
          ),
        ),
      )
    ]);

    return Container(
      color: widget.appBarColor,
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          backgroundColor: Palette.greyLightest,
          body: ListView.builder(
              padding: EdgeInsets.zero,
              physics: AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics()),
              itemBuilder: (c, i) {
                var core = (widget.tabContent[selected] == null)
                    ? waitingWidget()
                    : widget.tabContent[selected];

                var list = List<Widget>.from([
                  top,
                  Padding(
                      padding:
                          EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Container(
                                  constraints: BoxConstraints(maxWidth: 1100),
                                  child: core),
                            )
                          ])),
                  SizedBox(
                      height: max(16.0, MediaQuery.of(context).padding.bottom))
                ]);
                return list[i];
              },
              itemCount: 3),
          floatingActionButton: widget.floatingActionButton,
        ),
      ),
    );
  }
}

class GenericMatchInfo extends StatelessWidget {
  final Match match;
  final SportCenter? sportCenter;

  final double topMargin;
  final Function onTap;

  GenericMatchInfo(this.match, this.sportCenter, this.onTap) : topMargin = 10;

  GenericMatchInfo.first(this.match, this.sportCenter, this.onTap)
      : topMargin = 0;

  static String formatDate(DateTime d, BuildContext context) {
    var dayDateFormatPastYear = DateFormat(
        "EEE, MMM dd yyyy HH:mm", getLanguageLocaleWatch(context).languageCode);
    var dayDateFormat = DateFormat(
        "EEE, MMM dd HH:mm", getLanguageLocaleWatch(context).languageCode);
    return DateTime.now().year == d.year
        ? dayDateFormat.format(d)
        : dayDateFormatPastYear.format(d);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
        child: Padding(
          padding: EdgeInsets.only(top: topMargin),
          child: InfoContainer(
              backgroundColor: Palette.white,
              child: IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MatchThumbnail(
                        image: sportCenter?.getThumbnail() ?? Container()),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                    sportCenter?.getName() ??
                                        "" +
                                            " - " +
                                            (sportCenter?.getCourtType() ?? ""),
                                    style: TextPalette.h2),
                              ],
                            ),
                            SizedBox(
                              height: 8,
                            ),
                            Text(
                                formatDate(match.getLocalizedTime(), context) +
                                    " " +
                                    gmtSuffix(sportCenter?.timezoneId),
                                style:
                                    TextPalette.getBodyText(Palette.greyDark)),
                            SizedBox(
                              height: 6,
                            ),
                            (match.status == MatchStatus.unpublished)
                                ? Text(
                                    AppLocalizations.of(context)!
                                        .notPublishedStatus,
                                    style: TextPalette.getBodyText(
                                        Palette.darkWarning))
                                : (match.status == MatchStatus.cancelled)
                                    ? Text(
                                        AppLocalizations.of(context)!
                                            .cancelledStatus,
                                        style: TextPalette.getBodyText(
                                            Palette.destructive))
                                    : (match.isFull())
                                        ? Text(
                                            AppLocalizations.of(context)!
                                                .fullStatus,
                                            style: TextPalette.bodyText,
                                            textAlign: TextAlign.right)
                                        : Text(
                                            AppLocalizations.of(context)!
                                                .spotsLeft(match.maxPlayers -
                                                    match.numPlayersGoing()),
                                            style: TextPalette.bodyTextPrimary,
                                            textAlign: TextAlign.right),
                          ]),
                    ),
                    Column(
                      children: [
                        if (match.isPrivate) Icon(Icons.lock_outline),
                        Spacer(),
                        getBadges(context, match)
                      ],
                    )
                  ],
                ),
              )),
        ),
        onTap: () => onTap(context, match.documentId));
  }

  Widget getBadges(BuildContext context, Match match) {
    var shouldShowUserBadge = context.watch<UserState>().isLoggedIn() &&
        match.isUserGoing(context.watch<UserState>().getLoggedUserDetails()!);

    var badges = [
      if (shouldShowUserBadge)
        Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(50.0)),
              border: Border.all(
                color: Colors.white,
                width: 2.0,
              ),
            ),
            child: UserAvatar(
                14, context.read<UserState>().getLoggedUserDetails())),
      if (shouldShowUserBadge && match.numPlayersGoing() > 1)
        Container(
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
        ),
    ];

    var p = 0.0;
    List<Widget> positionedBadges = [];
    badges.forEach((b) {
      positionedBadges.add(Positioned(child: b, left: p));
      p = p + 20.0;
    });

    return Container(
      height: 26,
      width: 26 + 20 * (badges.length - 1),
      child: Stack(children: positionedBadges.toList()),
    );
  }
}

// variation of match info for past
class GenericMatchInfoPast extends StatelessWidget {
  static String formatDay(DateTime d, BuildContext context) {
    var dayDateFormatPastYear =
        DateFormat("dd MMM yyyy", getLanguageLocaleWatch(context).languageCode);
    var dayDateFormat =
        DateFormat("dd MMM", getLanguageLocaleWatch(context).languageCode);
    return DateTime.now().year == d.year
        ? dayDateFormat.format(d)
        : dayDateFormatPastYear.format(d);
  }

  final String matchId;
  final double topMargin;
  final Function onTap;

  GenericMatchInfoPast(this.matchId, this.onTap) : topMargin = 10;

  GenericMatchInfoPast.first(this.matchId, this.onTap) : topMargin = 0;

  @override
  Widget build(BuildContext context) {
    var match = context.watch<MatchState>().match;

    if (match == null) return Container();

    var sportCenter = match.sportCenter;

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
                        Text(
                            sportCenter?.getName() ??
                                "" +
                                    " - " +
                                    (sportCenter?.getCourtType() ?? ""),
                            style: TextPalette.h2),
                        SizedBox(height: 8),
                        Text(sportCenter?.getName() ?? "",
                            style: TextPalette.bodyText),
                        if (match.status == MatchStatus.cancelled)
                          Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                  AppLocalizations.of(context)!.cancelledStatus,
                                  style: TextPalette.getBodyText(
                                      Palette.destructive)))
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
                child: Column(
              children: [
                Text(formatDay(match.dateTime, context), style: TextPalette.h4)
              ],
            )),
          ],
        ),
      ),
    );

    return InkWell(
        child: Padding(
          padding: EdgeInsets.only(top: topMargin),
          child: child,
        ),
        onTap: () => onTap(context, match.documentId));
  }
}

class MatchThumbnail extends StatelessWidget {
  final Widget image;
  final double height;

  const MatchThumbnail({this.height = 60, required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(width: 60, height: height, child: image);
  }
}

class WeekSeparatorWidget extends StatelessWidget {
  final int weekDelta;

  const WeekSeparatorWidget(this.weekDelta);

  @override
  Widget build(BuildContext context) =>
      TextSeparatorWidget(_getWeekDesc(context));

  _getWeekDesc(context) {
    if (weekDelta == 0) {
      return AppLocalizations.of(context)!.thisWeek.toUpperCase();
    }
    if (weekDelta == 1) {
      return AppLocalizations.of(context)!.nextWeek.toUpperCase();
    }
    return AppLocalizations.of(context)!.moreThanTwoWeeks.toUpperCase();
  }
}
