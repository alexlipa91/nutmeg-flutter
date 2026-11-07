import 'dart:math' show pi, sin;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutmeg/l10n/app_localizations.dart';
import 'package:nutmeg/model/UserDetails.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/share_utils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:share_plus/share_plus.dart';

// The FIFA-style player card: used for the best players of the month in the
// leaderboard and for the profile.

final _logger = CrashlyticsLogger("FifaCard");

class FifaCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final w = s.width, h = s.height;
    return Path()
      ..moveTo(w * 0.10, h * 0.02)
      ..quadraticBezierTo(w * 0.5, 0, w * 0.90, h * 0.02)
      ..quadraticBezierTo(w * 0.90, h * 0.07, w, h * 0.09)
      ..lineTo(w, h * 0.86)
      ..cubicTo(w, h * 0.93, w * 0.65, h * 0.95, w * 0.5, h)
      ..cubicTo(w * 0.35, h * 0.95, 0, h * 0.93, 0, h * 0.86)
      ..lineTo(0, h * 0.09)
      ..quadraticBezierTo(w * 0.10, h * 0.07, w * 0.10, h * 0.02)
      ..close();
  }

  @override
  bool shouldReclip(_) => false;
}

class FifaStripesPainter extends CustomPainter {
  final Color color;

  const FifaStripesPainter([this.color = Colors.white54]);

  @override
  void paint(Canvas canvas, Size s) {
    final area = Rect.fromLTWH(0, 0, s.width, s.height * 0.65);
    final paint = Paint()
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, Colors.transparent],
      ).createShader(area);
    final step = s.width * 0.014;
    for (double x = -area.height; x < s.width; x += step) {
      canvas.drawLine(
        Offset(x, area.height),
        Offset(x + area.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Moving effects for the best player's card: a light sweeping across it now
/// and then and a pulsing glow behind the picture.
class FifaGoldEffects extends StatefulWidget {
  // the pulsing glow behind the picture; without it only the sweep is left
  final bool glow;

  const FifaGoldEffects({this.glow = true});

  @override
  State<FifaGoldEffects> createState() => _FifaGoldEffectsState();
}

class _FifaGoldEffectsState extends State<FifaGoldEffects>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(seconds: 5),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // keep still for people who asked for less motion
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: _FifaGoldEffectsPainter(_controller, glow: widget.glow));
}

class _FifaGoldEffectsPainter extends CustomPainter {
  final Animation<double> t;
  final bool glow;

  _FifaGoldEffectsPainter(this.t, {required this.glow}) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height, v = t.value;

    // glow behind the picture, pulsing twice per cycle
    final pulse = 0.5 + 0.5 * sin(2 * pi * v * 2);
    final center = Offset(w * 0.57, h * 0.38);
    if (glow)
      canvas.drawCircle(
        center,
        w * 0.36,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.transparent,
              Color.fromRGBO(255, 244, 200, 0.3 + 0.35 * pulse),
              Colors.transparent,
            ],
            stops: [0.45, 0.62, 1],
          ).createShader(Rect.fromCircle(center: center, radius: w * 0.36)),
      );

    // a band of light sweeping across during the first part of the cycle
    final e = (v / 0.4).clamp(0.0, 1.0);
    if (e < 1) {
      final p = -0.3 + 1.6 * Curves.easeInOut.transform(e);
      canvas.drawRect(
        Offset.zero & s,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment(-1, -0.7),
            end: Alignment(1, 0.7),
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: 0.6),
              Colors.transparent,
            ],
            stops: [
              (p - 0.14).clamp(0.0, 1.0),
              p.clamp(0.0, 1.0),
              (p + 0.14).clamp(0.0, 1.0),
            ],
          ).createShader(Offset.zero & s),
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Colours and background effect of a card.
class FifaTheme {
  final List<Color> gradient;
  final List<double> stops;
  final Color ink;
  final Color ring;
  final bool electric;
  // stripes and the light band across the card
  final Color stripe;
  final double sheen;
  // Oxanium type, metallic numbers, a shimmering gold rim and carbon lines
  final bool holo;
  // Oxanium type in place of Oswald and Bebas
  final bool oxanium;
  // a picture for the whole card, in place of the gradient and its effects
  final String? background;
  // with a picture: the gradient of the big numbers, the small labels, the
  // outline behind the text, the colours of the picture's ring
  final List<Color> metal;
  final Color accent;
  final Color outline;
  final List<Color>? ringColors;
  // the change since last month, as a chip under the score
  final bool showChange;
  // size of the title and the month, for art with a narrower frame
  final double headerScale;
  // size of the numbers on the bottom row
  final double statsScale;

