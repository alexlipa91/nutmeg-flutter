import 'dart:math' show min, pi, sin;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/l10n/app_localizations.dart';
import 'package:nutmeg/model/UserDetails.dart';
import 'package:nutmeg/state/UsersState.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/PageTemplate.dart';
import 'package:provider/provider.dart';

final _logger = CrashlyticsLogger("GroupMonthlyStats");

final _gold = UiUtils.fromHex("#F5B83D");

/// Monthly ranking of the players in an organizer's matches: one table with
/// each player's score, wins and average rating, over the rated games.
class GroupMonthlyStats extends StatefulWidget {
  final String organizerId;
  final String? month; // yyyyMM, latest month with results when null
  final bool showBack;

  const GroupMonthlyStats(
      {Key? key, required this.organizerId, this.month, this.showBack = true})
      : super(key: key);

  @override
  State<GroupMonthlyStats> createState() => _GroupMonthlyStatsState();
}

class _GroupMonthlyStatsState extends State<GroupMonthlyStats> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _failed = false;
  String? _month;
  // 0 monthly, 1 this year, 2 everything
  int _tab = 0;
  // kept across tabs, so the group name doesn't vanish while a tab loads
  String? _organizerId;

  @override
  void initState() {
    super.initState();
    _month = widget.month;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      var period = _tab == 1
          ? "${DateTime.now().year}"
          : _tab == 2
              ? "all"
              : _month;
      var data = await CloudFunctionsClient().get(
          "groups/${widget.organizerId}/monthly",
          args: period == null ? {} : {"month": period});
      if (data != null) _fetchUsers(data);
      if (!mounted) return;
      setState(() {
        _data = data;
        if (_tab == 0) _month = data?["month"];
        _organizerId = data?["organizer_id"] ?? _organizerId;
        _failed = data == null;
      });
    } catch (e) {
      _logger.warning("Could not load group stats: $e");
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fetchUsers(Map<String, dynamic> data) {
    var usersState = context.read<UsersState>();
    var organizerId = data["organizer_id"] as String?;
    if (organizerId != null) usersState.fetchUserDetails(organizerId);
    for (var p in data["players"] as List) {
      usersState.fetchUserDetails(p["user_id"] as String);
    }
  }

  static String monthLabel(String yyyymm, BuildContext context) {
    var date = DateTime(
        int.parse(yyyymm.substring(0, 4)), int.parse(yyyymm.substring(4)));
    var label =
        DateFormat("LLLL yyyy", Localizations.localeOf(context).toString())
            .format(date);
    return label[0].toUpperCase() + label.substring(1);
  }

  Widget _groupName(BuildContext context, AppLocalizations l10n) {
    var organizerId = _organizerId;
    var name = organizerId == null
        ? null
        : context
            .watch<UsersState>()
            .getUserDetail(organizerId)
            ?.getShortName();
    if (name == null) return SizedBox.shrink();
    return Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text(l10n.groupStatsGroupOf(name), style: TextPalette.bodyText));
  }

  void _goToTab(int tab) {
    if (tab == _tab) return;
    setState(() {
      _tab = tab;
      _data = null;
    });
    _load();
  }

  Widget _periodTabs(AppLocalizations l10n) {
    var labels = [
      l10n.groupStatsTabMonthly,
      "${DateTime.now().year}",
      l10n.groupStatsTabAllTime
    ];
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: Palette.white, borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: () => _goToTab(i),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                    color: _tab == i ? Palette.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(labels[i],
                    textAlign: TextAlign.center,
                    style: TextPalette.getBodyText(
                            _tab == i ? Colors.white : Palette.black)
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
      ]),
    );
  }

  void _goToMonth(String month) {
    if (month == _month) return;
    _month = month;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;
    var data = _data;

    Widget body;
    if (_loading && data == null) {
      body = Padding(
          padding: EdgeInsets.only(top: 80),
          child: Center(child: CircularProgressIndicator()));
    } else if (_failed || data == null) {
      body = Padding(
          padding: EdgeInsets.only(top: 80),
          child: Center(child: Text(l10n.groupStatsEmpty)));
    } else {
      body = _content(context, data, l10n);
    }

    return PageTemplate(
      appBar: widget.showBack
          ? Row(children: [
              Expanded(
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 1100),
                    child: Row(children: [BackButton(color: Palette.black)]),
                  ),
                ),
              ),
            ])
          : null,
      showTopBar: widget.showBack,
      widgets: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.navLeaderboard, style: TextPalette.h1Default),
                _groupName(context, l10n),
                SizedBox(height: 16),
                _periodTabs(l10n),
                SizedBox(height: 16),
                body,
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _monthSelector(BuildContext context, List<String> months, int matches,
      AppLocalizations l10n) {
    var idx = months.indexOf(_month ?? "");
    // months are sorted newest first: next index is the previous month
    var older = idx >= 0 && idx + 1 < months.length ? months[idx + 1] : null;
    var newer = idx > 0 ? months[idx - 1] : null;

    Widget arrow(IconData icon, String? target) => IconButton(
          icon: Icon(icon),
          color: Palette.black,
          disabledColor: Palette.greyLight,
          onPressed: target == null ? null : () => _goToMonth(target),
        );

    return Row(children: [
      arrow(Icons.chevron_left, older),
      Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Palette.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(children: [
            Text(_month == null ? "" : monthLabel(_month!, context),
                style: TextPalette.h2),
            SizedBox(height: 2),
            Text("${l10n.groupStatsMatches}: $matches",
                style: TextPalette.getBodyText(Palette.greyDark)),
          ]),
        ),
      ),
      arrow(Icons.chevron_right, newer),
    ]);
  }

  Widget _periodHeader(int matches, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text("${l10n.groupStatsMatches}: $matches",
          textAlign: TextAlign.center,
          style: TextPalette.getBodyText(Palette.greyDark)),
    );
  }

  Widget _content(
      BuildContext context, Map<String, dynamic> data, AppLocalizations l10n) {
    var months = (data["available_months"] as List).cast<String>();
    if (months.isEmpty) {
      // no finished matches in the group yet (e.g. a new user)
      return _EmptyState(text: l10n.groupStatsNoGames);
    }
    var ranking =
        ((data["ranking"] as List?) ?? []).cast<Map<String, dynamic>>();
    // the month in progress has no winner yet
    var now = DateTime.now();
    var isCurrentMonth = (data["month"] as String?) ==
        "${now.year}${now.month.toString().padLeft(2, '0')}";
    var monthly = _tab == 0;
    var potm =
        !monthly || isCurrentMonth || ranking.isEmpty ? null : ranking.first;
    var improver = !monthly || isCurrentMonth
        ? null
        : data["best_improver"] as Map<String, dynamic>?;
    var improverEntry = improver == null
        ? null
        : ranking.where((e) => e["user_id"] == improver["user_id"]).firstOrNull;
    var users = context.watch<UsersState>();
    // special cards, swiped sideways; only for a finished month
    // (player, look, title, whether it is about the change, moving effects)
    var specials = <(Map<String, dynamic>, _FifaTheme, String, bool, bool)>[
      if (potm != null) (potm, _FifaTheme.gold, "POTM", false, true),
      if (improverEntry != null)
        (improverEntry, _FifaTheme.blue, "ON FIRE", true, false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_tab == 0)
          _monthSelector(context, months, data["matches"] as int, l10n)
        else
          _periodHeader(data["matches"] as int, l10n),
        if (_loading)
          Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(minHeight: 2)),
        SizedBox(height: 16),
        if (ranking.isEmpty)
          Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text(l10n.groupStatsEmpty))),
        if (specials.isNotEmpty) ...[
          LayoutBuilder(builder: (context, c) {
            // the card in the middle is full size, the next ones peek in
            var itemWidth = min(240.0, c.maxWidth * 0.58);
            var fraction = (itemWidth + 20) / c.maxWidth;
            return _SpecialCards(
              key: ValueKey("specials-$_month-${fraction.toStringAsFixed(3)}"),
              count: specials.length,
              itemWidth: itemWidth,
              fraction: fraction,
              builder: (i, width) => _FifaCard(
                  entry: specials[i].$1,
                  user: users.getUserDetail(specials[i].$1["user_id"]),
                  period: data["month"] as String,
                  theme: specials[i].$2,
                  title: specials[i].$3,
                  emphasizeChange: specials[i].$4,
                  effects: specials[i].$5,
                  maxWidth: width),
            );
          }),
          SizedBox(height: 8),
        ],
        if (ranking.isNotEmpty) ...[
          _RankingTable(
              // a new period starts again from the score order
              key: ValueKey("ranking-$_tab-$_month"),
              ranking: ranking,
              highlightFirst: !monthly || !isCurrentMonth,
              period: data["month"] as String,
              l10n: l10n),
          Padding(
              padding: EdgeInsets.fromLTRB(4, 12, 4, 0),
              child: Text(
                  switch (data["ranking_source"]) {
                        "month" => l10n.groupStatsInfoMonth,
                        "last_games" => l10n.groupStatsInfoLastGames,
                        _ => l10n.groupStatsInfoPeriod,
                      } +
                      // the year and all time leave out players with few games
                      (((data["ranking_min_games"] as int?) ?? 0) > 0
                          ? " ${l10n.groupStatsInfoMinGames(data["ranking_min_games"])}"
                          : ""),
                  style: TextPalette.getBodyText(Palette.greyDark)
                      .copyWith(fontSize: 12))),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;

  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Center(
        child: Column(children: [
          Icon(Icons.emoji_events_outlined, size: 64, color: Palette.greyLight),
          SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center, style: TextPalette.h3),
        ]),
      ),
    );
  }
}

