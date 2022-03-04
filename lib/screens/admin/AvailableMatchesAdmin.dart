import "package:collection/collection.dart";
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:nutmeg/screens/admin/AddOrEditMatch.dart';
import 'package:nutmeg/widgets/Buttons.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../state/AvailableMatchesState.dart';
import '../../state/MatchesState.dart';
import '../../utils/UiUtils.dart';
import '../../widgets/GenericAvailableMatches.dart';
import 'AddOrEditMatch.dart';

// main widget
class AdminAvailableMatches extends StatelessWidget {
  static const routeName = "/adminAvailableMatches";

  final RefreshController refreshController = RefreshController();

  List<Widget> getButtons(BuildContext context) {
    var uiState = context.watch<AvailableMatchesAdminUiState>();

    return [
      uiState.getCurrentSelection() == MatchesAdminSelectionStatus.UPCOMING
          ? Expanded(
              child: LeftButtonOn("UPCOMING",
                  () => uiState.changeTo(MatchesAdminSelectionStatus.UPCOMING)))
          : Expanded(
              child: LeftButtonOff(
                  "UPCOMING",
                  () =>
                      uiState.changeTo(MatchesAdminSelectionStatus.UPCOMING))),
      uiState.getCurrentSelection() == MatchesAdminSelectionStatus.PAST
          ? Expanded(
              child: RightButtonOn("PAST",
                  () => uiState.changeTo(MatchesAdminSelectionStatus.PAST)))
          : Expanded(
              child: RightButtonOff("PAST",
                  () => uiState.changeTo(MatchesAdminSelectionStatus.PAST)))
    ];
  }

  Future<void> onTap(BuildContext context, String matchId,
      RefreshController refreshController) async {
    Get.toNamed("/editMatch/" + matchId);
    await refreshController.requestRefresh();
  }

  List<Widget> getGamesWidgets(
      BuildContext context, RefreshController refreshController) {
    List<Widget> result = [];
    result.add(SizedBox(height: 16));

    var status = context.watch<AvailableMatchesAdminUiState>().selected;

    var matchesState = context.watch<MatchesState>();

    var matches = (status == MatchesAdminSelectionStatus.UPCOMING)
        ? matchesState
            .getMatches()
            .where((e) => e.dateTime.isAfter(DateTime.now()))
            .sortedBy((e) => e.dateTime)
        : matchesState
            .getMatches()
            .where((e) => e.dateTime.isBefore(DateTime.now()));

    matches.forEachIndexed((index, match) {
      if (index == 0) {
        result.add(
            GenericMatchInfo.first(match.documentId, onTap, refreshController));
      } else {
        result
            .add(GenericMatchInfo(match.documentId, onTap, refreshController));
      }
    });

    return result;
  }

  static Widget getEmptyStateWidget(BuildContext context) {
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
              create: (context) => AvailableMatchesAdminUiState()),
        ],
        child: Scaffold(
            body: GenericAvailableMatchesList(
                RoundedTopBar(getButtons: getButtons, color: Colors.green),
                getGamesWidgets,
                getEmptyStateWidget,
                refreshController,
                Colors.green),
            floatingActionButton: FloatingActionButton(
                backgroundColor: Colors.green,
                child: Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  Get.toNamed("/addMatch");
                })));
  }
}
