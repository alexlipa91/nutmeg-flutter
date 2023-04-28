import 'dart:math';

import 'package:badges/badges.dart';
import 'package:charts_flutter/flutter.dart' as charts;

import 'package:charts_flutter/flutter.dart';
import 'package:charts_flutter/src/text_element.dart' as ChartText;
import 'package:charts_flutter/src/text_style.dart' as ChartStyle;
import 'package:flutter/material.dart' hide Badge;
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Skeletons.dart';
import 'package:provider/provider.dart';

import '../model/UserDetails.dart';
import '../state/UserState.dart';
import 'Avatar.dart';

class BottomModalWithTopImage extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? content;
  final Widget? topImage;

  const BottomModalWithTopImage(
      {Key? key, this.title, this.subtitle, this.content, this.topImage})
      : super(key: key);

  Widget build(BuildContext context) {
    return Container(
      child: Container(
        decoration: new BoxDecoration(
            color: Palette.white,
            borderRadius: new BorderRadius.only(
                topLeft: const Radius.circular(20.0),
                topRight: const Radius.circular(20.0))),
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
                                ? Text(title!, style: TextPalette.h2)
                                : Skeletons.xlTextCenter,
                            if (subtitle != null)
                              Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(subtitle!,
                                      style: TextPalette.getBodyText(
                                          Palette.greyDark))),
                            SizedBox(height: 24),
                            content!
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
    );
  }
}

class PlayerBottomModal extends StatelessWidget {
  PlayerBottomModal(this.userDetails, this.content, this.title, this.subtitle);

  final UserDetails userDetails;
  final String? title;
  final String? subtitle;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 700,
      child: BottomModalWithTopImage(
          title: title,
          subtitle: subtitle,
          content: content,
          topImage: UserAvatar(34, userDetails)),
    );
  }
}

class StatEntry extends StatelessWidget {
  final String? stat;
  final String? description;
  final Widget? rightBadge;

  const StatEntry({Key? key, required this.stat, required this.description, this.rightBadge})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(stat!, style: TextPalette.getStats(Palette.black)),
        SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: (rightBadge != null) ? Badge(
                badgeColor: Colors.transparent,
                borderSide: BorderSide.none,
                shape: BadgeShape.circle,
                position: BadgePosition(end: 0, bottom: -2),
                elevation: 0,
                badgeContent: rightBadge,
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Text(description!,
                        style: TextPalette.bodyText))) :
            Text(description!, textAlign: TextAlign.center,
                style: TextPalette.bodyText))
        ],)
      ],
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
                flex: 2,
                child: StatEntry(
                  stat: userDetails.getNumJoinedMatches().toString(),
                  description: "Matches",
                ),
              ),
              Expanded(
                flex: 3,
                child: StatEntry(
                  stat: (userDetails.getScoreMatches() == null)
                      ? "-" : userDetails.getScoreMatches()!.toStringAsFixed(2),
                  description: "Avg. score",
                  // rightBadge: UserScoreBox.deltaBadge(userDetails),
                ),
              ),
              Expanded(
                flex: 2,
                child: StatEntry(
                  stat: userDetails.getNumManOfTheMatch().toString(),
                  description: "POTM",
                ),
              ),
            ],
          ),
          // if (userDetails.numWin != null)
          //   Padding(
          //     padding: EdgeInsets.only(top: 16),
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.spaceAround,
          //       children: [
          //         Expanded(
          //           flex: 2,
          //           child: StatEntry(
          //             stat: (userDetails.numWin ?? 0).toString(),
          //             description: "Won",
          //           ),
          //         ),
          //         Expanded(
          //           flex: 2,
          //           child: StatEntry(
          //             stat: (userDetails.numLoss ?? 0).toString(),
          //             description: "Loss",
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          if (userDetails.getLastScores().length > 0)
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

  const PerformanceGraph({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<MapEntry> ratesWithIndex = (context.read<UserState>()
        .getUserDetail(userId)!.lastScores ?? []).asMap().entries.toList();

    return new charts.LineChart(
              [
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
                  tickProviderSpec: new charts.StaticNumericTickProviderSpec([
                    1,
                    2,
                    3,
                    4,
                    5
                  ]
                      .map((e) => charts.TickSpec(e,
                          style: new charts.TextStyleSpec(
                              fontFamily: "Roboto",
                              fontSize: 16,
                              color: charts.ColorUtil.fromDartColor(
                                  Palette.greyDark))))
                      .toList()),
                  renderSpec: new charts.GridlineRendererSpec(
                      labelOffsetFromAxisPx: 20,
                      labelStyle: new charts.TextStyleSpec(
                          fontSize: 14, // size in Pts.
                          color: charts.MaterialPalette.black),
                      lineStyle: new charts.LineStyleSpec(
                          color: charts.ColorUtil.fromDartColor(
                              Palette.greyLighter)))),
              behaviors: [
                charts.LinePointHighlighter(
                  radiusPaddingPx: 3.0,
                  showVerticalFollowLine:
                      charts.LinePointHighlighterFollowLineType.nearest,
                  symbolRenderer: CustomCircleSymbolRenderer(),
                ),
              ],
              selectionModels: [
                charts.SelectionModelConfig(
                  updatedListener: (charts.SelectionModel model) {
                    if (model.hasDatumSelection) {
                      String rate = (model.selectedSeries.first
                                  .measureFn(model.selectedDatum.first.index) ??
                              0)
                          .toStringAsFixed(1);
                      ToolTipMgr.setData(rate);
                    }
                  },
                ),
              ],
              defaultRenderer: new charts.LineRendererConfig(
                includePoints: true,
                radiusPx: 6,
              ));
  }
}

class CustomCircleSymbolRenderer extends CircleSymbolRenderer {
  @override
  void paint(ChartCanvas canvas, Rectangle<num> bounds,
      {List<int>? dashPattern,
      Color? fillColor,
      FillPatternType? fillPattern,
      Color? strokeColor,
      double? strokeWidthPx}) {
    super.paint(canvas, bounds,
        dashPattern: dashPattern,
        fillColor: fillColor,
        strokeColor: strokeColor,
        strokeWidthPx: strokeWidthPx);
    canvas.drawRRect(
        Rectangle(bounds.left - 8, bounds.height - 32, bounds.width + 17,
            bounds.height + 5),
        fill: Color.fromOther(
            color: charts.ColorUtil.fromDartColor(Palette.primary)),
        roundBottomLeft: true,
        roundBottomRight: true,
        roundTopRight: true,
        roundTopLeft: true,
        radius: 30);

    ChartStyle.TextStyle textStyle = ChartStyle.TextStyle();

    textStyle.color = charts.ColorUtil.fromDartColor(Palette.white);
    textStyle.fontSize = 14;
    textStyle.fontFamily = "Roboto";
    textStyle.fontWeight = "w700";

    canvas.drawText(
        ChartText.TextElement('${ToolTipMgr.data()}', style: textStyle),
        (bounds.left).round(),
        (bounds.height - 27).round());
  }
}

String? _data;

class ToolTipMgr {
  static String data() => _data!;

  static setData(String data) {
    _data = data;
  }
}