class _FifaCardClipper extends CustomClipper<Path> {
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

class _StripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final area = Rect.fromLTWH(0, 0, s.width, s.height * 0.65);
    final paint = Paint()
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white54, Colors.transparent],
      ).createShader(area);
    final step = s.width * 0.014;
    for (double x = -area.height; x < s.width; x += step) {
      canvas.drawLine(
          Offset(x, area.height), Offset(x + area.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Cards in a row to swipe: the one in the middle is full size, the others
/// shrink and fade as they move away.
class _SpecialCards extends StatefulWidget {
  final int count;
  final double itemWidth; // width of the card in the middle
  final double fraction; // share of the width each page takes
  final Widget Function(int index, double width) builder;

  const _SpecialCards(
      {Key? key,
      required this.count,
      required this.itemWidth,
      required this.fraction,
      required this.builder})
      : super(key: key);

  @override
  State<_SpecialCards> createState() => _SpecialCardsState();
}

class _SpecialCardsState extends State<_SpecialCards> {
  late final PageController _controller =
      PageController(viewportFraction: widget.fraction);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      // swipe with a finger, a trackpad or the mouse
      behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      }),
      child: SizedBox(
        // card height plus room for its shadow
        height: widget.itemWidth * 800 / 576 + 28,
        child: PageView.builder(
          controller: _controller,
          itemCount: widget.count,
          itemBuilder: (context, i) => AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              var page =
                  _controller.hasClients && _controller.position.haveDimensions
                      ? _controller.page!
                      : 0.0;
              var away = (page - i).abs().clamp(0.0, 1.0);
              return Align(
                child: Opacity(
                  opacity: 1 - 0.4 * away,
                  child: Transform.scale(
                    scale: 1 - 0.22 * away,
                    child: SizedBox(
                        width: widget.itemWidth,
                        child: widget.builder(i, widget.itemWidth)),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Moving effects for the best player's card: a light sweeping across it now
/// and then and a pulsing glow behind the picture.
class _GoldEffects extends StatefulWidget {
  const _GoldEffects();

  @override
  State<_GoldEffects> createState() => _GoldEffectsState();
}

class _GoldEffectsState extends State<_GoldEffects>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: Duration(seconds: 5));

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
  Widget build(BuildContext context) =>
      CustomPaint(painter: _GoldEffectsPainter(_controller));
}

class _GoldEffectsPainter extends CustomPainter {
  final Animation<double> t;

  _GoldEffectsPainter(this.t) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height, v = t.value;

    // glow behind the picture, pulsing twice per cycle
    final pulse = 0.5 + 0.5 * sin(2 * pi * v * 2);
    final center = Offset(w * 0.57, h * 0.38);
    canvas.drawCircle(
        center,
        w * 0.36,
        Paint()
          ..shader = RadialGradient(colors: [
            Colors.transparent,
            Color.fromRGBO(255, 244, 200, 0.3 + 0.35 * pulse),
            Colors.transparent,
          ], stops: [
            0.45,
            0.62,
            1
          ]).createShader(Rect.fromCircle(center: center, radius: w * 0.36)));

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
                ]).createShader(Offset.zero & s));
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Colours and background effect of a card.
class _FifaTheme {
  final List<Color> gradient;
  final List<double> stops;
  final Color ink;
  final Color ring;
  final bool electric;

  const _FifaTheme(
      {required this.gradient,
      required this.stops,
      required this.ink,
      required this.ring,
      this.electric = false});

  static const gold = _FifaTheme(gradient: [
    Color(0xFFF6DE8D),
    Color(0xFFD9B04A),
    Color(0xFFF2D77A),
    Color(0xFFC9A03C),
  ], stops: [
    0,
    0.4,
    0.7,
    1
  ], ink: Color(0xFF3B2A06), ring: Color(0xFF9A7620));

  static const silver = _FifaTheme(gradient: [
    Color(0xFFF2F4F7),
    Color(0xFFB9C0CA),
    Color(0xFFE6E9EE),
    Color(0xFF9AA3AF),
  ], stops: [
    0,
    0.4,
    0.7,
    1
  ], ink: Color(0xFF2B3036), ring: Color(0xFF7B8490));

  static const bronze = _FifaTheme(gradient: [
    Color(0xFFE8B48A),
    Color(0xFFB87333),
    Color(0xFFD9956B),
    Color(0xFF8A4F22),
  ], stops: [
    0,
    0.4,
    0.7,
    1
  ], ink: Color(0xFF2E1706), ring: Color(0xFF6E3B14));

  static const blue = _FifaTheme(gradient: [
    Color(0xFF1747FF),
    Color(0xFF0096FF),
    Color(0xFF2230E0),
    Color(0xFF0A1A8C),
  ], stops: [
    0,
    0.35,
    0.7,
    1
  ], ink: Colors.white, ring: Color(0xFF9FE9FF), electric: true);
}

/// Glow behind the picture and a couple of lightning bolts, for the blue card.
class _ElectricPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    canvas.drawRect(
        Offset.zero & s,
        Paint()
          ..shader =
              RadialGradient(colors: [Color(0xAA7FE8FF), Color(0x007FE8FF)])
                  .createShader(Rect.fromCircle(
                      center: Offset(w * 0.62, h * 0.34), radius: w * 0.6)));
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
        [0.16, 0.44]
      ],
      [
        [0.95, 0.06],
        [0.88, 0.16],
        [0.95, 0.24],
        [0.89, 0.36],
        [0.94, 0.46]
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
        _FifaCardClipper().getClip(s).transform(m.storage),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = color.withValues(alpha: 0.33));
  }

  @override
  bool shouldRepaint(_) => false;
}

