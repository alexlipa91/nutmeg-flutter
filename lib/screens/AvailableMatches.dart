import "package:collection/collection.dart";
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/GenericAvailableMatches.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:nutmeg/widgets/Texts.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../state/AvailableMatchesState.dart';
import '../state/MatchesState.dart';
import '../state/UserState.dart';
import '../utils/UiUtils.dart';
import '../widgets/GenericAvailableMatches.dart';

// main widget
class AvailableMatches extends StatelessWidget {
  final RefreshController refreshController = RefreshController();

  Future<void> onTap(BuildContext context, String matchId,
      RefreshController refreshController) async {

    Get.find().pushPage(
      name: '/match',
      arguments: matchId,
    );
    // Get.toNamed("/match/" + matchId);
    await refreshController.requestRefresh();
  }

  Widget pastWidgets(
      BuildContext context, RefreshController refreshController) {
    var state = context.watch<MatchesState>();
    var userState = context.watch<UserState>();

    if (state.getMatches() == null) {
      return null;
    }

    if (!userState.isLoggedIn()) {
      return getEmptyStateWidget(context, false);
    }

    var now = DateTime.now();
    var matches = state
        .getMatches()
        .where((e) => (!e.isTest || userState.isTestMode))
        .where((m) => m.isUserGoing(userState.getLoggedUserDetails()))
        .where((m) => m.dateTime.isBefore(now));

    List<Widget> widgets = [];

    if (matches.isNotEmpty) {
      matches.sortedBy((e) => e.dateTime).reversed.forEachIndexed((index, m) {
        if (index == 0) {
          widgets.add(GenericMatchInfoPast.first(
              m.documentId, onTap, refreshController));
        } else {
          widgets.add(
              GenericMatchInfoPast(m.documentId, onTap, refreshController));
        }
      });
    }

    if (widgets.isEmpty) return getEmptyStateWidget(context, false);

    return Column(children: widgets);
  }

  Widget goingWidgets(
      BuildContext context, RefreshController refreshController) {
    var state = context.watch<MatchesState>();
    var userState = context.watch<UserState>();

    if (state.getMatches() == null) {
      return null;
    }

    if (!userState.isLoggedIn()) {
      return getEmptyStateWidget(context);
    }

    var now = DateTime.now();
    var matches = state
        .getMatches()
        .where((e) => (!e.isTest || userState.isTestMode))
        .where((m) => m.isUserGoing(userState.getLoggedUserDetails()))
        .where((m) => m.dateTime.isAfter(now));

    List<Widget> widgets = [];

    if (matches.isNotEmpty) {
      matches.sortedBy((e) => e.dateTime).forEachIndexed((index, m) {
        if (index == 0) {
          widgets.add(
              GenericMatchInfo.first(m.documentId, onTap, refreshController));
        } else {
          widgets.add(GenericMatchInfo(m.documentId, onTap, refreshController));
        }
      });
    }

    if (widgets.isEmpty) return getEmptyStateWidget(context, false);

    return Column(children: widgets);
  }

  Widget upcomingWidgets(
      BuildContext context, RefreshController refreshController) {
    var state = context.watch<MatchesState>();
    var userState = context.watch<UserState>();

    if (state.getMatches() == null) {
      return null;
    }

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
      var widgets =
          grouped[w].sortedBy((e) => e.dateTime).mapIndexed((index, match) {
        if (index == 0) {
          return GenericMatchInfo.first(
              match.documentId, onTap, refreshController);
        }
        return GenericMatchInfo(match.documentId, onTap, refreshController);
      });

      result.add(Section(
        topSpace: 16,
        title: (w == 0)
            ? "THIS WEEK"
            : (w == 1)
                ? "NEXT WEEK"
                : "IN MORE THAN TWO WEEKS",
        body: Column(
          children: widgets.toList(),
        ),
      ));
    });

    if (result.isEmpty) return getEmptyStateWidget(context, false);

    return Column(children: result);
  }

  Widget getMyMatchesWidgets(
      BuildContext context, RefreshController refreshController) {
    var state = context.read<MatchesState>();

    if (state.getMatches() == null) {
      return null;
    }

    return getEmptyStateWidget(context);
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
                  onTap: (BuildContext context) => Get.toNamed("/createMatch")),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = context.watch<UserState>().isLoggedIn() &&
        context.watch<UserState>().getLoggedUserDetails().isAdmin;

    return MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (context) => AvailableMatchesUiState()),
        ],
        builder: (context, _) => GenericAvailableMatchesList(
            Palette.primary,
            ["UPCOMING", "GOING", "PAST", if (isAdmin) "MY MATCHES"].toList(),
            [
              upcomingWidgets(context, refreshController),
              goingWidgets(context, refreshController),
              pastWidgets(context, refreshController),
              if (isAdmin) getMyMatchesWidgets(context, refreshController)
            ].toList(),
            getEmptyStateWidget(context),
            refreshController,
            context.watch<AvailableMatchesUiState>().current == 3
                ? FloatingActionButton(
                    backgroundColor: Palette.primary,
                    child: Icon(Icons.add, color: Palette.white),
                    onPressed: () => Get.toNamed("/createMatch"))
                : null));
  }
}
