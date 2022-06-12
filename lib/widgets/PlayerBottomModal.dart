import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Skeletons.dart';
import 'package:skeletons/skeletons.dart';

import '../model/UserDetails.dart';
import 'Avatar.dart';

class BottomModalWithTopImage extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget content;
  final Widget topImage;

  const BottomModalWithTopImage(
      {Key key, this.title, this.subtitle, this.content, this.topImage})
      : super(key: key);

  Widget build(BuildContext context) {
    return Container(
      child: Container(
        decoration: new BoxDecoration(
            color: Palette.white,
            borderRadius: new BorderRadius.only(
                topLeft: const Radius.circular(20.0),
                topRight: const Radius.circular(20.0))),
        child: Padding(
          padding: GenericInfoModal.padding,
          child: Container(
            child: Wrap(
              children: [
                Stack(
                    alignment: AlignmentDirectional.bottomStart,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                          decoration: BoxDecoration(
                              color: Palette.white,
                              borderRadius: GenericInfoModal.modalRadius),
                          width: double.infinity,
                          child: Column(
                            children: [
                              SizedBox(height: 44),
                              (title != null)
                                  ? Text(title, style: TextPalette.h2)
                                  : Skeletons.xlTextCenter,
                              if (subtitle != null)
                                Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text(subtitle,
                                        style: TextPalette.getBodyText(
                                            Palette.grey_dark))),
                              SizedBox(height: 24),
                              content
                            ],
                          )),
                      Positioned(
                          top: -50,
                          left: 0,
                          right: 0,
                          child: CircleAvatar(
                              backgroundColor: Palette.white,
                              radius: 38,
                              child: topImage)),
                    ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlayerBottomModal extends StatelessWidget {
  PlayerBottomModal(this.userDetails, this.content, this.title, this.subtitle);

  final UserDetails userDetails;
  final String title;
  final String subtitle;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return BottomModalWithTopImage(
        title: title,
        subtitle: subtitle,
        content: content,
        topImage: UserAvatar(34, userDetails));
  }
}

class StatEntry extends StatelessWidget {
  final String stat;
  final String description;

  const StatEntry({Key key, this.stat, this.description}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Text(stat, style: TextPalette.getStats(Palette.black)),
          SizedBox(height: 4),
          Text(description, style: TextPalette.bodyText)
        ],
      ),
    );
  }
}

class JoinedPlayerBottomModal extends StatelessWidget {
  final UserDetails userDetails;

  JoinedPlayerBottomModal(this.userDetails);

  @override
  Widget build(BuildContext context) {
    return PlayerBottomModal(
        userDetails,
        Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: StatEntry(
                  stat: userDetails.getNumJoinedMatches().toString(),
                  description: "Matches",
                ),
              ),
              Expanded(
                child: StatEntry(
                  stat: (userDetails.getScoreMatches() == null)
                      ? "-"
                      : userDetails.getScoreMatches().toStringAsFixed(1),
                  description: "Avg. score",
                ),
              ),
              Expanded(
                child: StatEntry(
                  stat: userDetails.getNumManOfTheMatch().toString(),
                  description: "POTM",
                ),
              ),
            ],
          ),
          if (userDetails.numJoinedMatches > 0)
            Padding(
                padding: EdgeInsets.only(top: 24.0, left: 8, right: 8),
                child: SizedBox(
                    height: 150,
                    child: PerformanceGraph(userId: userDetails.documentId)))
        ]),
        UserDetails.getDisplayName(userDetails),
        null);
  }
}

class PerformanceGraph extends StatelessWidget {
  final String userId;

  const PerformanceGraph({Key key, this.userId}) : super(key: key);

  Future<List<double>> _getScores(String userId) async {
    var scores = await CloudFunctionsClient()
        .callFunction("get_last_user_scores", {"id": userId});

    List<double> scoresList = [];

    List<Object> o = scores["scores"];
    o.forEach((e) {
      scoresList.add(e);
    });

    return scoresList;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _getScores(userId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<MapEntry> ratesWithIndex =
            snapshot.data
                .asMap()
                .entries
                .toList();

            return new charts.LineChart([
              new charts.Series<MapEntry, int>(
                id: 'Rates',
                colorFn: (_, __) =>
                    charts.ColorUtil.fromDartColor(Palette.primary),
                domainFn: (MapEntry e, _) => e.key,
                measureFn: (MapEntry e, _) => e.value,
                strokeWidthPxFn: (MapEntry e, _) => 5,
                data: ratesWithIndex,

                fillColorFn: (_, __) =>
                    charts.ColorUtil.fromDartColor(Palette.white),
              )
            ],
                animate: false,
                domainAxis: new charts.NumericAxisSpec(
                    renderSpec: new charts.NoneRenderSpec()),
                primaryMeasureAxis: new charts.NumericAxisSpec(
                    tickProviderSpec: new charts.StaticNumericTickProviderSpec(
                        [1, 2, 3, 4, 5].map((e) =>
                            charts.TickSpec(e,
                                style: new charts.TextStyleSpec(
                                    fontFamily: "Roboto",
                                    fontSize: 16,
                                    color: charts.ColorUtil.fromDartColor(
                                        Palette.grey_dark)))).toList()
                    ),
                    renderSpec: new charts.GridlineRendererSpec(
                        labelOffsetFromAxisPx: 20,
                        labelStyle: new charts.TextStyleSpec(
                            fontSize: 14, // size in Pts.
                            color: charts.MaterialPalette.black),
                        lineStyle: new charts.LineStyleSpec(
                            color: charts.ColorUtil.fromDartColor(
                                Palette.grey_lighter)))),
                defaultRenderer:
                new charts.LineRendererConfig(
                  includePoints: true,
                  radiusPx: 6,
                ));
          }
          return SkeletonAvatar(
              style: SkeletonAvatarStyle(
                  width: double.infinity,
                  height: 190,
                  borderRadius: BorderRadius.circular(10.0)));
        });
  }
}

class PointsLineChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  PointsLineChart(this.seriesList, {this.animate});

  /// Creates a [LineChart] with sample data and no transition.
  factory PointsLineChart.withSampleData() {
    return new PointsLineChart(
      _createSampleData(),
      // Disable animations for image tests.
      animate: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return new charts.LineChart(seriesList,
        animate: animate,
        defaultRenderer: new charts.LineRendererConfig(includePoints: true));
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<LinearSales, int>> _createSampleData() {
    final data = [
      new LinearSales(0, 5),
      new LinearSales(1, 25),
      new LinearSales(2, 100),
      new LinearSales(3, 75),
    ];

    return [
      new charts.Series<LinearSales, int>(
        id: 'Sales',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (LinearSales sales, _) => sales.year,
        measureFn: (LinearSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }
}

/// Sample linear data type.
class LinearSales {
  final int year;
  final int sales;

  LinearSales(this.year, this.sales);
}