/// A player's card for a period: `entry` is the player's row of the ranking.
/// `title` marks a special card (POTM, ...); without one it is a plain card.
class _FifaCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final UserDetails? user;
  final String period; // yyyyMM, yyyy or "all"
  final _FifaTheme theme;
  final String? title;
  final double maxWidth;
  // the card is about the change since last month: show it big
  final bool emphasizeChange;
  // moving effects and a golden halo, for the best player's card
  final bool effects;

  const _FifaCard(
      {Key? key,
      required this.entry,
      required this.user,
      required this.period,
      required this.theme,
      this.title,
      this.maxWidth = 200,
      this.emphasizeChange = false,
      this.effects = false})
      : super(key: key);

  Color get _ink => theme.ink;

  /// Light edge on dark text, dark edge on light text.
  Color get _edge => _ink.computeLuminance() > 0.5
      ? Colors.black.withValues(alpha: 0.35)
      : Colors.white.withValues(alpha: 0.55);

  TextStyle _text(double size, FontWeight weight,
          {double? spacing, double height = 1}) =>
      GoogleFonts.oswald(
          color: _ink,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: spacing,
          height: height,
          shadows: [Shadow(color: _edge, offset: Offset(0, 0.8))]);

  /// Label on top, number below, sharing the row equally.
  Widget _statColumn(String label, String value, double w) {
    return Expanded(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label,
              style: _text(w * 0.046, FontWeight.w500, height: 1.2)),
        ),
        Text(value, style: _text(w * 0.09, FontWeight.w700, height: 1.1)),
      ]),
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

  String _periodLabel(BuildContext context) {
    if (period == "all") {
      return AppLocalizations.of(context)!.groupStatsTabAllTime.toUpperCase();
    }
    if (period.length == 4) return period;
    return DateFormat("MMM yyyy", Localizations.localeOf(context).toString())
        .format(DateTime(
            int.parse(period.substring(0, 4)), int.parse(period.substring(4))))
        .toUpperCase();
  }

  /// Change since last month: arrow and number, green up and red down.
  Widget _changeChip(num change, double w, {double scale = 1}) {
    final up = change > 0;
    final color = up ? Color(0xFF1B6B33) : Color(0xFF9B2226);
    return Container(
      padding: EdgeInsets.fromLTRB(w * 0.005 * scale, w * 0.005 * scale,
          w * 0.02 * scale, w * 0.005 * scale),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(w)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(up ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            size: w * 0.07 * scale, color: color),
        Text(up ? "+$change" : "$change",
            style: GoogleFonts.oswald(
                color: color,
                fontSize: w * 0.05 * scale,
                height: 1,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    num? change = entry["change"];
    var label = _periodLabel(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: AspectRatio(
          aspectRatio: 576 / 800,
          child: LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            return Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: PhysicalShape(
                      clipper: _FifaCardClipper(),
                      color: theme.gradient[1],
                      elevation: effects ? 12 : 8,
                      shadowColor: effects ? Color(0xFFFFB300) : Colors.black87,
                      clipBehavior: Clip.antiAlias,
                      child: Stack(fit: StackFit.expand, children: [
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
                                : _StripesPainter()),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(-1, -0.3),
                              end: Alignment(1, 0.3),
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.5),
                                Colors.transparent,
                              ],
                              stops: [0.25, 0.5, 0.75],
                            ),
                          ),
                        ),
                        if (effects) _GoldEffects(),
                        CustomPaint(painter: _InsetBorderPainter(_ink)),
                      ]),
                    ),
                  ),
                  if (title != null)
                    Positioned(
                      top: h * 0.065,
                      left: w * 0.1,
                      right: w * 0.1,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(title!,
                            style: GoogleFonts.bebasNeue(
                                color: _ink,
                                fontSize: w * 0.17,
                                height: 1,
                                letterSpacing:
                                    title!.length <= 4 ? w * 0.08 : w * 0.03,
                                shadows: [
                                  Shadow(color: _edge, offset: Offset(0, 0.8))
                                ])),
                      ),
                    ),
                  Positioned(
                    top: title == null ? h * 0.1 : h * 0.166,
                    left: 0,
                    right: 0,
                    child: Text(label,
                        textAlign: TextAlign.center,
                        style: title == null
                            ? _text(w * 0.07, FontWeight.w600,
                                spacing: w * 0.03)
                            : _text(w * 0.055, FontWeight.w600,
                                spacing: w * 0.025)),
                  ),
                  Positioned(
                    top: h * 0.24,
                    left: w * 0.08,
                    width: emphasizeChange ? w * 0.28 : w * 0.26,
                    // as tall as the picture, so the number sits level with it
                    height: w * 0.39,
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
                                    child: Text("${entry["score"]}",
                                        style: _text(w * 0.2, FontWeight.w700)),
                                  ),
                                  Text("OVR",
                                      style: _text(w * 0.055, FontWeight.w500)),
                                  if (change != null && change != 0) ...[
                                    SizedBox(height: w * 0.025),
                                    FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: _changeChip(change, w,
                                            scale: emphasizeChange ? 2 : 1)),
                                  ],
                                ]))),
                  ),
                  Positioned(
                    top: h * 0.24,
                    left: w * 0.38,
                    child: Container(
                      padding: EdgeInsets.all(w * 0.01),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.ring, width: 1.6),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black38,
                              blurRadius: 6,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      child: UserAvatar(w * 0.22, user),
                    ),
                  ),
                  Positioned(
                    top: h * 0.597,
                    left: w * 0.12,
                    right: w * 0.12,
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          _ink.withValues(alpha: 0),
                          _ink.withValues(alpha: 0.67),
                          _ink.withValues(alpha: 0),
                        ]),
                      ),
                    ),
                  ),
                  Positioned(
                    top: h * 0.612,
                    left: w * 0.08,
                    right: w * 0.08,
                    child: Text(
                      _cardName(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: _text(w * 0.105, FontWeight.w700,
                          spacing: w * 0.012, height: 1.2),
                    ),
                  ),
                  Positioned(
                    top: h * 0.747,
                    left: w * 0.1,
                    right: w * 0.1,
                    child: Row(children: [
                      _statColumn("MATCHES", "${entry["played"]}", w),
                      _statSeparator(w),
                      _statColumn("WINS", "${entry["wins"]}", w),
                      _statSeparator(w),
                      _statColumn("AVG SCORE",
                          (entry["avg_rating"] as num).toStringAsFixed(2), w),
                    ]),
                  ),
                ]);
          }),
        ),
      ),
    );
  }
}

