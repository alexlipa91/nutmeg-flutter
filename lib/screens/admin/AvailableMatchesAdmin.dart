import "package:collection/collection.dart";
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/state/AvailableMatchesState.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../state/MatchesState.dart';
import '../../utils/UiUtils.dart';
import '../../widgets/GenericAvailableMatches.dart';

// main widget
class AdminAvailableMatches extends StatelessWidget {
  final RefreshController refreshController = RefreshController();

  Future<void> onTap(BuildContext context, String matchId,
      RefreshController refreshController) async {
    await Get.toNamed("/editMatch/" + matchId);
    await refreshController.requestRefresh();
  }

  //
  Widget getUpcomingWidgets(BuildContext context, bool future) {
    var matchesState = context.watch<MatchesState>();

    if (matchesState.getMatches() == null) {
      return null;
    }

    List<Match> matches = matchesState
        .getMatches()
        .where((e) => (future)
            ? e.dateTime.isAfter(DateTime.now())
            : e.dateTime.isBefore(DateTime.now()))
        .sortedBy((e) => e.dateTime)
        .toList();

    List<Widget> result = List<Widget>.from([]);

    matches.forEachIndexed((index, match) {
      if (index == 0) {
        result.add(
            GenericMatchInfo.first(match.documentId, onTap, refreshController));
      } else {
        result
            .add(GenericMatchInfo(match.documentId, onTap, refreshController));
      }
    });

    if (result.isEmpty)
      return getEmptyStateWidget(context);

    return Column(children: result);
  }

  Widget getEmptyStateWidget(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Container(
        child: Column(
          children: [
            Image.asset("assets/empty_state/illustration_01.png", height: 400),
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
        child: Scaffold(
            body: GenericAvailableMatchesList(
                Colors.green,
                ["UPCOMING", "PAST"].toList(),
                [
                  getUpcomingWidgets(context, true),
                  getUpcomingWidgets(context, false)
                ].toList(),
                getEmptyStateWidget(context),
                refreshController),
            floatingActionButton: FloatingActionButton(
                backgroundColor: Colors.green,
                child: Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  Get.toNamed("/addMatch");
                })));
  }
}
