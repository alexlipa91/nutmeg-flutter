import 'package:flutter/material.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/screens/JoinModal.dart';
import 'package:nutmeg/screens/LeaveMatchModal.dart';
import 'package:nutmeg/screens/RatePlayersModal.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:provider/provider.dart';

import '../controller/MatchesController.dart';
import '../state/MatchesState.dart';

class BottomBarMatch extends StatelessWidget {
  final String matchId;

  const BottomBarMatch({Key key, this.matchId}) : super(key: key);

  String getText(Match match, MatchStatusForUser matchStatusForUser) {
    if (match.status == MatchStatus.canceled) {
      return "Cancelled";
    }
    if (match.status == MatchStatus.open) {
      if (matchStatusForUser == MatchStatusForUser.canJoin) {
        return match.getSpotsLeft().toString() + " spots left";
      }
      if (matchStatusForUser == MatchStatusForUser.canLeave) {
        return "You are in";
      }
      throw Exception("Unexpected");
    }
    if (match.status == MatchStatus.to_rate) {
      if (matchStatusForUser == MatchStatusForUser.to_rate) {
        return "Rate Players";
      }
      throw Exception("Unexpected");
    }
    throw Exception("Unexpected");
  }

  Widget getSubText(Match match, MatchStatusForUser matchStatusForUser,
      BuildContext context) {
    if (match == null) return Container();

    if (match.status == MatchStatus.canceled) {
      return Container();
    }
    if (match.status == MatchStatus.open) {
      if (matchStatusForUser == MatchStatusForUser.canJoin) {
        return Text(formatCurrency(match.pricePerPersonInCents),
            style: TextPalette.bodyText);
      }
      if (matchStatusForUser == MatchStatusForUser.canLeave) {
        return Text(match.going.length.toString() + " players going",
            style: TextPalette.bodyText);
      }
      throw Exception("Unexpected");
    }
    if (match.status == MatchStatus.to_rate) {
      if (matchStatusForUser == MatchStatusForUser.to_rate) {
        return Text(
            context
                    .watch<MatchesState>()
                    .stillToVote(matchId,
                        context.read<UserState>().getLoggedUserDetails())
                    .length
                    .toString() +
                " players left",
            style: TextPalette.bodyText);
      }
      throw Exception("Unexpected");
    }
    throw Exception("Unexpected");
  }

  Widget getButton(Match match, MatchStatusForUser matchStatusForUser,
      BuildContext context) {
    if (matchStatusForUser == MatchStatusForUser.canJoin) {
      return JoinButton(matchId: match.documentId);
    }
    if (matchStatusForUser == MatchStatusForUser.canLeave) {
      return LeaveButton(matchId: matchId);
    }
    if (matchStatusForUser == MatchStatusForUser.cannotJoin) {
      return JoinButtonDisabled();
    }
    if (matchStatusForUser == MatchStatusForUser.to_rate) {
      return RateButton(matchId: matchId);
    }
    throw Exception("Unexpected");
  }

  @override
  Widget build(BuildContext context) {
    var matchesState = context.watch<MatchesState>();

    var match = matchesState.getMatch(matchId);
    var statusForUser = context.watch<MatchesState>().getMatchStatusForUser(
        matchId, context.watch<UserState>().getLoggedUserDetails());

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
                Text(getText(match, statusForUser), style: TextPalette.h2),
                SizedBox(
                  height: 4,
                ),
                getSubText(match, statusForUser, context),
              ],
            ),
          ),
          Container(child: getButton(match, statusForUser, context))
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