class _PlayerName extends StatelessWidget {
  final String userId;
  final double radius;

  const _PlayerName({required this.userId, this.radius = 14});

  @override
  Widget build(BuildContext context) {
    var ud = context.watch<UsersState>().getUserDetail(userId);
    return Row(children: [
      UserAvatar(radius, ud),
      SizedBox(width: 10),
      Flexible(
        child: Text(ud?.name?.split(" ").first ?? "…",
            overflow: TextOverflow.ellipsis, style: TextPalette.bodyText),
      ),
    ]);
  }
}

class _RankingTable extends StatefulWidget {
  final List<Map<String, dynamic>> ranking;
  // gold row and trophy for the player at the top
  final bool highlightFirst;
  final String period; // yyyyMM, yyyy or "all"
  final AppLocalizations l10n;

  const _RankingTable(
      {Key? key,
      required this.ranking,
      required this.highlightFirst,
      required this.period,
      required this.l10n})
      : super(key: key);

  @override
  State<_RankingTable> createState() => _RankingTableState();
}

class _RankingTableState extends State<_RankingTable> {
  static const _numWidth = 46.0;

  // the ranking arrives sorted by score; tap a header to sort by its column,
  // tap again to flip the order
  String _sortKey = "score";
  bool _descending = true;

  List<Map<String, dynamic>> get _sorted {
    var indexed = widget.ranking.asMap().entries.toList();
    indexed.sort((a, b) {
      num? x = a.value[_sortKey], y = b.value[_sortKey];
      // players without a value go last, whatever the order
      var c = x == null && y == null
          ? 0
          : x == null
              ? 1
              : y == null
                  ? -1
                  : _descending
                      ? y.compareTo(x)
                      : x.compareTo(y);
      return c != 0 ? c : a.key.compareTo(b.key);
    });
    return indexed.map((e) => e.value).toList();
  }

