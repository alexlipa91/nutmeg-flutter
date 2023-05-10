import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/PageTemplate.dart';
import 'package:provider/provider.dart';

import '../model/Leaderboard.dart';

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
    dateFormatDesc.format(nowMinusOneMonth): dateFormat.format(nowMinusOneMonth)
  };

  Leaderboard? leaderboard;
  String selectedLeaderboard = "All time";
  int sortColumnIndex = 1;
  bool sortAscending = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    var l = await CloudFunctionsClient()
        .get("leaderboard/${leaderboardNameToId[selectedLeaderboard]}");
    setState(() {
      leaderboard = Leaderboard.fromJson(selectedLeaderboard, l!);
      this.leaderboard!.entries.sort((a, b) {
        return (b.averageScore ?? 0).compareTo((a.averageScore ?? 0));
      });
    });
    leaderboard!.entries.forEach((e) {
      context.read<UserState>().getOrFetch(e.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageTemplate(widgets: [
      Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [Text("Leaderboard", style: TextPalette.h1Default)]),
      SizedBox(height: 16),
      DecoratedBox(
        decoration: BoxDecoration(
          color: Palette.white,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedLeaderboard,
            onChanged: (v) {
              print(v);
              setState(() {
                if (v != selectedLeaderboard) {
                  selectedLeaderboard = v!;
                  leaderboard = null;
                  load();
                }
              });
            },
            items: leaderboardNameToId.entries
                .map((e) =>
                    DropdownMenuItem<String>(value: e.key, child: Text(e.key)))
                .toList(),
          ),
        ),
      ),
      SizedBox(height: 16),
      if (leaderboard != null)
        InfoContainer(
            child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
              sortColumnIndex: sortColumnIndex,
              sortAscending: sortAscending,
              dataRowHeight: 36,
              columnSpacing: 2,
              columns: [
                DataColumn(label: Text('  ', style: TextPalette.h3)),
                DataColumn(label: Text('Name', style: TextPalette.h3)),
                DataColumn(
                    label: Text('Avg. score', style: TextPalette.h3),
                    tooltip: "Average score",
                    onSort: (colIndex, a) {
                      setState(() {
                        this.leaderboard!.entries.sort((a, b) {
                          var c = (a.averageScore ?? 0)
                              .compareTo((b.averageScore ?? 0));
                          return sortAscending ? -c : c;
                        });
                        sortAscending = !sortAscending;
                        sortColumnIndex = 2;
                      });
                    }),
                DataColumn(
                    label: Text('POTM', style: TextPalette.h3),
                    onSort: (colIndex, a) {
                      setState(() {
                        this.leaderboard!.entries.sort((a, b) {
                          var c = a.potmCount.compareTo(b.potmCount);
                          return sortAscending ? -c : c;
                        });
                        sortAscending = !sortAscending;
                        sortColumnIndex = 3;
                      });
                    },
                    tooltip: "Number of Player of the Match awards"),
                DataColumn(
                  label: Text('Matches', style: TextPalette.h3),
                  onSort: (colIndex, _) {
                    setState(() {
                      this.leaderboard!.entries.sort((a, b) {
                        var c =
                            a.numMatchesJoined.compareTo(b.numMatchesJoined);
                        return sortAscending ? -c : c;
                      });
                      sortAscending = !sortAscending;
                      sortColumnIndex = 4;
                    });
                  },
                ),
                DataColumn(
                    label: Text('Win %', style: TextPalette.h3),
                    onSort: (colIndex, a) {
                      setState(() {
                        this.leaderboard!.entries.sort((a, b) {
                          var c = (a.getWinLossRatio() ?? -1)
                              .compareTo((b.getWinLossRatio() ?? -1));
                          return sortAscending ? -c : c;
                        });
                        sortAscending = !sortAscending;
                        sortColumnIndex = 5;
                      });
                    },
                    tooltip: "Percentage of games won"),
              ],
              rows: leaderboard!.entries
                  .asMap()
                  .entries
                  .map((entry) => DataRow(cells: [
                        DataCell(SizedBox(
                          width: 30,
                          child: Text(
                            (entry.key + 1).toString(),
                            style: TextPalette.getBodyText(Palette.greyLight),
                          ),
                        )),
                        DataCell(SizedBox(
                          width: 100,
                          child: Text(
                              context
                                      .watch<UserState>()
                                      .getUserDetail(entry.value.userId)
                                      ?.name
                                      ?.split(" ")
                                      .first ??
                                  "",
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              style: TextPalette.bodyText),
                        )),
                        DataCell(Text(
                            entry.value.averageScore?.toStringAsFixed(2) ?? "-",
                            style: TextPalette.bodyText)),
                        DataCell(Text(entry.value.potmCount.toString(),
                            style: TextPalette.bodyText)),
                        DataCell(Text(entry.value.numMatchesJoined.toString(),
                            style: TextPalette.bodyText)),
                        DataCell(Text(
                            entry.value.getWinLossRatio()?.toStringAsFixed(2) ??
                                "-",
                            style: TextPalette.bodyText)),
                      ]))
                  .toList()),
        )),
      if (leaderboard == null)
        Center(
          child: Container(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Palette.primary))),
        )
    ]);
  }
}
