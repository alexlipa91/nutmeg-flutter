import 'dart:math';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:charts_flutter/src/text_style.dart' as style;
import 'package:charts_flutter/src/text_element.dart';
import 'dart:math';

import 'package:charts_flutter/flutter.dart';
import 'package:charts_flutter/src/text_element.dart' as ChartText;
import 'package:charts_flutter/src/text_style.dart' as ChartStyle;
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Skeletons.dart';
import 'package:provider/provider.dart';
import 'package:skeletons/skeletons.dart';

import '../model/UserDetails.dart';
import '../state/UserState.dart';
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

class PerformanceGraph extends StatefulWidget {
  final String userId;

  const PerformanceGraph({Key key, this.userId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => PerformanceGraphState();
}

class PerformanceGraphState extends State<PerformanceGraph> {
  @override
  void initState() {
    super.initState();
    loadState();
  }

  Future<void> loadState() =>
      context.read<UserState>().fetchScores(widget.userId);

  @override
  Widget build(BuildContext context) {
    var scores = context.watch<UserState>().getUserScores(widget.userId);

    if (scores == null)
      return SkeletonAvatar(
          style: SkeletonAvatarStyle(
              width: double.infinity,
              height: 190,
              borderRadius: BorderRadius.circular(10.0)));

    List<MapEntry> ratesWithIndex = scores.asMap().entries.toList();

    return new charts.LineChart([
      new charts.Series<MapEntry, int>(
        id: 'Rates',
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(Palette.primary),
        domainFn: (MapEntry e, _) => e.key,
        measureFn: (MapEntry e, _) => e.value,
        strokeWidthPxFn: (MapEntry e, _) => 5,
        data: ratesWithIndex,
        fillColorFn: (_, __) => charts.ColorUtil.fromDartColor(Palette.white),
      )
    ],
        animate: false,
        domainAxis:
            new charts.NumericAxisSpec(renderSpec: new charts.NoneRenderSpec()),
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
                        color:
                            charts.ColorUtil.fromDartColor(Palette.grey_dark))))
                .toList()),
            renderSpec: new charts.GridlineRendererSpec(
                labelOffsetFromAxisPx: 20,
                labelStyle: new charts.TextStyleSpec(
                    fontSize: 14, // size in Pts.
                    color: charts.MaterialPalette.black),
                lineStyle: new charts.LineStyleSpec(
                    color:
                        charts.ColorUtil.fromDartColor(Palette.grey_lighter)))),
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
                String rate = model.selectedSeries.first
                    .measureFn(model.selectedDatum.first.index)
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
      {List<int> dashPattern,
        Color fillColor,
        FillPatternType fillPattern,
        Color strokeColor,
        double strokeWidthPx}) {
    super.paint(canvas, bounds,
        dashPattern: dashPattern,
        fillColor: fillColor,
        strokeColor: strokeColor,
        strokeWidthPx: strokeWidthPx);
    canvas.drawRRect(
      Rectangle(bounds.left - 8, bounds.height - 32,
          bounds.width + 17, bounds.height + 5),
      fill: Color.fromOther(color: charts.ColorUtil.fromDartColor(Palette.primary)),
      roundBottomLeft: true,
      roundBottomRight: true,
      roundTopRight: true,
      roundTopLeft: true,
      radius: 30
    );

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

String _data;

class ToolTipMgr {

  static String data() => _data;

  static setData(String data) {
    _data = data;
  }
}