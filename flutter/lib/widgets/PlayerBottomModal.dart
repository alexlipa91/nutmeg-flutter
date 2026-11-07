import 'dart:math' show min, pi, sin;

import 'package:badges/badges.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:flutter/material.dart' hide Badge;
import 'package:nutmeg/l10n/app_localizations.dart';
import 'package:nutmeg/utils/AllTimeRow.dart';
import 'package:nutmeg/widgets/FifaCard.dart';
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

/// Opens the popup of a player: a bottom sheet on a phone, a dialog on a wide
/// screen. Both are see-through, the popup draws its own panel.
Future<void> showPlayerPopup(BuildContext context, UserDetails user) {
  if (MediaQuery.of(context).size.width > 700) {
    return showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.all(24),
        child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 500),
            child: JoinedPlayerBottomModal(user)),
      ),
    );
  }
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) =>
        SafeArea(top: false, child: JoinedPlayerBottomModal(user)),
  );
}

/// What opens when you tap a player: their card, floating over the screen.
/// Tap it to turn it over: the back has the stats.
class JoinedPlayerBottomModal extends StatefulWidget {
  final UserDetails userDetails;

  JoinedPlayerBottomModal(this.userDetails);

  @override
  State<JoinedPlayerBottomModal> createState() =>
      _JoinedPlayerBottomModalState();
}

class _JoinedPlayerBottomModalState extends State<JoinedPlayerBottomModal>
    with TickerProviderStateMixin {
  static const _maxCardWidth = 280.0;

  late final AnimationController _flip =
      AnimationController(vsync: this, duration: Duration(milliseconds: 600));
  // a small wobble when the card shows up, to say it can be turned
  late final AnimationController _hint =
      AnimationController(vsync: this, duration: Duration(milliseconds: 1200));
  final GlobalKey _front = GlobalKey();
  bool _sharing = false;

  // from the player's matches, so asked for once the popup is open
  int? _score;
  int? _winPercent;

  @override
  void initState() {
    super.initState();
    _load();
    Future.delayed(Duration(milliseconds: 700), () {
      if (mounted && !MediaQuery.disableAnimationsOf(context)) {
        _hint.forward();
      }
    });
  }

  @override
  void dispose() {
    _flip.dispose();
    _hint.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    var row = await fetchAllTimeRow(widget.userDetails.documentId);
    if (mounted) {
      setState(() {
        _score = row.score;
        _winPercent = row.winPercent;
      });
    }
  }

  bool get _showsBack =>
      _flip.status == AnimationStatus.completed ||
      _flip.status == AnimationStatus.forward;

  void _turn() {
    _hint.value = 1;
    _showsBack ? _flip.reverse() : _flip.forward();
  }

  Future<void> _share(FifaCard front) async {
    final caption = front.caption(context);
    // the picture is of the front
    if (_showsBack) {
      await _flip.reverse();
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!mounted) return;
    setState(() => _sharing = true);
    await shareFifaCardPicture(context, _front, caption);
    if (mounted) setState(() => _sharing = false);
  }

  Widget _roundButton(IconData icon, VoidCallback? onPressed, {String? tip}) =>
      IconButton(
        onPressed: onPressed,
        tooltip: tip,
        style: IconButton.styleFrom(backgroundColor: Palette.white),
        icon: Icon(icon, size: 20, color: Palette.primary),
      );

  @override
  Widget build(BuildContext context) {
    final user = widget.userDetails;
    final width = min(_maxCardWidth, MediaQuery.of(context).size.width * 0.72);
    final height = width * 800 / 576;
    final theme = FifaTheme.forScore(_score);
    FifaCard card({Widget? back}) => FifaCard.player(
        user: user, score: _score, theme: theme, maxWidth: width, back: back);
    final front = card();
    final back = card(
        back: UserStatsCard.buildStatsContent(context, user,
            winPercent: _winPercent));
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          onTap: _turn,
          onHorizontalDragEnd: (_) => _turn(),
          child: SizedBox(
            width: width,
            height: height,
            child: AnimatedBuilder(
              animation: Listenable.merge([_flip, _hint]),
              builder: (context, _) {
                final wobble = _flip.value == 0
                    ? 0.35 * sin(2 * pi * _hint.value) * (1 - _hint.value)
                    : 0.0;
                final angle =
                    Curves.easeInOut.transform(_flip.value) * pi + wobble;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateY(angle),
                  child: angle > pi / 2
                      // the back is seen mirrored: turn it once more
                      ? Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(pi),
                          child: back)
                      : RepaintBoundary(key: _front, child: front),
                );
              },
            ),
          ),
        ),
        SizedBox(height: 12),
        Row(mainAxisSize: MainAxisSize.min, children: [
          _roundButton(Icons.flip, _turn),
          SizedBox(width: 12),
          _roundButton(Icons.ios_share, _sharing ? null : () => _share(front),
              tip: AppLocalizations.of(context)!.shareAction),
        ]),
      ]),
    );
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

    // Build a set of indices where the score date matches a POTM date
    final potmDates = userDetails.potmDates ?? {};
    final scoreDates = userDetails.lastScoreDates ?? [];
    final potmIndices = <int>{};
    for (var i = 0; i < scoreDates.length; i++) {
      if (potmDates.containsKey(scoreDates[i])) {
        potmIndices.add(i);
      }
    }

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
                getTouchedSpotIndicator: (barData, spotIndexes) {
                  return spotIndexes.map((i) {
                    return TouchedSpotIndicatorData(
                      FlLine(color: Colors.transparent),
                      FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          if (potmIndices.contains(i)) {
                            return _PotmDotPainter();
                          }
                          return FlDotCirclePainter(
                            radius: 5,
                            color: Colors.white,
                            strokeWidth: 3,
                            strokeColor: Palette.primary,
                          );
                        },
                      ),
                    );
                  }).toList();
                },
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
                    getDotPainter: (spot, percent, barData, index) {
                      if (potmIndices.contains(index)) {
                        return _PotmDotPainter();
                      }
                      return FlDotCirclePainter(
                        radius: 5,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: Palette.primary,
                      );
                    },
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