  const FifaTheme({
    required this.gradient,
    required this.stops,
    required this.ink,
    required this.ring,
    this.electric = false,
    this.stripe = Colors.white54,
    this.sheen = 0.5,
    this.holo = false,
    this.oxanium = false,
    this.background,
    this.metal = const [
      Color(0xFFF0D78A),
      Color(0xFFD4AC45),
      Color(0xFFA67C24)
    ],
    this.accent = const Color(0xFFB8975A),
    this.outline = Colors.black,
    this.ringColors,
    this.showChange = true,
    this.headerScale = 1,
    this.statsScale = 1,
  });

  /// Black and gold, for the player of the month.
  static const blackGold = FifaTheme(
    gradient: [
      Color(0xFF3A3A3A),
      Color(0xFF111111),
      Color(0xFF2A2A2A),
      Color(0xFF050505),
    ],
    stops: [0, 0.4, 0.7, 1],
    ink: Color(0xFFE8C766),
    ring: Color(0xFFD9B04A),
    stripe: Color(0x66D9B04A),
    sheen: 0.12,
    holo: true,
    oxanium: true,
    background: 'assets/potm_card_bg.png',
    showChange: false,
  );

  static const gold = FifaTheme(
    gradient: [
      Color(0xFFF6DE8D),
      Color(0xFFD9B04A),
      Color(0xFFF2D77A),
      Color(0xFFC9A03C),
    ],
    stops: [0, 0.4, 0.7, 1],
    ink: Color(0xFF3B2A06),
    ring: Color(0xFF9A7620),
    background: 'assets/gold_card_bg.png',
    oxanium: true,
    statsScale: 1.25,
  );

  static const silver = FifaTheme(
    gradient: [
      Color(0xFFF2F4F7),
      Color(0xFFB9C0CA),
      Color(0xFFE6E9EE),
      Color(0xFF9AA3AF),
    ],
    stops: [0, 0.4, 0.7, 1],
    ink: Color(0xFF2B3036),
    ring: Color(0xFF7B8490),
    background: 'assets/silver_card_bg.png',
    oxanium: true,
    statsScale: 1.25,
  );

  /// Gold above 80, silver above 70, bronze below; silver while the score is
  /// not known.
  static FifaTheme forScore(num? score) => score == null
      ? silver
      : score > 80
          ? gold
          : score > 70
              ? silver
              : bronze;

  static const bronze = FifaTheme(
    gradient: [
      Color(0xFFE8B48A),
      Color(0xFFB87333),
      Color(0xFFD9956B),
      Color(0xFF8A4F22),
    ],
    stops: [0, 0.4, 0.7, 1],
    ink: Color(0xFF2E1706),
    ring: Color(0xFF6E3B14),
    background: 'assets/bronze_card_bg.png',
    oxanium: true,
    statsScale: 1.25,
  );

  static const blue = FifaTheme(
    gradient: [
      Color(0xFF1747FF),
      Color(0xFF0096FF),
      Color(0xFF2230E0),
      Color(0xFF0A1A8C),
    ],
    stops: [0, 0.35, 0.7, 1],
    ink: Colors.white,
    ring: Color(0xFF9FE9FF),
    electric: true,
    holo: true,
    oxanium: true,
    background: 'assets/fire_card_bg.png',
    metal: [Color(0xFFFFFFFF), Color(0xFFBFE3FF), Color(0xFF8FA6FF)],
    accent: Color(0xFF9DB4E8),
    outline: Color(0xFF070B33),
    headerScale: 0.65,
    statsScale: 0.85,
    ringColors: [
      Color(0xFF3FE0FF),
      Color(0xFF7B5CFF),
      Color(0xFFFF4FD8),
      Color(0xFF3FE0FF),
    ],
  );
}

