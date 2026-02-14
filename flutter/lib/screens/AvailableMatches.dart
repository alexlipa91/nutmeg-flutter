import "package:collection/collection.dart";
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/model/LocationInfo.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/screens/ChangeCity.dart';
import 'package:nutmeg/state/MatchState.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/GenericAvailableMatches.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:nutmeg/widgets/Texts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:math';

import '../state/AvailableMatchesState.dart';
import '../state/MatchesState.dart';
import '../state/UserState.dart';
import '../utils/UiUtils.dart';

// main widget
class AvailableMatches extends StatelessWidget {
  static Random random = new Random();

  Future<void> onTap(BuildContext context, String matchId) async =>
      context.go("/match/$matchId");

  Widget widgetWithMatchProvider(
      MatchesState state, Widget widget, String matchId) {
    return ChangeNotifierProvider<MatchState>.value(
      value: state.getMatch(matchId),
      child: widget,
    );
  }

  Widget? pastWidgets(BuildContext context) {
    var state = context.watch<MatchesState>();

    if (!context.read<UserState>().isLoggedIn()) {
      return getEmptyStateWidget(context, false);
    }

    var matches = context
        .select<MatchesState, List<MatchState>?>((s) => s.getPastMatches());

    if (matches == null) return null;

    List<Widget> widgets = [];

    if (matches.isNotEmpty) {
      var sorted = matches.sortedBy((e) => e.match!.dateTime).reversed.toList();
      var locale = Localizations.localeOf(context).languageCode;

      var grouped = sorted.groupListsBy((m) {
        var date = m.match!.dateTime;
        return "${date.year}-${date.month}";
      });

      grouped.entries.forEachIndexed((groupIndex, entry) {
        var firstDate = entry.value.first.match!.dateTime;
        var label = DateFormat("MMMM yyyy", locale).format(firstDate).toUpperCase();

        var matchWidgets = entry.value.mapIndexed((index, m) {
          if (groupIndex == 0 && index == 0) {
            return widgetWithMatchProvider(state,
                GenericMatchInfoPast.first(m.match!.documentId, onTap),
                m.match!.documentId);
          } else {
            return widgetWithMatchProvider(state,
                GenericMatchInfoPast(m.match!.documentId, onTap),
                m.match!.documentId);
          }
        }).toList();

        widgets.add(Section(
          topSpace: groupIndex == 0 ? 16 : 32,
          title: label,
          body: Column(children: matchWidgets),
        ));
      });
    }

    if (widgets.isEmpty) return getEmptyStateWidget(context, false);

    widgets.add(_buildLoadMoreButton(
      context,
      hasMore: state.pastMatchesHasMore,
      isLoading: state.pastMatchesLoadingMore,
      onPressed: () => state.fetchMorePastMatches(),
    ));

    return Column(children: widgets);
  }


  Widget? getMyMatchesWidgets(BuildContext context, MatchesState state) {
    var matches = context
        .select<MatchesState, List<MatchState>?>((s) => s.getMyOrganizedMatches());

    if (matches == null || matches.isEmpty) return null;

    List<Widget> widgets = [];

    if (matches.isNotEmpty) {
      var sorted = matches.sortedBy((e) => e.match!.dateTime).reversed.toList();
      var locale = Localizations.localeOf(context).languageCode;

      var grouped = sorted.groupListsBy((m) {
        var date = m.match!.dateTime;
        return "${date.year}-${date.month}";
      });

      grouped.entries.forEachIndexed((groupIndex, entry) {
        var firstDate = entry.value.first.match!.dateTime;
        var label = DateFormat("MMMM yyyy", locale).format(firstDate).toUpperCase();

        var matchWidgets = entry.value.mapIndexed((index, m) {
          if (groupIndex == 0 && index == 0) {
            return widgetWithMatchProvider(state,
                GenericMatchInfo.first(m.match!, m.match!.sportCenter, onTap),
                m.match!.documentId);
          } else {
            return widgetWithMatchProvider(state,
                GenericMatchInfo(m.match!, m.match!.sportCenter, onTap),
                m.match!.documentId);
          }
        }).toList();

        widgets.add(Section(
          topSpace: groupIndex == 0 ? 16 : 32,
          title: label,
          body: Column(children: matchWidgets),
        ));
      });
    }

    if (widgets.isEmpty) return getEmptyStateWidget(context);

    widgets.add(_buildLoadMoreButton(
      context,
      hasMore: state.myOrganizedMatchesHasMore,
      isLoading: state.myOrganizedMatchesLoadingMore,
      onPressed: () => state.fetchMoreMyOrganizedMatches(),
    ));

    return Column(children: widgets);
  }