class _PotmDotPainter extends FlDotPainter {
  static const double _hexW = 22;
  static const double _hexH = 24;

  static final _iconPainter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(Icons.emoji_events.codePoint),
      style: TextStyle(
        fontSize: 12,
        fontFamily: Icons.emoji_events.fontFamily,
        package: Icons.emoji_events.fontPackage,
        color: Colors.white,
        shadows: [
          Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))
        ],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  static Path _buildHexagonPath(double w, double h) {
    final r = w * 0.08;
    final points = [
      Offset(w * 0.5, 0),
      Offset(w, h * 0.25),
      Offset(w, h * 0.75),
      Offset(w * 0.5, h),
      Offset(0, h * 0.75),
      Offset(0, h * 0.25),
    ];
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final prev = points[(i - 1 + points.length) % points.length];
      final curr = points[i];
      final next = points[(i + 1) % points.length];
      final inFromPrev = Offset(
        curr.dx + (prev.dx - curr.dx) * r / (curr - prev).distance,
        curr.dy + (prev.dy - curr.dy) * r / (curr - prev).distance,
      );
      final inToNext = Offset(
        curr.dx + (next.dx - curr.dx) * r / (curr - next).distance,
        curr.dy + (next.dy - curr.dy) * r / (curr - next).distance,
      );
      if (i == 0) {
        path.moveTo(inFromPrev.dx, inFromPrev.dy);
      } else {
        path.lineTo(inFromPrev.dx, inFromPrev.dy);
      }
      path.quadraticBezierTo(curr.dx, curr.dy, inToNext.dx, inToNext.dy);
    }
    path.close();
    return path;
  }

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    // Draw the hexagon centered on the data point (replaces the dot)
    final hexLeft = offsetInCanvas.dx - _hexW / 2;
    final hexTop = offsetInCanvas.dy - _hexH / 2;

    canvas.save();
    canvas.translate(hexLeft, hexTop);
    final hexPath = _buildHexagonPath(_hexW, _hexH);
    canvas.drawPath(hexPath, Paint()..color = Palette.accent);
    canvas.restore();

    // Draw the trophy icon centered inside the hexagon
    final iconOffset = Offset(
      hexLeft + (_hexW - _iconPainter.width) / 2,
      hexTop + (_hexH - _iconPainter.height) / 2,
    );
    _iconPainter.paint(canvas, iconOffset);
  }

  @override
  Size getSize(FlSpot spot) => const Size(_hexW, _hexH);

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) => this;

  @override
  Color get mainColor => Palette.accent;

  @override
  List<Object?> get props => [];
}
