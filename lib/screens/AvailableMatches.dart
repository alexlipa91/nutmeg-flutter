import "package:collection/collection.dart";
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/screens/ChangeCity.dart';
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

  Future<void> onTap(BuildContext context, String matchId) async => context.go("/match/$matchId");

  Widget? pastWidgets(BuildContext context) {
    var state = context.watch<MatchesState>();
    var userState = context.watch<UserState>();

    if (!userState.isLoggedIn()) {
      return getEmptyStateWidget(context, false);
    }

    var matches = state.getMatchesForTab("PAST");

    if (matches == null)
      return null;

    List<Widget> widgets = [];

    if (matches.isNotEmpty) {
      matches.sortedBy((e) => e.dateTime).reversed.forEachIndexed((index, m) {
        if (index == 0) {
          widgets.add(GenericMatchInfoPast.first(m.documentId, onTap));
        } else {
          widgets.add(
              GenericMatchInfoPast(m.documentId, onTap));
        }
      });
    }

    if (widgets.isEmpty) return getEmptyStateWidget(context, false);

    return Column(children: widgets);
  }

  Widget? goingWidgets(BuildContext context) {
    var state = context.watch<MatchesState>();
    var userState = context.watch<UserState>();

    if (!userState.isLoggedIn()) {
      return getEmptyStateWidget(context);
    }

    var matches = state.getMatchesForTab("GOING");

    if (matches == null)
      return null;

    List<Widget> widgets = [];

    if (matches.isNotEmpty) {
      matches.sortedBy((e) => e.dateTime).forEachIndexed((index, match) {
        var s = match.sportCenter;
        var w;
        if (index == 0) {
          w = GenericMatchInfo.first(match, s, onTap);
        } else {
          w = GenericMatchInfo(match, s, onTap);
        }
        widgets.add(w);
      });
    }

    if (widgets.isEmpty) return getEmptyStateWidget(context, false);

    return Column(children: widgets);
  }

  Widget? upcomingWidgets(BuildContext context) {
    var state = context.watch<MatchesState>();
    // var loadOnceState = context.watch<LoadOnceState>();

    var matches = state.getMatchesForTab("UPCOMING");

    if (matches == null)
      return null;

    var beginningOfCurrentWeek = getBeginningOfTheWeek(DateTime.now());

    // group by delta of days from first day of the week
    var grouped = matches.groupListsBy((m) {
      var durationDifference =
          getBeginningOfTheWeek(m.dateTime).difference(beginningOfCurrentWeek);
      return durationDifference.inDays ~/ 7;
    });

    List<int> sortedWeeks = grouped.keys.toList()..sort();

    var groupedByWeeksIntervals = Map<String, List<Match>>();
    if (grouped.containsKey(0))
      groupedByWeeksIntervals[AppLocalizations.of(context)!.thisWeek] = grouped[0]!;
    if (grouped.containsKey(1))
      groupedByWeeksIntervals[AppLocalizations.of(context)!.nextWeek] = grouped[1]!;
    groupedByWeeksIntervals[AppLocalizations.of(context)!.moreThanTwoWeeks] = List<Match>.from([]);
    sortedWeeks.forEach((w) {
      if (w > 1) {
        groupedByWeeksIntervals[AppLocalizations.of(context)!.moreThanTwoWeeks]
            ?.addAll(grouped[w]!);
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
                w = GenericMatchInfo.first(match, s, onTap);
              else
                w = GenericMatchInfo(match, s, onTap);
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

  Widget? getMyMatchesWidgets(BuildContext context) {
    var state = context.read<MatchesState>();
    var userState = context.read<UserState>();

    if (!userState.isLoggedIn()) {
      return getEmptyStateWidget(context);
    }

    var matches = state.getMatchesForTab("MY MATCHES");

    if (matches == null)
      return null;

    List<Widget> widgets = [];

    if (matches.isNotEmpty) {
      matches.sortedBy((e) => e.dateTime).reversed.forEachIndexed((index, m) {
        if (index == 0) {
          widgets.add(
              GenericMatchInfo.first(state.getMatch(m.documentId)!,
                  m.sportCenter,
                  onTap));
        } else {
          widgets.add(GenericMatchInfo(state.getMatch(m.documentId)!,
              m.sportCenter,
              onTap));
        }
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
            Image.asset("assets/empty_state/illustration_0${(random.nextInt(2) + 1).toString()}.png",
              gaplessPlayback: true,),
            Text(AppLocalizations.of(context)!.noMatchesHere,
                style: TextPalette.h1Default, textAlign: TextAlign.center),
            SizedBox(height: 4),
            Text(AppLocalizations.of(context)!.browseOrCreateText,
                style: TextPalette.bodyText, textAlign: TextAlign.center),
            if (withAction) SizedBox(height: 4),
            if (withAction)
              TappableLinkText(
                  text: AppLocalizations.of(context)!.createNewMatchActionText,
                  onTap: (BuildContext context) => context.go("/createMatch")
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                AppLocalizations.of(context)!.myMatches.toUpperCase(),
              ].toList(),
              [
                upcomingWidgets(context),
                goingWidgets(context),
                pastWidgets(context),
                getMyMatchesWidgets(context)
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
                      LocationInfo? newUserLocation = await Navigator.push(context,
                        MaterialPageRoute(builder: (context) => ChangeCity()));

                      if (newUserLocation != null
                          && newUserLocation.placeId !=
                          context.read<UserState>().getLocationInfo().placeId) {
                        if (context.read<UserState>().isLoggedIn()) {
                          await context
                              .read<UserState>()
                              .editUser({"location": newUserLocation.toJson()});
                        } else {
                          context.read<UserState>()
                              .setCustomLocationInfo(newUserLocation);
                        }

                        await context.read<MatchesState>()
                            .refreshState(context, reset: true);
                      }
                    },
                    child: Row(children: [
                      Text(context.watch<UserState>().getLocationInfo().getText(),
                          style: TextPalette.h1Inverted),
                      SizedBox(width: 4,),
                      Icon(Icons.keyboard_arrow_down_outlined, size: 28, color: Palette.white)
                    ]),
                  ),
                ],
              ),
              () async {
                print("refreshing state for available matches");
                await context.read<MatchesState>().refreshState(context);
              }
            )
    );
  }
}

