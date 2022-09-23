import "package:collection/collection.dart";
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/state/LoadOnceState.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/GenericAvailableMatches.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:nutmeg/widgets/Texts.dart';
import 'package:provider/provider.dart';

import '../state/AvailableMatchesState.dart';
import '../state/MatchesState.dart';
import '../state/UserState.dart';
import '../utils/UiUtils.dart';
import '../widgets/GenericAvailableMatches.dart';

// main widget
class AvailableMatches extends StatelessWidget {

  Future<void> onTap(BuildContext context, String matchId) async => context.go("/match/$matchId");

  bool _isLoading(BuildContext context) {
    var state = context.read<MatchesState>();
    var loadOnceState = context.read<LoadOnceState>();

    if (state.getMatches() == null) {
      return true;
    }
    if (state
        .getMatches()!
        .where((m) => loadOnceState.getSportCenter(m.sportCenterId) == null)
        .isNotEmpty) return true;
    return false;
  }

  Widget? pastWidgets(BuildContext context) {
    var state = context.watch<MatchesState>();
    var userState = context.watch<UserState>();

    if (_isLoading(context))
      return null;

    if (!userState.isLoggedIn()) {
      return getEmptyStateWidget(context, false);
    }

    var now = DateTime.now();
    var matches = state
        .getMatches()!
        .where((e) => (!e.isTest || userState.isTestMode))
        .where((m) => userState.isLoggedIn() && m.isUserGoing(userState.getLoggedUserDetails()!))
        .where((m) => m.dateTime.isBefore(now));

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
    var loadOnceState = context.watch<LoadOnceState>();

    if (_isLoading(context))
      return null;

    if (!userState.isLoggedIn()) {
      return getEmptyStateWidget(context);
    }

    var now = DateTime.now();
    var matches = state
        .getMatches()!
        .where((e) => (!e.isTest || userState.isTestMode))
        .where((m) => userState.isLoggedIn() && m.isUserGoing(userState.getLoggedUserDetails()!))
        .where((m) => m.dateTime.isAfter(now));

    List<Widget> widgets = [];

    if (matches.isNotEmpty) {
      matches.sortedBy((e) => e.dateTime).forEachIndexed((index, m) {
        if (index == 0) {
          widgets.add(
              GenericMatchInfo.first(state.getMatch(m.documentId)!,
                  loadOnceState.getSportCenter(m.sportCenterId)!,
                  onTap));
        } else {
          widgets.add(GenericMatchInfo(state.getMatch(m.documentId)!,
              loadOnceState.getSportCenter(m.sportCenterId)!, onTap));
        }
      });
    }

    if (widgets.isEmpty) return getEmptyStateWidget(context, false);

    return Column(children: widgets);
  }

  Widget? upcomingWidgets(BuildContext context) {
    var state = context.watch<MatchesState>();
    var userState = context.watch<UserState>();
    var loadOnceState = context.watch<LoadOnceState>();

    if (_isLoading(context))
      return null;

    var hideStatuses = Set.of([MatchStatus.unpublished]);
    var matches = state
        .getMatchesInFuture()
        .where((e) => !hideStatuses.contains(e.status))
        .where((e) => (!e.isTest || userState.isTestMode))
        .toList();

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
      groupedByWeeksIntervals["THIS WEEK"] = grouped[0]!;
    if (grouped.containsKey(1))
      groupedByWeeksIntervals["NEXT WEEK"] = grouped[1]!;
    groupedByWeeksIntervals["IN MORE THAN TWO WEEKS"] = List<Match>.from([]);
    sortedWeeks.forEach((w) {
      if (w > 1) {
        groupedByWeeksIntervals["IN MORE THAN TWO WEEKS"]?.addAll(grouped[w]!);
      }
    });

    List<Widget> result = [];
    groupedByWeeksIntervals.entries.forEachIndexed((index, e) {
      if (e.value.isNotEmpty) {
        var widgets =
            e.value.sortedBy((e) => e.dateTime).mapIndexed((index, match) {
          if (index == 0) {
            return GenericMatchInfo.first(state.getMatch(match.documentId)!,
                loadOnceState.getSportCenter(match.sportCenterId)!, onTap);
          }
          return GenericMatchInfo(state.getMatch(match.documentId)!,
              loadOnceState.getSportCenter(match.sportCenterId)!, onTap);
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
    var loadOnceState = context.watch<LoadOnceState>();

    if (_isLoading(context))
      return null;

    if (!userState.isLoggedIn()) {
      return getEmptyStateWidget(context);
    }

    var matches = state
        .getMatches()!
        .where((e) => (!e.isTest || userState.isTestMode))
        .where((m) =>
            m.organizerId == userState.getLoggedUserDetails()!.documentId);

    List<Widget> widgets = [];

    if (matches.isNotEmpty) {
      matches.sortedBy((e) => e.dateTime).reversed.forEachIndexed((index, m) {
        if (index == 0) {
          widgets.add(
              GenericMatchInfo.first(state.getMatch(m.documentId)!,
                  loadOnceState.getSportCenter(m.sportCenterId)!, onTap));
        } else {
          widgets.add(GenericMatchInfo(state.getMatch(m.documentId)!,
              loadOnceState.getSportCenter(m.sportCenterId)!, onTap));
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
            Image.asset("assets/empty_state/illustration_01.png"),
            Text("No matches here",
                style: TextPalette.h1Default, textAlign: TextAlign.center),
            SizedBox(height: 4),
            Text("Browse matches or create your own match",
                style: TextPalette.bodyText, textAlign: TextAlign.center),
            if (withAction) SizedBox(height: 4),
            if (withAction)
              TappableLinkText(
                  text: "CREATE A NEW MATCH",
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
              ["UPCOMING", "GOING", "PAST", "MY MATCHES"].toList(),
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
                children: [
                  Text("Find football matches in",
                      style: TextPalette.bodyTextInverted),
                  Text("Amsterdam", style: TextPalette.h1Inverted),
                ],
              ),
            )
    );
  }
}

