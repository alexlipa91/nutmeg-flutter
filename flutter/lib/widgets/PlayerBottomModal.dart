import 'package:badges/badges.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:flutter/material.dart' hide Badge;
import 'package:nutmeg/screens/UserPage.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Skeletons.dart';

import '../model/UserDetails.dart';
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
                            SizedBox(height: 56),
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
                        top: -54,
                        left: 0,
                        right: 0,
                        child: CircleAvatar(
                            backgroundColor: Palette.white,
                            radius: 50,
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
          topImage: UserAvatar(46, userDetails)),
    );
  }
}

class StatEntry extends StatelessWidget {
  final String? stat;
  final String? description;
  final Widget? rightBadge;

  const StatEntry(
      {Key? key,
      required this.stat,
      required this.description,
      this.rightBadge})
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
            Expanded(
                child: (rightBadge != null)
                    ? Badge(
                        badgeStyle: BadgeStyle(
                          badgeColor: Colors.transparent,
                          borderSide: BorderSide.none,
                          shape: BadgeShape.circle,
                          // position: BadgePosition.custom(
                          //     bottom: -2, end: 0),
                          elevation: 0,
                        ),
                        badgeContent: rightBadge,
                        child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 30),
                            child: Text(description!,
                                style: TextPalette.bodyText)))
                    : Text(description!,
                        textAlign: TextAlign.center,
                        style: TextPalette.bodyText))
          ],
        )
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
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Column(children: [
            UserStatsCard.buildStatsContent(context, userDetails),
            SizedBox(height: 16),
          ]),
        ),
        UserDetails.getDisplayName(userDetails),
        userDetails.location?.getText());
  }
}

class PerformanceGraph extends StatelessWidget {
  final UserDetails userDetails;

  const PerformanceGraph({Key? key, required this.userDetails})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<MapEntry> ratesWithIndex = (userDetails.lastScores ?? [])
        .asMap()
        .entries
        .map((e) => MapEntry(e.key, double.parse(e.value.toStringAsFixed(2))))
        .toList();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(
          child: LineChart(
            LineChartData(
              borderData: FlBorderData(
                show: true,
                border: Border.symmetric(
                    horizontal: BorderSide(color: Palette.greyLightest)),
              ),
              titlesData: FlTitlesData(
                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 24,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Container(
                          child: Text(value.toStringAsFixed(0),
                              style: TextPalette.bodyText),
                        );
                      }),
                ),
              ),
              maxY: 5,
              minY: 1,
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (value) => Palette.greyLightest,
                  tooltipPadding: EdgeInsets.all(8),
                ),
                getTouchLineEnd: (a, b) => 0,
              ),
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Palette.greyLightest,
                    strokeWidth: 1,
                  );
                },
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: ratesWithIndex
                      .map((t) => FlSpot(t.key.toDouble(), t.value))
                      .toList(),
                  isCurved: false,
                  color: Palette.primary,
                  barWidth: 5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: 5,
                      color: Colors.white,
                      strokeWidth: 3,
                      strokeColor: Palette.primary,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: false,
                  ),
                ),
              ],
              // read about it in the LineChartData section
            ),
            // swapAnimationDuration: Duration(milliseconds: 150), // Optional
            // swapAnimationCurve: Curves.linear, // Optional
          ),
        )
      ]),
    );
  }
}
