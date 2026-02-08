import 'package:flutter/material.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/screens/JoinModal.dart';
import 'package:nutmeg/screens/LeaveMatchModal.dart';
import 'package:nutmeg/screens/RatePlayersModal.dart';
import 'package:nutmeg/screens/WaitListModal.dart';
import 'package:nutmeg/state/MatchState.dart';
import 'package:nutmeg/state/UserRatings.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BottomBarMatch extends StatelessWidget {
  static Widget? getBottomBar(
      MatchState matchState, String matchId, MatchStatus? matchStatus) {
    // https://docs.google.com/document/d/1PpHh-8blyMYH7ePtU-XIBU289guZX847eBfHz_yqPJ0/edit#

    var match = matchState.match;

    if (match == null || matchStatus == null) return null;

    var isFull = match.isFull();
    var isGoing = matchState.isLoggedUserInMatch();

    var bottomBar;

    var isInWaitList = matchState.isLoggedUserInWaitList();

    switch (matchStatus) {
      case MatchStatus.open:
        if (isGoing) {
          bottomBar = LeaveMatchBottomBar(matchId: matchId, enabled: true);
        } else if (isInWaitList) {
          bottomBar = LeaveWaitListBottomBar(matchId: matchId);
        } else if (isFull) {
          bottomBar = JoinWaitListBottomBar(matchId: matchId);
        } else {
          bottomBar = JoinMatchBottomBar(matchId: matchId, enabled: true);
        }
        break;
      case MatchStatus.pre_playing:
        if (isGoing) {
          bottomBar = LeaveMatchBottomBar(matchId: matchId, enabled: false);
        } else if (isInWaitList) {
          bottomBar = LeaveWaitListBottomBar(matchId: matchId);
        } else if (isFull) {
          bottomBar = JoinWaitListBottomBar(matchId: matchId);
        } else {
          bottomBar = JoinMatchBottomBar(matchId: matchId, enabled: true);
        }
        break;
      case MatchStatus.playing:
        break;
      case MatchStatus.to_rate:
        if (isGoing) {
          bottomBar = RatePlayersBottomBar(matchId: matchId);
        }
        break;
      case MatchStatus.rated:
        break;
      case MatchStatus.cancelled:
        break;
      case MatchStatus.unpublished:
        if (matchState.isLoggedUserOrganizer())
          bottomBar =
              NotPublishedBottomBar(matchId: matchId, isTest: match.isTest);
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
    var match = context.watch<MatchState>().match;

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
    var match = context.watch<MatchState>().match;

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
    // Check if user has already provided ratings
    var userRatings = context.watch<UserRatings>();
    var match = context.watch<MatchState>().match;

    if (userRatings.isLoading || match == null) {
      return Container();
    }

    final hasRated = !userRatings.isEmpty();

    var hoursLeft = match.dateTime
        .add(Duration(days: 1))
        .difference(DateTime.now())
        .inHours;

    final text = hasRated
        ? AppLocalizations.of(context)!.ratePlayersThanksText
        : AppLocalizations.of(context)!.ratePlayersTitleText;
    final subText = (hoursLeft > 0)
        ? AppLocalizations.of(context)!.ratesCloseInText(hoursLeft.toString())
        : "";

    return BottomBarMatch(
        matchId: matchId,
        text: text,
        subText: subText,
        button: RateButton(matchId: matchId, hasRated: hasRated));
  }
}

class NotPublishedBottomBar extends StatelessWidget {
  final String matchId;
  final bool isTest;

  const NotPublishedBottomBar(
      {Key? key, required this.matchId, required this.isTest})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomBarMatch(
        matchId: matchId,
        text: "Not Published",
        subText:
            "Complete your Stripe account to receive payments and publish this match",
        button: InkWell(
            onTap: () =>
                completeAccountAction(context, isTest, matchId: matchId),
            child: Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text("GO TO STRIPE", style: TextPalette.linkStyle))));
  }
}
