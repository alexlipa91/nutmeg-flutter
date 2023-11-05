import 'package:flutter/material.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/screens/JoinModal.dart';
import 'package:nutmeg/screens/LeaveMatchModal.dart';
import 'package:nutmeg/screens/RatePlayersModal.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../state/MatchesState.dart';

class BottomBarMatch extends StatelessWidget {
  static Widget? getBottomBar(
      BuildContext context, String matchId, MatchStatus? matchStatus) {
    // https://docs.google.com/document/d/1PpHh-8blyMYH7ePtU-XIBU289guZX847eBfHz_yqPJ0/edit#

    var match = context.read<MatchesState>().getMatch(matchId);

    if (match == null || matchStatus == null) return null;

    var isFull = match.isFull();
    var isGoing =
        match.isUserGoing(context.read<UserState>().getLoggedUserDetails());

    var bottomBar;

    switch (matchStatus) {
      case MatchStatus.open:
        if (isGoing) {
          bottomBar = LeaveMatchBottomBar(matchId: matchId, enabled: true);
        } else {
          bottomBar = JoinMatchBottomBar(matchId: matchId, enabled: !isFull);
        }
        break;
      case MatchStatus.pre_playing:
        if (isGoing) {
          bottomBar = LeaveMatchBottomBar(matchId: matchId, enabled: false);
        } else {
          bottomBar = JoinMatchBottomBar(matchId: matchId, enabled: !isFull);
        }
        break;
      case MatchStatus.playing:
        break;
      case MatchStatus.to_rate:
        if (isGoing) {
          var stillToVote = context.read<MatchesState>().getStillToVote(
              matchId, context.read<UserState>().currentUserId!);
          if (stillToVote != null && stillToVote.isNotEmpty)
            bottomBar = RatePlayersBottomBar(matchId: matchId);
        }
        break;
      case MatchStatus.rated:
        break;
      case MatchStatus.cancelled:
        break;
      case MatchStatus.unpublished:
        if (match.organizerId == context.read<UserState>().currentUserId)
          bottomBar = NotPublishedBottomBar(matchId: matchId);
    }

    return bottomBar;
  }

  final String matchId;
  final String text;
  final String? subText;
  final Widget? button;

  const BottomBarMatch(
      {Key? key,
      required this.matchId,
      required this.text,
      this.subText,
      this.button})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GenericBottomBar(
        child: Padding(
      padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(text, style: TextPalette.h2),
                SizedBox(
                  height: 4,
                ),
                if (subText != null)
                  Text(subText!, style: TextPalette.bodyText),
              ],
            ),
          ),
          if (button != null) button!
        ],
      ),
    ));
  }
}

class GenericBottomBar extends StatelessWidget {
  final Widget child;

  const GenericBottomBar({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Palette.white,
            boxShadow: [
              BoxShadow(
                color: Palette.black.withOpacity(0.05),
                spreadRadius: 0,
                blurRadius: 20,
                offset: Offset(0, -10),
              )
            ],
          ),
          child: SafeArea(
            minimum: EdgeInsets.only(bottom: 16),
            child: child,
          ),
        )
      ],
    );
  }
}

class JoinMatchBottomBar extends StatelessWidget {
  final String matchId;
  final bool enabled;

  const JoinMatchBottomBar(
      {Key? key, required this.matchId, required this.enabled})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var match = context.read<MatchesState>().getMatch(matchId);

    if (match == null) {
      return Container();
    }

    return BottomBarMatch(
        matchId: matchId,
        text: AppLocalizations.of(context)!.spotsLeft(match.getSpotsLeft()),
        subText: match.price != null
            ? formatCurrency(match.price!.getTotalPrice())
            : null,
        button: enabled ? JoinButton(matchId: matchId) : JoinButtonDisabled());
  }
}

class LeaveMatchBottomBar extends StatelessWidget {
  final String matchId;
  final bool enabled;

  const LeaveMatchBottomBar(
      {Key? key, required this.matchId, required this.enabled})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var match = context.read<MatchesState>().getMatch(matchId);

    return BottomBarMatch(
        matchId: matchId,
        text: AppLocalizations.of(context)!.joinMatchSuccessTitle,
        subText: AppLocalizations.of(context)!
            .joinMatchBarSubtitle(match!.getGoingPlayers()),
        button:
            enabled ? LeaveButton(matchId: matchId) : LeaveButtonDisabled());
  }
}

class RatePlayersBottomBar extends StatelessWidget {
  final String matchId;

  const RatePlayersBottomBar({Key? key, required this.matchId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomBarMatch(
        matchId: matchId,
        text: "Rate players",
        subText: context
                .watch<MatchesState>()
                .getStillToVote(
                    matchId, context.read<UserState>().currentUserId!)!
                .length
                .toString() +
            " players left",
        button: RateButton(matchId: matchId));
  }
}

class NotPublishedBottomBar extends StatelessWidget {
  final String matchId;

  const NotPublishedBottomBar({Key? key, required this.matchId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var userState = context.read<UserState>();

    return BottomBarMatch(
        matchId: matchId,
        text: "Not Published",
        subText:
            "Complete your Stripe account to receive payments and publish this match",
        button: InkWell(
            onTap: () => launchUrl(
                Uri.parse(getStripeUrl(
                    userState.isTestMode, userState.currentUserId!)),
                mode: LaunchMode.externalApplication),
            child: Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text("GO TO STRIPE", style: TextPalette.linkStyle))));
  }
}
