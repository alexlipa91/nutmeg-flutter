import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../model/Leaderboard.dart';
import 'MatchDetails.dart';

class LeaderboardScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LeaderboardScreenState();
}

class LeaderboardScreenState extends State<LeaderboardScreen> {
  static var dateFormat = DateFormat("yyyyMM");
  static var dateFormatDesc = DateFormat("LLLL yyyy");
  static var now = DateTime.now();
  static var nowMinusOneMonth = DateTime(now.year, now.month - 1, now.day);

  var leaderboardNameToId = {
    "All time": "abs",
    dateFormatDesc.format(now): dateFormat.format(now),
    dateFormatDesc.format(nowMinusOneMonth):
        dateFormat.format(nowMinusOneMonth),
  };

  bool isLoading = false;
  Leaderboard? leaderboard;
  String selectedLeaderboard = "All time";
  List<String> sortableColumns = ["Score", "POTM", "Match", "Win %"];
  int sortColumnIndex = 0;
  bool sortAscending = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      isLoading = true;
    });
    var l = await CloudFunctionsClient()
        .get("leaderboard/${leaderboardNameToId[selectedLeaderboard]}");
    setState(() {
      this.leaderboard = null;
      if (l != null) {
        leaderboard = Leaderboard.fromJson(selectedLeaderboard, l);
        this.leaderboard!.entries.sort((a, b) {
          return LeaderboardEntry.compareBy(a, b, sortColumnIndex);
        });
      }
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Container(
              width: 800,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("Leaderboard", style: TextPalette.h1Default)
                      ]),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Palette.white,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: ButtonTheme(
                            alignedDropdown: true,
                            child: DropdownButton<String>(
                              isDense: true,
                              // isExpanded: true,
                              elevation: 1,
                              value: selectedLeaderboard,
                              onChanged: (v) {
                                print(v);
                                setState(() {
                                  if (v != selectedLeaderboard) {
                                    selectedLeaderboard = v!;
                                    load();
                                  }
                                });
                              },
                              items: leaderboardNameToId.entries
                                  .map((e) => DropdownMenuItem<String>(
                                      value: e.key, child: Text(e.key)))
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Palette.white,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: ButtonTheme(
                            alignedDropdown: true,
                            child: DropdownButton<int>(
                              isDense: true,
                              value: sortColumnIndex,
                              elevation: 1,
                              onChanged: (v) {
                                setState(() {
                                  if (v != null) {
                                    sortColumnIndex = v;
                                    load();
                                  }
                                });
                              },
                              items: [0, 1, 2, 3]
                                  .map((e) => DropdownMenuItem<int>(
                                      value: e,
                                      child: Text(sortableColumns[e])))
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  if (!isLoading && leaderboard != null)
                    Expanded(
                      child: InfoContainer(
                          padding: EdgeInsets.only(
                              left: 8, right: 16, top: 8, bottom: 0),
                          child: Column(
                            children: [
                              Flexible(
                                child: DataTable2(
                                    fixedTopRows: 1,
                                    bottomMargin: 8,
                                    sortColumnIndex: sortColumnIndex,
                                    sortAscending: sortAscending,
                                    dataRowHeight: 36,
                                    headingRowHeight: 36,
                                    columnSpacing: 4,
                                    smRatio: 0.55,
                                    dividerThickness: 0,
                                    horizontalMargin: 0,
                                    columns: [
                                      DataColumn2(
                                        fixedWidth: 20,
                                        label: Text('', style: TextPalette.h3),
                                      ),
                                      DataColumn2(
                                          label: Text('NAME',
                                              style: TextPalette.h3),
                                          size: ColumnSize.M),
                                      DataColumn2(
                                          size: ColumnSize.S,
                                          label: Text('SCORE',
                                              style: TextPalette.h3),
                                          tooltip: "Average score",
                                          numeric: true),
                                      DataColumn2(
                                          size: ColumnSize.S,
                                          label: Text('POTM',
                                              style: TextPalette.h3),
                                          numeric: true,
                                          tooltip:
                                              "Number of Player of the Match awards"),
                                      DataColumn2(
                                          size: ColumnSize.S,
                                          label: Text('MATCH',
                                              style: TextPalette.h3),
                                          numeric: true),
                                      DataColumn2(
                                          size: ColumnSize.S,
                                          label: Text('WIN %',
                                              style: TextPalette.h3),
                                          numeric: true,
                                          tooltip: "Percentage of games won"),
                                    ],
                                    rows: leaderboard!.entries
                                        .asMap()
                                        .entries
                                        .map((entry) => DataRow(cells: [
                                              DataCell(Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Text(
                                                  (entry.key + 1).toString(),
                                                  style:
                                                      TextPalette.getBodyText(
                                                          Palette.greyLight),
                                                ),
                                              )),
                                              DataCell(Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Row(
                                                    children: [
                                                      UserAvatar(
                                                          10.0,
                                                          leaderboard!.userData[
                                                              entry.value
                                                                  .userId]),
                                                      SizedBox(
                                                        width: 4,
                                                      ),
                                                      Expanded(
                                                        child: Align(
                                                          alignment: Alignment
                                                              .centerLeft,
                                                          child: UserNameWidget(
                                                              userDetails: leaderboard!
                                                                      .userData[
                                                                  entry.value
                                                                      .userId]),
                                                        ),
                                                      )
                                                    ],
                                                  ))),
                                              DataCell(Text(
                                                  entry.value.averageScore
                                                          ?.toStringAsFixed(
                                                              2) ??
                                                      "-",
                                                  style:
                                                      TextPalette.getBodyText(
                                                          Palette.black))),
                                              DataCell(Text(
                                                  entry.value.potmCount
                                                      .toString(),
                                                  style:
                                                      TextPalette.getBodyText(
                                                          Palette.black))),
                                              DataCell(Text(
                                                  entry.value.numMatchesJoined
                                                      .toString(),
                                                  style:
                                                      TextPalette.getBodyText(
                                                          Palette.black))),
                                              DataCell(Text(
                                                  entry.value
                                                          .getWinLossRatio()
                                                          ?.toStringAsFixed(
                                                              0) ??
                                                      "-",
                                                  style:
                                                      TextPalette.getBodyText(
                                                          Palette.black))),
                                            ]))
                                        .toList()),
                              ),
                            ],
                          )),
                    ),
                  if (isLoading)
                    Padding(
                      padding: EdgeInsets.only(top: 36),
                      child: Center(
                        child: Container(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Palette.primary))),
                      ),
                    ),
                  if (!isLoading && leaderboard == null)
                    Padding(
                      padding: EdgeInsets.only(top: 36),
                      child: Center(
                          child: Text(
                        AppLocalizations.of(context)!.searchLocationTitle,
                        style: TextPalette.bodyText,
                      )),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
