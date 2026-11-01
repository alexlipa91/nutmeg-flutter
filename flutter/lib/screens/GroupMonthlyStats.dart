import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/l10n/app_localizations.dart';
import 'package:nutmeg/state/UsersState.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/PageTemplate.dart';
import 'package:provider/provider.dart';

final _logger = CrashlyticsLogger("GroupMonthlyStats");

final _gold = UiUtils.fromHex("#F5B83D");
final _heroDark = UiUtils.fromHex("#1F2A7A");

/// Monthly performance of the players in an organizer's matches: player of the
/// month, most wins, best rated, most losses, strongest chemistry, repeated
/// awards and a full table.
class GroupMonthlyStats extends StatefulWidget {
  final String organizerId;
  final String? month; // yyyyMM, latest month with results when null
  final bool showBack;

  const GroupMonthlyStats(
      {Key? key,
      required this.organizerId,
      this.month,
      this.showBack = true})
      : super(key: key);

  @override
  State<GroupMonthlyStats> createState() => _GroupMonthlyStatsState();
}

class _GroupMonthlyStatsState extends State<GroupMonthlyStats> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _failed = false;
  String? _month;

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
      var data = await CloudFunctionsClient().get(
          "groups/${widget.organizerId}/monthly",
          args: _month == null ? {} : {"month": _month});
      if (data != null) _fetchUsers(data);
      if (!mounted) return;
      setState(() {
        _data = data;
        _month = data?["month"];
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
                Text(l10n.groupStatsTitle, style: TextPalette.h1Default),
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

  Widget _monthSelector(
      BuildContext context, List<String> months, int matches, AppLocalizations l10n) {
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

  Widget _content(
      BuildContext context, Map<String, dynamic> data, AppLocalizations l10n) {
    var months = (data["available_months"] as List).cast<String>();
    if (months.isEmpty) {
      // no finished matches in the group yet (e.g. a new user)
      return _EmptyState(text: l10n.groupStatsNoGames);
    }
    var highlights = data["highlights"] as Map<String, dynamic>;
    var players = (data["players"] as List).cast<Map<String, dynamic>>();
    var potm = data["player_of_the_month"] as Map<String, dynamic>?;
    var runnersUp = (data["runners_up"] as List).cast<Map<String, dynamic>>();

    var mostWins = (highlights["most_wins"] as List).cast<Map<String, dynamic>>();
    var bestRating =
        (highlights["best_rating"] as List).cast<Map<String, dynamic>>();
    var mostLosses =
        (highlights["most_losses"] as List).cast<Map<String, dynamic>>();
    var chemistry = highlights["chemistry"] as Map<String, dynamic>?;
    var repeatAwards =
        (highlights["repeat_awards"] as List).cast<Map<String, dynamic>>();

    // Show at most 3 tied players, then "+N".
    List<Widget> limited(List<Map<String, dynamic>> entries, Color color,
        String Function(Map<String, dynamic>) value) {
      return [
        for (var e in entries.take(3))
          _PlayerRow(userId: e["user_id"], value: value(e), color: color),
        if (entries.length > 3)
          Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text("+${entries.length - 3}",
                  style: TextPalette.getBodyText(Palette.greyDark))),
      ];
    }

    var cards = <Widget>[
      if (mostWins.isNotEmpty)
        _HighlightCard(
          title: l10n.groupStatsMostWins,
          icon: Icons.emoji_events,
          color: Palette.green,
          rows: limited(mostWins, Palette.green,
              (e) => "${e["wins"]}/${e["played"]}"),
        ),
      if (bestRating.isNotEmpty)
        _HighlightCard(
          title: l10n.groupStatsBestRating,
          icon: Icons.star,
          color: Palette.accent,
          rows: limited(bestRating, Palette.accent,
              (e) => (e["avg_rating"] as num).toStringAsFixed(2)),
        ),
      if (mostLosses.isNotEmpty)
        _HighlightCard(
          title: l10n.groupStatsMostLosses,
          icon: Icons.trending_down,
          color: Palette.destructive,
          rows: limited(mostLosses, Palette.destructive,
              (e) => "${e["losses"]}/${e["played"]}"),
        ),
      if (chemistry != null)
        _HighlightCard(
          title: l10n.groupStatsChemistry,
          icon: Icons.handshake,
          color: Palette.primary,
          rows: [
            Row(children: [
              for (var uid in (chemistry["users"] as List).cast<String>()) ...[
                Expanded(child: _PlayerName(userId: uid, radius: 18)),
              ],
            ]),
            SizedBox(height: 10),
            _Pill(
                "${chemistry["wins"]}${l10n.groupStatsWinsShort} ${chemistry["draws"]}${l10n.groupStatsDrawsShort} ${chemistry["losses"]}${l10n.groupStatsLossesShort} ${l10n.groupStatsTogether}",
                Palette.primary),
          ],
        ),
      if (repeatAwards.isNotEmpty)
        _HighlightCard(
          title: l10n.groupStatsRepeatAwards,
          icon: Icons.military_tech,
          color: UiUtils.fromHex("#8E44AD"),
          rows: [
            for (var a in repeatAwards)
              _PlayerRow(
                  userId: a["user_id"],
                  label: _awardName(l10n, a["award"]),
                  value: "×${a["times"]}",
                  color: UiUtils.fromHex("#8E44AD"))
          ],
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _monthSelector(context, months, data["matches"] as int, l10n),
        if (_loading)
          Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(minHeight: 2)),
        SizedBox(height: 16),
        if (players.isEmpty)
          Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text(l10n.groupStatsEmpty))),
        if (potm != null) ...[
          _PlayerOfTheMonthCard(
              key: ValueKey("potm-$_month"),
              potm: potm,
              runnersUp: runnersUp,
              l10n: l10n),
          SizedBox(height: 16),
        ],
        for (var c in cards) ...[c, SizedBox(height: 16)],
        if (players.isNotEmpty)
          _PlayersTable(
              players: players,
              potmId: potm?["user_id"] as String?,
              l10n: l10n),
      ],
    );
  }

  static String _awardName(AppLocalizations l10n, String awardId) {
    switch (awardId) {
      case "best_goal":
        return l10n.bestGoalAwardName;
      case "best_striker":
        return l10n.bestStrikerAwardName;
      case "best_goalkeeper":
        return l10n.bestGoalkeeperAwardName;
      case "best_defender":
        return l10n.bestDefenderAwardName;
      default:
        return awardId;
    }
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

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  final bool onDark;

  const _Pill(this.text, this.color, {this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withOpacity(0.18) : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextPalette.getBodyText(onDark ? Colors.white : color)
              .copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

class _PlayerOfTheMonthCard extends StatelessWidget {
  final Map<String, dynamic> potm;
  final List<Map<String, dynamic>> runnersUp;
  final AppLocalizations l10n;

  const _PlayerOfTheMonthCard(
      {Key? key, required this.potm, required this.runnersUp, required this.l10n})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var ud = context.watch<UsersState>().getUserDetail(potm["user_id"]);
    var name = ud?.name?.split(" ").first ?? "…";

    var card = Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Palette.primary, _heroDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Palette.primary.withOpacity(0.35),
              blurRadius: 24,
              offset: Offset(0, 12)),
        ],
      ),
      child: Column(children: [
        Text(l10n.groupStatsPlayerOfMonth,
            style: TextPalette.getBodyText(Colors.white70)
                .copyWith(fontWeight: FontWeight.w600)),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _gold, width: 3),
            boxShadow: [
              BoxShadow(color: _gold.withOpacity(0.5), blurRadius: 22),
            ],
          ),
          child: UserAvatar(44, ud),
        ),
        SizedBox(height: 12),
        Text(name,
            style: TextPalette.h1Default.copyWith(color: Colors.white, fontSize: 30)),
        SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
          _Pill("${potm["wins"]} ${l10n.groupStatsWinsWord}", Colors.white,
              onDark: true),
          _Pill(
              "${(potm["avg_rating"] as num).toStringAsFixed(2)} ${l10n.groupStatsRatingWord}",
              Colors.white,
              onDark: true),
        ]),
        if (potm["most_wins"] == true || potm["best_rated"] == true) ...[
          SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            if (potm["most_wins"] == true)
              _Pill("🏆 ${l10n.groupStatsMostWins}", _gold),
            if (potm["best_rated"] == true)
              _Pill("⭐ ${l10n.groupStatsBestRating}", _gold),
          ]),
        ],
        if (runnersUp.isNotEmpty) ...[
          SizedBox(height: 16),
          Divider(color: Colors.white24, height: 1),
          SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < runnersUp.length; i++) ...[
              if (i > 0) SizedBox(width: 24),
              _RunnerUp(rank: i + 2, userId: runnersUp[i]["user_id"]),
            ],
          ]),
        ],
      ]),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1.0),
      duration: Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Opacity(
        opacity: ((scale - 0.92) / 0.08).clamp(0.0, 1.0),
        child: Transform.scale(scale: scale, child: child),
      ),
      child: card,
    );
  }
}

