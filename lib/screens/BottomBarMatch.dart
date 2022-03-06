import 'package:flutter/material.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/screens/JoinModal.dart';
import 'package:nutmeg/screens/LeaveMatchModal.dart';
import 'package:nutmeg/screens/RatePlayersModal.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:provider/provider.dart';

import '../model/UserDetails.dart';
import '../state/MatchesState.dart';


class BottomBarMatch extends StatelessWidget {
  final String matchId;
  final double extraBottomPadding;

  const BottomBarMatch({Key key, this.matchId, this.extraBottomPadding}) : super(key: key);

  String getText(Match match, MatchStatusForUser matchStatusForUser) {
    switch (matchStatusForUser) {
      case MatchStatusForUser.join:
        return match.getSpotsLeft().toString() + " spots left";
      case MatchStatusForUser.leave:
        return "You are in";
      case MatchStatusForUser.full:
        return "Match Full";
      case MatchStatusForUser.canceled:
        return "Cancelled";
      case MatchStatusForUser.to_rate:
        return "Rate Players";
      case MatchStatusForUser.no_more_to_rate:
        return "Thanks for rating";
      case MatchStatusForUser.rated:
        return "Man of the Match";
    }
  }

  Widget getSubText(Match match, MatchStatusForUser matchStatusForUser,
      BuildContext context) {
    var matchesState = context.watch<MatchesState>();

    switch (matchStatusForUser) {
      case MatchStatusForUser.join:
        return Text(formatCurrency(match.pricePerPersonInCents),
            style: TextPalette.bodyText);
      case MatchStatusForUser.leave:
        return Text(match.going.length.toString() + " players going",
            style: TextPalette.bodyText);
      case MatchStatusForUser.full:
        return Text(match.going.length.toString() + " players going",
            style: TextPalette.bodyText);
      case MatchStatusForUser.canceled:
        return Container();
      case MatchStatusForUser.to_rate:
        return Text(matchesState.getUsersToRate(match.documentId).length.toString()
            + " players left", style: TextPalette.bodyText);
      case MatchStatusForUser.no_more_to_rate:
        return Text("Man of the match will be published soon",
            style: TextPalette.bodyText);
      case MatchStatusForUser.rated:
        return FutureBuilder<UserDetails>(
            future: UserController.getUserDetails(context, match.manOfTheMatch),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(snapshot.data.name + " with a score of "
                    + match.manOfTheMatchScore.toString() + "/5");
              }
              return Container();
            });
    }
  }

  Widget getButton(Match match, MatchStatusForUser matchStatusForUser,
      BuildContext context) {
    switch (matchStatusForUser) {
      case MatchStatusForUser.join:
        return JoinButton(matchId: match.documentId);
      case MatchStatusForUser.leave:
        return LeaveButton(matchId: matchId);
      case MatchStatusForUser.full:
        return JoinButtonDisabled();
      case MatchStatusForUser.canceled:
        return JoinButtonDisabled();
      case MatchStatusForUser.to_rate:
        return RateButton(matchId: matchId);
      case MatchStatusForUser.no_more_to_rate:
        return Container();
      case MatchStatusForUser.rated:
        return FutureBuilder(
            future: UserController.getUserDetails(context, match.manOfTheMatch),
            builder: (context, snapshot) => (snapshot.hasData) ?
            UserAvatar(20.0, snapshot.data) : Container());
    }
  }

  @override
  Widget build(BuildContext context) {
    var matchesState = context.watch<MatchesState>();

    var match = matchesState.getMatch(matchId);
    var status = matchesState.getMatchStatus(matchId);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Palette.white,
            boxShadow: [
              BoxShadow(
                color: Palette.black.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 20,
                offset: Offset(0, 10),
              )
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(getText(match, status), style: TextPalette.h2),
                      SizedBox(
                        height: 4,
                      ),
                      getSubText(match, status, context),
                    ],
                  ),
                ),
                Container(child: getButton(match, status, context))
              ],
            ),
          ),
        )
      ],
    );
  }
}