/// Glow behind the picture and a couple of lightning bolts, for the blue card.
class _ElectricPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = RadialGradient(
          colors: [Color(0xAA7FE8FF), Color(0x007FE8FF)],
        ).createShader(
          Rect.fromCircle(center: Offset(w * 0.62, h * 0.34), radius: w * 0.6),
        ),
    );
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Color(0x557FE8FF)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);
    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Color(0xCCFFFFFF);
    for (final pts in [
      [
        [0.06, 0.0],
        [0.14, 0.08],
        [0.07, 0.15],
        [0.15, 0.25],
        [0.09, 0.32],
        [0.16, 0.44],
      ],
      [
        [0.95, 0.06],
        [0.88, 0.16],
        [0.95, 0.24],
        [0.89, 0.36],
        [0.94, 0.46],
      ],
    ]) {
      final path = Path()..moveTo(pts[0][0] * w, pts[0][1] * h);
      for (final q in pts.skip(1)) {
        path.lineTo(q[0] * w, q[1] * h);
      }
      canvas.drawPath(path, glow);
      canvas.drawPath(path, core);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Faint carbon-fibre lines: diagonals in both directions.
class _CarbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final step = s.width * 0.025;
    final a = Paint()
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.05);
    final b = Paint()
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.025);
    for (double x = -s.height; x < s.width; x += step) {
      canvas.drawLine(Offset(x, s.height), Offset(x + s.height, 0), a);
      canvas.drawLine(Offset(x, 0), Offset(x + s.height, s.height), b);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

const _holoColors = [
  Color(0xFFF6DE8D),
  Color(0xFFB8892B),
  Color(0xFFFFF1B8),
  Color(0xFFD9B04A),
  Color(0xFF8A6A1F),
  Color(0xFFF6DE8D),
];

/// Thin shimmering gold rim around the card edge.
class _HoloRimPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    // the clip hides the outer half of the stroke
    canvas.drawPath(
      FifaCardClipper().getClip(s),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..shader = SweepGradient(
          colors: _holoColors,
          transform: GradientRotation(pi / 4),
        ).createShader(Offset.zero & s),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Thin darker outline inside the card edge, like the border of a real card.
class _InsetBorderPainter extends CustomPainter {
  final Color color;

  _InsetBorderPainter(this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final m = Matrix4.identity()
      ..translate(s.width / 2, s.height / 2)
      ..scale(0.94, 0.95)
      ..translate(-s.width / 2, -s.height / 2);
    canvas.drawPath(
      FifaCardClipper().getClip(s).transform(m.storage),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = color.withValues(alpha: 0.33),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

/// A player's card for a period: `entry` is the player's row of the ranking.
/// `title` marks a special card (POTM, ...); without one it is a plain card.
/// One number on a card: a label and its value.
class FifaStat {
  final String label;
  final String value;

  const FifaStat(this.label, this.value);
}

/// How the stats of a card are laid out.
enum FifaStatsLayout {
  /// Labels over numbers in one row, like MATCHES / WINS / AVG SCORE.
  columns,

  /// Number and label side by side, three to a line, like FIFA's attributes.
  grid,
}

/// A player's card. `score` is the big OVR number; `title` marks a special card
/// (POTM, ...) and `subtitle` is a small line such as the period.
class FifaCard extends StatelessWidget {
  final UserDetails? user;
  final int? score;
  final List<FifaStat> stats;
  final FifaStatsLayout layout;
  // change since last month, as a chip under the score
  final num? change;
  // a small extra under the score, like "GK 80"
  final String? extra;
  final String? subtitle;
  final FifaTheme theme;
  final String? title;
  final double maxWidth;
  // the card is about the change since last month: show it big
  final bool emphasizeChange;
  // moving effects and a golden halo, for the best player's card
  final bool effects;
  // the picture can be tapped (to change it)
  final VoidCallback? onPictureTap;
  // the back of the card: what it shows in place of the front's content
  final Widget? back;

  const FifaCard({
    Key? key,
    required this.user,
    required this.score,
    required this.stats,
    this.layout = FifaStatsLayout.columns,
    this.change,
    this.extra,
    this.subtitle,
    required this.theme,
    this.title,
    this.maxWidth = 200,
    this.emphasizeChange = false,
    this.effects = false,
    this.onPictureTap,
    this.back,
  }) : super(key: key);

  Color get _ink => theme.ink;

  /// Light edge on dark text, dark edge on light text.
  Color get _edge => _ink.computeLuminance() > 0.5
      ? Colors.black.withValues(alpha: 0.35)
      : Colors.white.withValues(alpha: 0.55);

  /// Oxanium on the light cards (gold, silver, bronze) goes one weight up, so
  /// it holds against the stripes of the picture.
  FontWeight _weight(FontWeight w) => theme.oxanium && !theme.holo
      ? FontWeight.values[(w.index + 1).clamp(0, 8)]
      : w;

  TextStyle _text(
    double size,
    FontWeight weight, {
    double? spacing,
    double height = 1,
    Color? color,
  }) =>
      (theme.oxanium ? GoogleFonts.oxanium : GoogleFonts.oswald)(
        color: color ?? _ink,
        fontSize: size,
        fontWeight: _weight(weight),
        letterSpacing: spacing,
        height: height,
        shadows: [Shadow(color: _edge, offset: Offset(0, 0.8))],
      );

  /// Gold gradient with a soft glow on the holographic card, plain otherwise.
  Widget _metal(String text, TextStyle style, {TextAlign? align}) {
    if (!theme.holo) {
      return Text(text,
          style: style,
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis);
    }
    final art = theme.background != null;
    final gold = ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (r) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: theme.metal,
      ).createShader(r),
      child: Text(
        text,
        textAlign: align,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style.copyWith(
          color: Colors.white,
          // the picture has its own glow; the text only needs an outline
          shadows: art ? [] : [Shadow(color: Color(0xAAE8C766), blurRadius: 8)],
        ),
      ),
    );
    if (!art) return gold;
    // a dark outline under the letters, so they stand out from the picture
    final size = style.fontSize ?? 16;
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: style.fontFamily,
            fontSize: size,
            fontWeight: style.fontWeight,
            letterSpacing: style.letterSpacing,
            height: style.height,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size * 0.09
              ..strokeJoin = StrokeJoin.round
              ..color = theme.outline.withValues(alpha: 0.9),
          ),
        ),
        gold,
      ],
    );
  }

  /// Label on top, number below, sharing the row equally.
  Widget _statColumn(String label, String value, double w) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: _text(
                  theme.oxanium ? w * 0.038 * theme.statsScale : w * 0.046,
                  FontWeight.w500,
                  height: 1.2,
                  color: theme.holo ? theme.accent : null),
            ),
          ),
          Text(value,
              style: _text(
                  theme.oxanium ? w * 0.075 * theme.statsScale : w * 0.09,
                  FontWeight.w700,
                  height: 1.1)),
        ],
      ),
    );
  }

  Widget _statSeparator(double w) =>
      Container(width: 1, height: w * 0.1, color: _ink.withValues(alpha: 0.25));

  String _cardName() {
    final name = (user?.name ?? "…").trim();
    final parts = name.split(RegExp(r'\s+'));
    return (name.length > 14 && parts.length > 1 ? parts.last : name)
        .toUpperCase();
  }

  /// What goes with the picture when the card is shared.
  String caption(BuildContext context) => [
        _cardName(),
        if (title != null) title!,
        if (subtitle != null) subtitle!,
      ].join(" · ");

  Widget _statsArea(double w) {
    if (layout == FifaStatsLayout.columns) {
      return Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) _statSeparator(w),
            _statColumn(stats[i].label, stats[i].value, w),
          ],
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < stats.length; r += 3)
          Padding(
            padding: EdgeInsets.only(top: r == 0 ? 0 : w * 0.015),
            child: Row(
              children: [
                for (var stat in stats.skip(r).take(3)) _inlineStat(stat, w),
              ],
            ),
          ),
      ],
    );
  }

  /// A player's card from their profile: OVR is `score`; the attributes come
  /// with the player once enough teammates gave them traits (before that the
  /// stats row shows matches, wins and average score); the title is a role from
  /// the best attribute, and the app's name before that.
  factory FifaCard.player({
    Key? key,
    required UserDetails user,
    int? score,
    required FifaTheme theme,
    double maxWidth = 200,
    VoidCallback? onPictureTap,
    Widget? back,
  }) {
    final attributes = user.traitAttributes ?? {};
    final hasAttributes = attributes.isNotEmpty;
    return FifaCard(
      key: key,
      user: user,
      score: score,
      title: _roleTitle(attributes),
      theme: theme,
      maxWidth: maxWidth,
      layout: hasAttributes ? FifaStatsLayout.grid : FifaStatsLayout.columns,
      stats: hasAttributes
          ? [
              for (var a in _attributeOrder)
                FifaStat(a, "${attributes[a] ?? "–"}")
            ]
          : [
              FifaStat("MATCHES", "${user.numJoinedMatches ?? 0}"),
              FifaStat("WINS", "${user.numWin ?? 0}"),
              FifaStat(
                  "AVG SCORE",
                  user.averageScore == null
                      ? "–"
                      : user.averageScore!.toStringAsFixed(2)),
            ],
      // goalkeeping only shows for players who are given it
      extra: attributes.containsKey("GK") ? "GK ${attributes["GK"]}" : null,
      onPictureTap: onPictureTap,
      back: back,
    );
  }

  /// Attributes in the order FIFA shows them, three to a line.
  static const _attributeOrder = ["PAC", "SHO", "PAS", "DRI", "DEF", "PHY"];

  static const _roles = {
    "PAC": "SPEEDSTER",
    "SHO": "FINISHER",
    "PAS": "PLAYMAKER",
    "DRI": "DRIBBLER",
    "DEF": "ROCK",
    "PHY": "POWERHOUSE",
    "GK": "KEEPER",
  };
  // a role only shows when the best attribute clearly stands out
  static const _minRoleValue = 65;

  static String _roleTitle(Map<String, int> attributes) {
    if (attributes.isEmpty) return "NUTMEG";
    var best = attributes.entries.reduce((a, b) => b.value > a.value ? b : a);
    return best.value >= _minRoleValue
        ? _roles[best.key] ?? "NUTMEG"
        : "NUTMEG";
  }

  /// Number and label side by side, sharing the line equally.
  Widget _inlineStat(FifaStat stat, double w) => Expanded(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(stat.value,
                  style: _text(w * 0.075 * theme.statsScale, FontWeight.w700)),
              SizedBox(width: w * 0.015),
              Text(stat.label,
                  style: _text(w * 0.045 * theme.statsScale, FontWeight.w500,
                      color: theme.holo ? theme.accent : null)),
            ],
          ),
        ),
      );

  /// Change since last month: arrow and number, green up and red down.
  Widget _changeChip(num change, double w, {double scale = 1}) {
    final up = change > 0;
    final color = up ? Color(0xFF1B6B33) : Color(0xFF9B2226);
    return Container(
      padding: EdgeInsets.fromLTRB(
        w * 0.005 * scale,
        w * 0.005 * scale,
        w * 0.02 * scale,
        w * 0.005 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            size: w * 0.07 * scale,
            color: color,
          ),
          Text(
            up ? "+$change" : "$change",
            style: GoogleFonts.oswald(
              color: color,
              fontSize: w * 0.05 * scale,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: AspectRatio(
          aspectRatio: 576 / 800,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final h = c.maxHeight;
              // a card with a title and a period leads with the period
              final monthLed = title != null && subtitle != null;
              // the picture's edge starts lower than the plain card's
              final art = theme.background != null;
              final bodyTop = monthLed ? (art ? 0.27 : 0.25) : 0.225;
              // room under the picture for the longer header
              final lower = monthLed ? 0.02 : 0.0;
              final numberBlock = SizedBox(
                // as tall as the picture, so the number sits level with it
                width: emphasizeChange
                    ? w * 0.28
                    : (monthLed ? w * 0.22 : w * 0.26),
                height: monthLed ? w * 0.46 : w * 0.39,
                child: Center(
                  // the big change chip can be taller than the picture:
                  // let it spill over instead of overflowing
                  child: OverflowBox(
                    maxHeight: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _metal(
                            score == null ? "–" : "$score",
                            _text(w * 0.2, FontWeight.w700),
                          ),
                        ),
                        Text(
                          "OVR",
                          style: _text(w * 0.055, FontWeight.w500,
                              color: theme.holo ? theme.accent : null),
                        ),
                        if (extra != null) ...[
                          SizedBox(height: w * 0.02),
                          Text(
                            extra!,
                            style: _text(w * 0.06, FontWeight.w700),
                          ),
                        ],
                        // the player of the month card leaves the change out
                        if (change != null &&
                            change != 0 &&
                            theme.showChange) ...[
                          SizedBox(height: w * 0.025),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _changeChip(
                              change!,
                              w,
                              scale: emphasizeChange ? 1.6 : 1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
              final picture = Container(
                padding: EdgeInsets.all(w * 0.01),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // the holographic card has a rim of colour as a ring
                  gradient: theme.holo
                      ? SweepGradient(colors: theme.ringColors ?? _holoColors)
                      : null,
                  border: theme.holo
                      ? null
                      : Border.all(color: theme.ring, width: 1.6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: onPictureTap == null
                    ? UserAvatar(w * 0.22, user)
                    : InkWell(
                        customBorder: CircleBorder(),
                        onTap: onPictureTap,
                        child: UserAvatar(w * 0.22, user),
                      ),
              );
              return Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  if (art)
                    Positioned.fill(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(theme.background!, fit: BoxFit.fill),
                          if (effects)
                            ClipPath(
                              clipper: FifaCardClipper(),
                              child: FifaGoldEffects(glow: false),
                            ),
                        ],
                      ),
                    )
                  else
                    Positioned.fill(
                      child: PhysicalShape(
                        clipper: FifaCardClipper(),
                        color: theme.gradient[1],
                        elevation: effects ? 12 : 8,
                        shadowColor:
                            effects ? Color(0xFFFFB300) : Colors.black87,
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: theme.gradient,
                                  stops: theme.stops,
                                ),
                              ),
                            ),
                            CustomPaint(
                              painter: theme.electric
                                  ? _ElectricPainter()
                                  : theme.holo
                                      ? _CarbonPainter()
                                      : FifaStripesPainter(theme.stripe),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment(-1, -0.3),
                                  end: Alignment(1, 0.3),
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withValues(alpha: theme.sheen),
                                    Colors.transparent,
                                  ],
                                  stops: [0.25, 0.5, 0.75],
                                ),
                              ),
                            ),
                            if (effects) FifaGoldEffects(glow: !theme.holo),
                            CustomPaint(painter: _InsetBorderPainter(_ink)),
                            if (theme.holo)
                              CustomPaint(painter: _HoloRimPainter()),
                          ],
                        ),
                      ),
                    ),
                  if (back != null) ...[
                    // the back of the card: the name, then what `back` shows
                    Positioned(
                      top: h * (0.1 + lower),
                      left: w * 0.1,
                      right: w * 0.1,
                      child: _metal(
                        _cardName(),
                        _text(w * 0.105, FontWeight.w700,
                            spacing: w * 0.012, height: 1.2),
                        align: TextAlign.center,
                      ),
                    ),
                    Positioned(
                      top: h * 0.21,
                      bottom: h * 0.1,
                      left: w * 0.12,
                      right: w * 0.12,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(width: w * 0.9, child: back!),
                        ),
                      ),
                    ),
                  ] else ...[
                    if (title != null)
                      Positioned(
                        top: monthLed
                            ? h * (art ? 0.095 : 0.07)
                            : h * (theme.oxanium ? 0.1 : 0.065),
                        // the long title keeps clear of the card's shoulders
                        left: monthLed
                            ? w * 0.17
                            : (theme.oxanium ? w * 0.15 : w * 0.1),
                        right: monthLed
                            ? w * 0.17
                            : (theme.oxanium ? w * 0.15 : w * 0.1),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            title!,
                            style: (theme.oxanium
                                ? GoogleFonts.oxanium
                                : GoogleFonts.bebasNeue)(
                              color: art
                                  ? _ink
                                  : (theme.holo ? theme.accent : _ink),
                              fontWeight: theme.oxanium
                                  ? (monthLed
                                      ? FontWeight.w700
                                      : _weight(FontWeight.w600))
                                  : null,
                              fontSize: monthLed
                                  ? (title!.length > 10 ? w * 0.065 : w * 0.1) *
                                      theme.headerScale
                                  : (theme.oxanium ? w * 0.095 : w * 0.17),
                              height: 1,
                              letterSpacing: monthLed
                                  ? (title!.length > 10
                                          ? w * 0.015
                                          : w * 0.06) *
                                      theme.headerScale
                                  : theme.oxanium
                                      ? w * 0.04
                                      : title!.length <= 4
                                          ? w * 0.08
                                          : w * 0.03,
                              shadows: [
                                // a dark halo so it reads on the picture
                                if (art && theme.holo)
                                  Shadow(color: theme.outline, blurRadius: 4),
                                Shadow(color: _edge, offset: Offset(0, 0.8)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (subtitle != null)
                      Positioned(
                        top: monthLed
                            ? h * (art ? 0.16 : 0.135)
                            : title == null
                                ? h * 0.1
                                : h * 0.166,
                        left: w * 0.08,
                        right: w * 0.08,
                        child: monthLed
                            // the month is what sets the card apart: big
                            ? FittedBox(
                                fit: BoxFit.scaleDown,
                                child: theme.holo
                                    ? _metal(
                                        subtitle!,
                                        _text(w * 0.105 * theme.headerScale,
                                            FontWeight.w800,
                                            spacing:
                                                w * 0.012 * theme.headerScale),
                                      )
                                    : Text(
                                        subtitle!,
                                        style: GoogleFonts.bebasNeue(
                                          color: _ink,
                                          fontSize: w * 0.16,
                                          height: 1,
                                          letterSpacing: w * 0.02,
                                          shadows: [
                                            Shadow(
                                                color: _edge,
                                                offset: Offset(0, 0.8)),
                                          ],
                                        ),
                                      ),
                              )
                            : Text(
                                subtitle!,
                                textAlign: TextAlign.center,
                                style: title == null
                                    ? _text(
                                        w * 0.07,
                                        FontWeight.w600,
                                        spacing: w * 0.03,
                                      )
                                    : _text(
                                        w * 0.055,
                                        FontWeight.w600,
                                        spacing: w * 0.025,
                                      ),
                              ),
                      ),
                    if (monthLed)
                      // number and picture as one row, centred on the card
                      Positioned(
                        top: h * bodyTop,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            numberBlock,
                            SizedBox(width: w * 0.04),
                            picture
                          ],
                        ),
                      )
                    else ...[
                      Positioned(
                          top: h * bodyTop, left: w * 0.08, child: numberBlock),
                      Positioned(
                          top: h * bodyTop, left: w * 0.38, child: picture),
                    ],
                    if (!theme.holo)
                      Positioned(
                        top: h * (0.597 + lower * 0.9),
                        left: w * 0.12,
                        right: w * 0.12,
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _ink.withValues(alpha: 0),
                                _ink.withValues(alpha: 0.67),
                                _ink.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      // Oxanium sits higher: keep the name off the line above it
                      top: h * (0.612 + lower) +
                          (theme.oxanium && !theme.holo ? 24 : 0),
                      left: w * 0.08,
                      right: w * 0.08,
                      child: _metal(
                        _cardName(),
                        _text(
                          w * 0.105,
                          FontWeight.w700,
                          spacing: w * 0.012,
                          height: 1.2,
                        ),
                        align: TextAlign.center,
                      ),
                    ),
                    Positioned(
                      top: h * (0.747 + lower) +
                          (theme.oxanium && !theme.holo ? 16 : 0),
                      left: w * 0.1,
                      right: w * 0.1,
                      child: _statsArea(w),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A card shown big, with a button to share it as a picture.
class FifaCardDialog extends StatefulWidget {
  final FifaCard card;

  const FifaCardDialog({required this.card});

  @override
  State<FifaCardDialog> createState() => FifaCardDialogState();
}

/// Shares the picture of the card inside `boundary`, on a plain background
/// with some room around it.
Future<void> shareFifaCardPicture(
  BuildContext context,
  GlobalKey boundary,
  String caption,
) async {
  try {
    final render =
        boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (render == null) return;
    final card = await render.toImage(pixelRatio: 3);
    const pad = 48.0;
    final size = Size(card.width + 2 * pad, card.height + 2 * pad);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    canvas.drawImage(card, Offset(pad, pad), Paint());
    final picture = await recorder.endRecording().toImage(
          size.width.toInt(),
          size.height.toInt(),
        );
    final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null || !context.mounted) return;
    await shareWithOrigin(
      context,
      text: caption,
      files: [
        XFile.fromData(
          bytes.buffer.asUint8List(),
          name: 'card.png',
          mimeType: 'image/png',
        ),
      ],
    );
  } catch (e) {
    _logger.warning("Could not share the card: $e");
  }
}

class FifaCardDialogState extends State<FifaCardDialog> {
  final GlobalKey _boundary = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    await shareFifaCardPicture(
        context, _boundary, widget.card.caption(context));
    if (mounted) setState(() => _sharing = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // exactly the card, so the picture has no empty sides
          SizedBox(
            width: widget.card.maxWidth,
            child: RepaintBoundary(key: _boundary, child: widget.card),
          ),
          SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _sharing ? null : _share,
            icon: Icon(Icons.ios_share, size: 18),
            label: Text(l10n.shareAction),
          ),
        ],
      ),
    );
  }
}

void showFifaCard(BuildContext context, FifaCard card) =>
    showDialog(context: context, builder: (_) => FifaCardDialog(card: card));

/// A card with a share icon under it. The picture that is shared is the still
/// card, without the moving effects.
class ShareableFifaCard extends StatefulWidget {
  final FifaCard Function(bool effects) card;
  final bool effects;

  const ShareableFifaCard({required this.card, this.effects = false});

  @override
  State<ShareableFifaCard> createState() => _ShareableFifaCardState();
}

class _ShareableFifaCardState extends State<ShareableFifaCard> {
  final GlobalKey _boundary = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    final caption = widget.card(false).caption(context);
    setState(() => _sharing = true);
    // wait for a frame without the effects
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await shareFifaCardPicture(context, _boundary, caption);
    if (mounted) setState(() => _sharing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
          key: _boundary,
          child: widget.card(widget.effects && !_sharing),
        ),
        SizedBox(height: 4),
        IconButton(
          onPressed: _sharing ? null : _share,
          tooltip: AppLocalizations.of(context)!.shareAction,
          icon: Icon(Icons.ios_share, size: 20, color: Palette.primary),
        ),
      ],
    );
  }
}