class _RunnerUp extends StatelessWidget {
  final int rank;
  final String userId;

  const _RunnerUp({required this.rank, required this.userId});

  @override
  Widget build(BuildContext context) {
    var ud = context.watch<UsersState>().getUserDetail(userId);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(rank == 2 ? "🥈" : "🥉", style: TextStyle(fontSize: 18)),
      SizedBox(width: 6),
      UserAvatar(14, ud),
      SizedBox(width: 8),
      Text(ud?.name?.split(" ").first ?? "…",
          style: TextPalette.getBodyText(Colors.white)),
    ]);
  }
}

class _HighlightCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> rows;

  const _HighlightCard(
      {required this.title,
      required this.icon,
      required this.color,
      required this.rows});

  @override
  Widget build(BuildContext context) {
    return InfoContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.14), shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: color),
            ),
            SizedBox(width: 10),
            Text(title, style: TextPalette.h4),
          ]),
          SizedBox(height: 12),
          ...rows,
        ],
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

class _PlayerRow extends StatelessWidget {
  final String userId;
  final String? label;
  final String? value;
  final Color color;

  const _PlayerRow(
      {required this.userId, this.label, this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        if (label != null) ...[
          SizedBox(
              width: 130,
              child: Text(label!,
                  style: TextPalette.getBodyText(Palette.greyDark))),
        ],
        Expanded(child: _PlayerName(userId: userId, radius: 18)),
        if (value != null) _Pill(value!, color),
      ]),
    );
  }
}

