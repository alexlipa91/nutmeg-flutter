import "package:collection/collection.dart";
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/state/AvailableMatchesState.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../state/MatchesState.dart';
import '../../utils/UiUtils.dart';
import '../../widgets/GenericAvailableMatches.dart';
import '../../widgets/Section.dart';

// main widget
class AdminAvailableMatches extends StatelessWidget {
  final RefreshController refreshController = RefreshController();

  Future<void> onTap(BuildContext context, String matchId,
      RefreshController refreshController) async {
    await Get.toNamed("/editMatch/" + matchId);
    await refreshController.requestRefresh();
  }

  //
  Widget getMatchWidgets(BuildContext context, bool future) {
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

    if (!future)
      matches = matches.reversed.toList();

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

    if (result.isEmpty) return getEmptyStateWidget(context);

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

  Widget getExtraWidgets(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Section(
          title: "DEMO PAGES",
          body: Column(
            children: [
              GenericButtonWithLoader("Player of the Match", (ctx) {
                Get.toNamed("/potm");
              }, Primary()),
              GenericButtonWithLoader("After Login details", (ctx) async {
                var n = await Get.toNamed("/login/enterDetails");
                GenericInfoModal(
                        title: "Flow ended",
                        description:
                            "Page returned the following data: " + n.toString())
                    .show(context);
              }, Primary())
            ],
          ),
          topSpace: 16,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AvailableMatchesUiState()),
      ],
      child: Scaffold(
          body: GenericAvailableMatchesList(
            Colors.green,
            ["UPCOMING MATCHES", "PAST MATCHES", "OTHER"].toList(),
            [
              getMatchWidgets(context, true),
              getMatchWidgets(context, false),
              getExtraWidgets(context)
            ].toList(),
            getEmptyStateWidget(context),
            refreshController,
            null,
            Column(
              children: [
                Text("Admin Tools", style: TextPalette.h1Inverted),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
              backgroundColor: Colors.green,
              child: Icon(Icons.add, color: Colors.white),
              onPressed: () {
                Get.toNamed("/addMatch");
              })),
    );
  }
}
