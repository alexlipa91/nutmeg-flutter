import "package:collection/collection.dart";
import 'package:flutter/material.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/Buttons.dart';
import 'package:nutmeg/widgets/GenericAvailableMatches.dart';
import 'package:nutmeg/widgets/Texts.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../state/AvailableMatchesState.dart';
import '../state/LoadOnceState.dart';
import '../state/MatchesState.dart';
import '../state/UserState.dart';
import '../utils/UiUtils.dart';
import '../widgets/GenericAvailableMatches.dart';
import 'MatchDetails.dart';

// main widget
class AvailableMatches extends StatelessWidget {
  static const routeName = "/availableMatches";

  final RefreshController refreshController = RefreshController();

  List<Widget> getButtons(BuildContext context) {
    var uiState = context.read<AvailableMatchesUiState>();

    return [
      uiState.getCurrentSelection() == MatchesSelectionStatus.ALL
          ? Expanded(
              child: LeftButtonOn(
                  "ALL", () => uiState.changeTo(MatchesSelectionStatus.ALL)))
          : Expanded(
              child: LeftButtonOff(
                  "ALL", () => uiState.changeTo(MatchesSelectionStatus.ALL))),
      uiState.getCurrentSelection() == MatchesSelectionStatus.MY_GAMES
          ? Expanded(
              child: RightButtonOn("MY MATCHES",
                  () => uiState.changeTo(MatchesSelectionStatus.MY_GAMES)))
          : Expanded(
              child: RightButtonOff("MY MATCHES",
                  () => uiState.changeTo(MatchesSelectionStatus.MY_GAMES)))
    ];
  }

  Future<void> onTap(BuildContext context, String matchId,
      RefreshController refreshController) async {
    await Navigator.pushNamed(
      context,
      MatchDetails.routeName,
      arguments: ScreenArguments(
        matchId,
        false,
      ),
    );
    await refreshController.requestRefresh();
  }

  List<Widget> getGamesWidget(
      BuildContext context, RefreshController refreshController) {
    var uiState = context.read<AvailableMatchesUiState>();
    var state = context.read<MatchesState>();
    var loadOnceState = context.read<LoadOnceState>();
    var userState = context.read<UserState>();

    return (uiState.getCurrentSelection() == MatchesSelectionStatus.ALL)
        ? allGamesWidgets(
            state, uiState, userState, loadOnceState, refreshController)
        : myGamesWidgets(
            state, userState, uiState, loadOnceState, refreshController);
  }

  List<Widget> myGamesWidgets(
      MatchesState state,
      UserState userState,
      AvailableMatchesUiState uiState,
      LoadOnceState loadOnceState,
      RefreshController refreshController) {
    var matches = state
        .getMatches()
        .where((e) => (!e.isTest || userState.isTestMode))
        .where((m) => m.isUserGoing(userState.getLoggedUserDetails()));

    var now = DateTime.now();

    List<Match> past = matches.where((m) => m.dateTime.isBefore(now)).toList();
    List<Match> future = matches.where((m) => m.dateTime.isAfter(now)).toList();

    List<Widget> widgets = [];

    if (future.isNotEmpty) {
      widgets.add(TextSeparatorWidget("UPCOMING MATCHES"));
      future.sortedBy((e) => e.dateTime).forEachIndexed((index, m) {
        if (index == 0) {
          widgets.add(
              GenericMatchInfo.first(m.documentId, onTap, refreshController));
        } else {
          widgets.add(GenericMatchInfo(m.documentId, onTap, refreshController));
        }
      });
    }

    if (past.isNotEmpty) {
      widgets.add(TextSeparatorWidget("PAST MATCHES"));
      past.sortedBy((e) => e.dateTime).reversed.forEachIndexed((index, m) {
        if (index == 0) {
          widgets.add(GenericMatchInfoPast.first(m.documentId, onTap));
        } else {
          widgets.add(GenericMatchInfoPast(m.documentId, onTap));
        }
      });
    }

    return widgets;
  }

  List<Widget> allGamesWidgets(
      MatchesState state,
      AvailableMatchesUiState uiState,
      UserState userState,
      LoadOnceState loadOnceState,
      RefreshController refreshController) {
    var matches = state
        .getMatchesInFuture()
        .where((e) => !e.wasCancelled())
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

    List<Widget> result = [];

    sortedWeeks.forEach((w) {
      result.add(WeekSeparatorWidget(w));
      grouped[w].sortedBy((e) => e.dateTime).forEachIndexed((index, match) {
        if (index == 0) {
          result.add(GenericMatchInfo.first(
              match.documentId, onTap, refreshController));
        } else {
          result.add(
              GenericMatchInfo(match.documentId, onTap, refreshController));
        }
      });
    });

    return result;
  }

  static Widget getEmptyStateWidget(BuildContext context) {
    var uiState = context.read<AvailableMatchesUiState>();
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Container(
        child: Column(
          children: [
            Image.asset(
                "assets/empty_state/illustration_" +
                    ((uiState.selected == MatchesSelectionStatus.ALL)
                        ? "01"
                        : "02") +
                    ".png",
                height: 400),
            Text("No matches here",
                style: TextPalette.h1Default, textAlign: TextAlign.center)
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
        child: GenericAvailableMatchesList(
            RoundedTopBar(getButtons: getButtons, color: Palette.primary),
            getGamesWidget,
            getEmptyStateWidget,
            refreshController,
            Palette.primary
        ));
  }
}
