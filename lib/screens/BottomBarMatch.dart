import 'package:flutter/material.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/screens/JoinModal.dart';
import 'package:nutmeg/screens/LeaveMatchModal.dart';
import 'package:nutmeg/screens/RatePlayersModal.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:provider/provider.dart';

import '../state/MatchesState.dart';

class BottomBarMatch extends StatelessWidget {

  static Widget getBottomBar(BuildContext context, String matchId,
      MatchStatus matchStatus) {
    // https://docs.google.com/document/d/1PpHh-8blyMYH7ePtU-XIBU289guZX847eBfHz_yqPJ0/edit#

    var match = context.read<MatchesState>().getMatch(matchId);

    if (match == null)
      return null;

    var isFull = match.isFull();
    var isGoing = match.isUserGoing(context.read<UserState>().getLoggedUserDetails());

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
        var stillToVote = context.read<MatchesState>()
            .stillToVote(matchId, context.read<UserState>().getLoggedUserDetails());
        if (isGoing && stillToVote.isNotEmpty)
          bottomBar = RatePlayersBottomBar(matchId: matchId);
        break;
      case MatchStatus.rated:
        break;
      case MatchStatus.cancelled:
        bottomBar = MatchCanceledBottomBar(matchId: matchId);
        break;
      case MatchStatus.unpublished:
        bottomBar = NotPublishedBottomBar(matchId: matchId);
    }

    return bottomBar;
  }

  final String matchId;
  final String text;
  final String subText;
  final Widget button;

  const BottomBarMatch({Key key, this.matchId, this.text, this.subText, this.button}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GenericBottomBar(
        child: Padding(
      padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
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
                  Text(subText, style: TextPalette.bodyText),
              ],
            ),
          ),
          if (button != null)
            button
        ],
      ),
    ));
  }
}

class GenericBottomBar extends StatelessWidget {
  final Widget child;

  const GenericBottomBar({Key key, this.child}) : super(key: key);

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

class MatchCanceledBottomBar extends StatelessWidget {

  final String matchId;

  const MatchCanceledBottomBar({Key key, this.matchId}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      BottomBarMatch(matchId: matchId, text: "Cancelled");
}

class JoinMatchBottomBar extends StatelessWidget {

  final String matchId;
  final bool enabled;

  const JoinMatchBottomBar({Key key, this.matchId, this.enabled}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var match = context.read<MatchesState>().getMatch(matchId);

    return BottomBarMatch(matchId: matchId,
      text: match.getSpotsLeft().toString() + " spots left",
      subText: formatCurrency(match.pricePerPersonInCents),
      button: enabled ? JoinButton(matchId: matchId) : JoinButtonDisabled()
    );
  }
}

class LeaveMatchBottomBar extends StatelessWidget {

  final String matchId;
  final bool enabled;

  const LeaveMatchBottomBar({Key key, this.matchId, this.enabled}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var match = context.read<MatchesState>().getMatch(matchId);

    return BottomBarMatch(matchId: matchId,
        text: "You are in!",
        subText: match.going.length.toString() + " players going",
        button: enabled ? LeaveButton(matchId: matchId) : LeaveButtonDisabled()
    );
  }
}

class RatePlayersBottomBar extends StatelessWidget {

  final String matchId;

  const RatePlayersBottomBar({Key key, this.matchId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomBarMatch(matchId: matchId,
        text: "Rate players",
        subText: context.watch<MatchesState>().stillToVote(
            matchId,
            context.read<UserState>().getLoggedUserDetails()).length.toString() +
        " players left",
        button:  RateButton(matchId: matchId)
    );
  }
}

class NotPublishedBottomBar extends StatelessWidget {

  final String matchId;

  const NotPublishedBottomBar({Key key, this.matchId}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      BottomBarMatch(matchId: matchId,
          text: "Not Published",
          subText: "Complete your Stripe account"
      );
}
