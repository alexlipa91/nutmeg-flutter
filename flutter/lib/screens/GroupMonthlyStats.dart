import 'dart:math' show min;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/l10n/app_localizations.dart';
import 'package:nutmeg/model/UserDetails.dart';
import 'package:nutmeg/state/UsersState.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/FifaCard.dart';
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
    var specials = <(Map<String, dynamic>, FifaTheme, String, bool, bool)>[
      if (potm != null)
        (potm, FifaTheme.blackGold, "PLAYER OF THE MONTH", false, true),
      if (improverEntry != null)
        (improverEntry, FifaTheme.blue, "ON FIRE", true, false),
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
              builder: (i, width) {
                FifaCard card(double w, bool effects) => _rankingCard(
                    context,
                    specials[i].$1,
                    users.getUserDetail(specials[i].$1["user_id"]),
                    data["month"] as String,
                    specials[i].$2,
                    title: specials[i].$3,
                    emphasizeChange: specials[i].$4,
                    effects: effects,
                    maxWidth: w);
                return ShareableFifaCard(
                    card: (effects) => card(width, effects),
                    effects: specials[i].$5);
              },
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

/// The small line on a card for the period: a month, a year or all time.
String _periodLabel(BuildContext context, String period) {
  if (period == "all") {
    return AppLocalizations.of(context)!.groupStatsTabAllTime.toUpperCase();
  }
  if (period.length == 4) return period;
  return DateFormat("MMM yyyy", Localizations.localeOf(context).toString())
      .format(DateTime(
          int.parse(period.substring(0, 4)), int.parse(period.substring(4))))
      .toUpperCase();
}

/// The card of a row of the ranking; `period` is yyyyMM, yyyy or "all".
FifaCard _rankingCard(BuildContext context, Map<String, dynamic> entry,
        UserDetails? user, String period, FifaTheme theme,
        {String? title,
        bool emphasizeChange = false,
        bool effects = false,
        double maxWidth = 200}) =>
    FifaCard(
      user: user,
      score: entry["score"],
      stats: [
        FifaStat("MATCHES", "${entry["played"]}"),
        FifaStat("WINS", "${entry["wins"]}"),
        FifaStat("AVG SCORE", (entry["avg_rating"] as num).toStringAsFixed(2)),
      ],
      change: entry["change"],
      subtitle: _periodLabel(context, period),
      theme: theme,
      title: title,
      emphasizeChange: emphasizeChange,
      effects: effects,
      maxWidth: maxWidth,
    );

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
        // card height plus room for its shadow and the share icon
        height: widget.itemWidth * 800 / 576 + 28 + 48,
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

  /// The player's card, big, with a button to share it.
  void _showCard(Map<String, dynamic> p) {
    var user = context.read<UsersState>().getUserDetail(p["user_id"]);
    showFifaCard(
        context,
        _rankingCard(context, p, user, widget.period,
            FifaTheme.forScore(p["score"] as num),
            maxWidth: 260));
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
