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

    return Column(children: widgets);
  }

  Widget? goingWidgets(BuildContext context) {
    var state = context.watch<MatchesState>();

    if (!context.read<UserState>().isLoggedIn()) {
      return getEmptyStateWidget(context);
    }

    var matches = context
        .select<MatchesState, List<MatchState>?>((s) => s.getGoingMatches());

    if (matches == null) return null;

    List<Widget> widgets = [];

    if (matches.isNotEmpty) {
      matches.sortedBy((e) => e.match!.dateTime).forEachIndexed((index, match) {
        var s = match.match!.sportCenter;
        var w;
        if (index == 0) {
          w = widgetWithMatchProvider(
              state,
              GenericMatchInfo.first(match.match!, s, onTap),
              match.match!.documentId);
        } else {
          w = widgetWithMatchProvider(
              state,
              GenericMatchInfo(match.match!, s, onTap),
              match.match!.documentId);
        }
        widgets.add(w);
      });
    }

    if (widgets.isEmpty) return getEmptyStateWidget(context, false);

    return Column(children: widgets);
  }

  Widget? upcomingWidgets(BuildContext context) {
    var matches = context
        .select<MatchesState, List<MatchState>?>((s) => s.getUpcomingMatches());

    if (matches == null) return null;

    var beginningOfCurrentWeek = getBeginningOfTheWeek(DateTime.now());

    // group by delta of days from first day of the week
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
        Iterable<Widget> widgets =
            e.value.sortedBy((e) => e.dateTime).mapIndexed((index, match) {
          var s = match.sportCenter;
          var w;
          if (index == 0)
            w = widgetWithMatchProvider(context.read<MatchesState>(),
                GenericMatchInfo.first(match, s, onTap), match.documentId);
          else
            w = widgetWithMatchProvider(
                context.read<MatchesState>(),
                GenericMatchInfo(match, s, onTap),
                match.documentId);
          return w;
        });

        var section;
        if (index == 0) {
          section = Section(
            // we already have a top padding
            topSpace: 16,
            title: e.key,
            body: Column(
              children: widgets.toList(),
            ),
          );
        } else {
          section = Section(
            title: e.key,
            body: Column(
              children: widgets.toList(),
            ),
          );
        }
        result.add(section);
      }
    });

    if (result.isEmpty) return getEmptyStateWidget(context, false);

    return Column(children: result);
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

    return Column(children: widgets);
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
    var myMatchesWidgets = getMyMatchesWidgets(context, state);

    return MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (context) => AvailableMatchesUiState()),
        ],
        builder: (context, _) => GenericAvailableMatchesList(
                Palette.primary,
                [
                  AppLocalizations.of(context)!.upcoming.toUpperCase(),
                  AppLocalizations.of(context)!.going.toUpperCase(),
                  AppLocalizations.of(context)!.past.toUpperCase(),
                  if (isLoggedIn)
                    AppLocalizations.of(context)!.myMatches.toUpperCase(),
                ].toList(),
                [
                  upcomingWidgets(context),
                  goingWidgets(context),
                  pastWidgets(context),
                  if (isLoggedIn)
                    myMatchesWidgets ?? getEmptyStateWidget(context)
                ].toList(),
                getEmptyStateWidget(context),
                context.watch<AvailableMatchesUiState>().current == 3
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
            }));
  }
}