  Widget _buildLoadMoreButton(
    BuildContext context, {
    required bool hasMore,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    if (!hasMore) return SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: 16, bottom: 8),
      child: Center(
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                onPressed: onPressed,
                icon: Icon(Icons.expand_more, color: Palette.primary, size: 28),
              ),
      ),
    );
  }

  Widget getEmptyStateWidget(BuildContext context, [bool withAction = true]) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Container(
        child: Column(
          children: [
            Image.asset(
              "assets/empty_state/illustration_0${(random.nextInt(2) + 1).toString()}.png",
              gaplessPlayback: true,
            ),
            Text(AppLocalizations.of(context)!.noMatchesHere,
                style: TextPalette.h1Default, textAlign: TextAlign.center),
            SizedBox(height: 4),
            Text(AppLocalizations.of(context)!.browseOrCreateText,
                style: TextPalette.bodyText, textAlign: TextAlign.center),
            if (withAction) SizedBox(height: 4),
            if (withAction)
              TappableLinkText(
                  text: AppLocalizations.of(context)!.createNewMatchActionText,
                  onTap: (BuildContext context) => context.go("/createMatch")),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var state = context.watch<MatchesState>();
    var userState = context.watch<UserState>();

    var locationInfo =
        userState.getLoggedUserDetails()?.location ?? state.locationInfo;

    var isLoggedIn = userState.isLoggedIn();
    var myMatchesWidgets = isLoggedIn
        ? getMyMatchesWidgets(context, state)
        : null;

    var tabNames = <String>[
      AppLocalizations.of(context)!.upcoming.toUpperCase(),
      AppLocalizations.of(context)!.past.toUpperCase(),
      if (isLoggedIn) AppLocalizations.of(context)!.myMatches.toUpperCase(),
    ];

    var tabContent = <Widget?>[
      _playUpcomingWidgets(context),
      pastWidgets(context),
      if (isLoggedIn) myMatchesWidgets ?? getEmptyStateWidget(context),
    ];

    return MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (context) => AvailableMatchesUiState()),
        ],
        builder: (context, _) {
          var currentTab = context.watch<AvailableMatchesUiState>().current;
          var isMyGamesTab = isLoggedIn && currentTab == tabNames.length - 1;

          return GenericAvailableMatchesList(
                Palette.primary,
                tabNames,
                tabContent,
                getEmptyStateWidget(context),
                isMyGamesTab
                    ? FloatingActionButton(
                        backgroundColor: Palette.primary,
                        child: Icon(Icons.add, color: Palette.white),
                        onPressed: () => context.go("/createMatch"))
                    : null,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.topHeader,
                        style: TextPalette.bodyTextInverted),
                    InkWell(
                      onTap: () async {
                        LocationInfo? newUserLocation = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ChangeCity()));

                        if (newUserLocation != null) {
                          if (context.read<UserState>().isLoggedIn()) {
                            await context
                                .read<UserState>()
                                .setLocation(newUserLocation);
                          } else {
                            context
                                .read<MatchesState>()
                                .setLocationInfo(newUserLocation);
                          }
                          await state.refreshState();
                        }
                      },
                      child: Row(children: [
                        Text(locationInfo?.getText() ?? "",
                            style: TextPalette.h1Inverted),
                        SizedBox(
                          width: 4,
                        ),
                        Icon(Icons.keyboard_arrow_down_outlined,
                            size: 28, color: Palette.white)
                      ]),
                    ),
                  ],
                ), () async {
              await state.refreshState();
            },
            tabIcons: isLoggedIn ? {2: Icons.edit_calendar_outlined} : null,
            separatorBeforeIndex: isLoggedIn ? 2 : null,
            );
        });
  }

  /// Upcoming tab: shows going matches first, then all upcoming matches
  Widget? _playUpcomingWidgets(BuildContext context) {
    var state = context.watch<MatchesState>();
    var isLoggedIn = context.read<UserState>().isLoggedIn();

    var upcomingMatches = context
        .select<MatchesState, List<MatchState>?>((s) => s.getUpcomingMatches());
    var goingMatches = isLoggedIn
        ? context.select<MatchesState, List<MatchState>?>((s) => s.getGoingMatches())
        : <MatchState>[];

    if (upcomingMatches == null) return null;

    // separate going from not-going upcoming
    var goingIds = (goingMatches ?? []).map((m) => m.match!.documentId).toSet();

    List<Widget> widgets = [];

    // going matches section (if any)
    if (goingMatches != null && goingMatches.isNotEmpty) {
      var sorted = goingMatches.sortedBy((e) => e.match!.dateTime);
      var goingWidgetsList = sorted.mapIndexed((index, match) {
        var s = match.match!.sportCenter;
        if (index == 0) {
          return widgetWithMatchProvider(
              state,
              GenericMatchInfo.first(match.match!, s, onTap),
              match.match!.documentId);
        } else {
          return widgetWithMatchProvider(
              state,
              GenericMatchInfo(match.match!, s, onTap),
              match.match!.documentId);
        }
      }).toList();

      widgets.add(Section(
        topSpace: 16,
        title: AppLocalizations.of(context)!.going.toUpperCase(),
        body: Column(children: goingWidgetsList),
      ));
    }

    // other upcoming matches (excluding the ones already shown as going)
    var otherUpcoming = upcomingMatches
        .where((m) => !goingIds.contains(m.match!.documentId))
        .toList();

    if (otherUpcoming.isNotEmpty) {
      var upcomingContent = _buildUpcomingGrouped(context, otherUpcoming);
      if (upcomingContent != null) {
        widgets.add(upcomingContent);
      }
    }

    if (widgets.isEmpty) return getEmptyStateWidget(context, false);

    return Column(children: widgets);
  }

  /// Groups upcoming matches by week intervals
  Widget? _buildUpcomingGrouped(BuildContext context, List<MatchState> matches) {
    var state = context.read<MatchesState>();
    var beginningOfCurrentWeek = getBeginningOfTheWeek(DateTime.now());

    var grouped = matches.groupListsBy((m) {
      var durationDifference = getBeginningOfTheWeek(m.match!.dateTime)
          .difference(beginningOfCurrentWeek);
      return durationDifference.inDays ~/ 7;
    });

    List<int> sortedWeeks = grouped.keys.toList()..sort();

    var groupedByWeeksIntervals = Map<String, List<Match>>();
    if (grouped.containsKey(0))
      groupedByWeeksIntervals[AppLocalizations.of(context)!.thisWeek] =
          grouped[0]!.map((e) => e.match!).toList();
    if (grouped.containsKey(1))
      groupedByWeeksIntervals[AppLocalizations.of(context)!.nextWeek] =
          grouped[1]!.map((e) => e.match!).toList();
    groupedByWeeksIntervals[AppLocalizations.of(context)!.moreThanTwoWeeks] =
        List<Match>.from([]);
    sortedWeeks.forEach((w) {
      if (w > 1) {
        groupedByWeeksIntervals[AppLocalizations.of(context)!.moreThanTwoWeeks]
            ?.addAll(grouped[w]!.map((e) => e.match!).toList());
      }
    });

    List<Widget> result = [];
    groupedByWeeksIntervals.entries.forEachIndexed((index, e) {
      if (e.value.isNotEmpty) {
        Iterable<Widget> sectionWidgets =
            e.value.sortedBy((e) => e.dateTime).mapIndexed((index, match) {
          var s = match.sportCenter;
          if (index == 0)
            return widgetWithMatchProvider(state,
                GenericMatchInfo.first(match, s, onTap), match.documentId);
          else
            return widgetWithMatchProvider(
                state, GenericMatchInfo(match, s, onTap), match.documentId);
        });

        result.add(Section(
          topSpace: result.isEmpty ? 16 : 32,
          title: e.key,
          body: Column(children: sectionWidgets.toList()),
        ));
      }
    });

    if (result.isEmpty) return null;
    return Column(children: result);
  }
}