class _ResultBar extends StatelessWidget {
  final int wins, draws, losses;

  const _ResultBar(this.wins, this.draws, this.losses);

  @override
  Widget build(BuildContext context) {
    Widget seg(int n, Color c) => n == 0
        ? SizedBox.shrink()
        : Expanded(flex: n, child: Container(color: c));
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        width: 64,
        height: 6,
        child: Row(children: [
          seg(wins, Palette.green),
          seg(draws, Palette.greyLight),
          seg(losses, Palette.destructive),
        ]),
      ),
    );
  }
}

class _PlayersTable extends StatelessWidget {
  final List<Map<String, dynamic>> players;
  final String? potmId;
  final AppLocalizations l10n;

  const _PlayersTable(
      {required this.players, required this.potmId, required this.l10n});

  static const _numWidth = 30.0;
  static const _ratingWidth = 56.0;

  Widget _num(String text, {Color? color, bool bold = false}) => SizedBox(
        width: _numWidth,
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextPalette.bodyText.copyWith(
                color: color,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
      );

  Widget _head(String text, {double width = _numWidth}) => SizedBox(
        width: width,
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextPalette.getBodyText(Palette.greyDark)
                .copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
      );

  /// Rating as a chip: green from 4, orange from 3, red below.
  Widget _rating(num? rating) {
    if (rating == null) {
      return SizedBox(
          width: _ratingWidth,
          child: Text("–",
              textAlign: TextAlign.center,
              style: TextPalette.getBodyText(Palette.greyLight)));
    }
    var color = rating >= 4
        ? Palette.green
        : rating >= 3
            ? Palette.accent
            : Palette.destructive;
    return SizedBox(
      width: _ratingWidth,
      child: Center(child: _Pill(rating.toStringAsFixed(2), color)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InfoContainer(
      padding: EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: LayoutBuilder(builder: (context, constraints) {
        // On narrow screens drop the result bar and the games column.
        var compact = constraints.maxWidth < 460;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text(l10n.groupStatsAllPlayers, style: TextPalette.h4),
            ),
            Row(children: [
              SizedBox(width: 28),
              Expanded(child: SizedBox()),
              if (!compact) ...[
                SizedBox(width: 64),
                SizedBox(width: 10),
                _head(l10n.groupStatsPlayedShort),
              ],
              _head(l10n.groupStatsWinsShort),
              _head(l10n.groupStatsDrawsShort),
              _head(l10n.groupStatsLossesShort),
              _head(l10n.groupStatsRatingShort, width: _ratingWidth),
            ]),
            SizedBox(height: 6),
            Divider(height: 1, color: Palette.greyLighter),
            for (var i = 0; i < players.length; i++) ...[
              _row(context, i, compact),
              if (i < players.length - 1)
                Divider(height: 1, color: Palette.greyLightest),
            ],
          ],
        );
      }),
    );
  }

  Widget _row(BuildContext context, int i, bool compact) {
    var p = players[i];
    var isPotm = p["user_id"] == potmId;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: isPotm
          ? BoxDecoration(
              color: _gold.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10))
          : null,
      child: Row(children: [
        SizedBox(
            width: 28,
            child: Center(
                child: isPotm
                    ? Icon(Icons.emoji_events, size: 16, color: _gold)
                    : Text("${i + 1}",
                        style: TextPalette.getBodyText(Palette.greyDark)
                            .copyWith(fontSize: 13)))),
        Expanded(child: _PlayerName(userId: p["user_id"], radius: 15)),
        if (!compact) ...[
          _ResultBar(p["wins"], p["draws"], p["losses"]),
          SizedBox(width: 10),
          _num("${p["played"]}", color: Palette.greyDark),
        ],
        _num("${p["wins"]}",
            color: p["wins"] > 0 ? Palette.green : Palette.greyLight,
            bold: p["wins"] > 0),
        _num("${p["draws"]}",
            color: p["draws"] > 0 ? Palette.greyDark : Palette.greyLight),
        _num("${p["losses"]}",
            color: p["losses"] > 0 ? Palette.destructive : Palette.greyLight,
            bold: p["losses"] > 0),
        _rating(p["avg_rating"] as num?),
      ]),
    );
  }
}