  void _sortBy(String key) => setState(() {
        if (key == _sortKey) {
          _descending = !_descending;
        } else {
          _sortKey = key;
          _descending = true;
        }
      });

  Widget _head(String text, String key) => InkWell(
        onTap: () => _sortBy(key),
        child: SizedBox(
          width: _numWidth,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(text,
                style: TextPalette.getBodyText(Palette.greyDark)
                    .copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
            if (key == _sortKey)
              Icon(_descending ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                  size: 14, color: Palette.greyDark),
          ]),
        ),
      );

  Widget _cell(String text, {bool bold = false}) => SizedBox(
        width: _numWidth,
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextPalette.bodyText.copyWith(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
      );

  // the monthly view carries the change in OVR since the previous month
  bool get _showChange => widget.ranking.any((p) => p.containsKey("change"));

  /// Change since last month: green up, red down, "–" when not ranked then.
  Widget _change(num? change) {
    var color = change == null || change == 0
        ? Palette.greyLight
        : change > 0
            ? Palette.green
            : Palette.destructive;
    var text = change == null
        ? "–"
        : change > 0
            ? "+$change"
            : "$change";
    return SizedBox(
      width: _numWidth,
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextPalette.bodyText.copyWith(
              color: color,
              fontWeight: change == null || change == 0
                  ? FontWeight.w400
                  : FontWeight.w700)),
    );
  }

  @override
  Widget build(BuildContext context) {
    var players = _sorted;
    return InfoContainer(
      padding: EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            SizedBox(width: 28),
            Expanded(child: SizedBox()),
            _head("OVR", "score"),
            if (_showChange) _head("Δ", "change"),
            _head(widget.l10n.groupStatsWinsShort, "wins"),
            _head(widget.l10n.groupStatsRatingShort, "avg_rating"),
          ]),
          SizedBox(height: 6),
          Divider(height: 1, color: Palette.greyLighter),
          for (var i = 0; i < players.length; i++) ...[
            _row(i, players[i]),
            if (i < players.length - 1)
              Divider(height: 1, color: Palette.greyLightest),
          ],
        ],
      ),
    );
  }

  /// A plain card of the player, closed by tapping anywhere.
  void _showCard(Map<String, dynamic> p) {
    var user = context.read<UsersState>().getUserDetail(p["user_id"]);
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.all(24),
        child: GestureDetector(
          onTap: () => Navigator.of(dialogContext).pop(),
          child: _FifaCard(
              entry: p,
              user: user,
              period: widget.period,
              // gold above 80, silver above 70, bronze below
              theme: (p["score"] as num) > 80
                  ? _FifaTheme.gold
                  : (p["score"] as num) > 70
                      ? _FifaTheme.silver
                      : _FifaTheme.bronze,
              maxWidth: 260),
        ),
      ),
    );
  }

  Widget _row(int i, Map<String, dynamic> p) {
    // the winner keeps the gold row wherever the sorting puts them
    var top = widget.highlightFirst &&
        p["user_id"] == widget.ranking.first["user_id"];
    return InkWell(
        // cards are for a month; the year and all time have none
        onTap: widget.period.length == 6 ? () => _showCard(p) : null,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: top
              ? BoxDecoration(
                  color: _gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10))
              : null,
          child: Row(children: [
            SizedBox(
                width: 28,
                child: Center(
                    child: top
                        ? Icon(Icons.emoji_events, size: 16, color: _gold)
                        : Text("${i + 1}",
                            style: TextPalette.getBodyText(Palette.greyDark)
                                .copyWith(fontSize: 13)))),
            Expanded(child: _PlayerName(userId: p["user_id"], radius: 15)),
            _cell("${p["score"]}", bold: true),
            if (_showChange) _change(p["change"] as num?),
            _cell("${p["wins"]}"),
            _cell((p["avg_rating"] as num).toStringAsFixed(2)),
          ]),
        ));
  }
}
