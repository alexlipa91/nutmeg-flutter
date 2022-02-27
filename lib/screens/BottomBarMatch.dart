import 'package:flutter/material.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/screens/JoinModal.dart';
import 'package:nutmeg/screens/LeaveMatchModal.dart';
import 'package:nutmeg/screens/RatePlayersModal.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';

class BottomBarMatch extends StatelessWidget {
  final Match match;

  const BottomBarMatch({Key key, this.match}) : super(key: key);

  String getText(MatchStatusForUser matchStatusForUser) {
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

  String getSubText(MatchStatusForUser matchStatusForUser,
      UserState userState) {
    switch (matchStatusForUser) {
      case MatchStatusForUser.join:
        return formatCurrency(match.pricePerPersonInCents);
      case MatchStatusForUser.leave:
        return match.going.length.toString() + " players going";
      case MatchStatusForUser.full:
        return match.going.length.toString() + " players going";
      case MatchStatusForUser.canceled:
        return ""; break;
      case MatchStatusForUser.to_rate:
        return userState.getUsersStillToRate(match.documentId).length.toString()
            + " players to rate";
      case MatchStatusForUser.no_more_to_rate:
        return "Man of the match will be published soon";
      case MatchStatusForUser.rated:
        return UsersState.getUserDetails(match.manOfTheMatch).name
            + " with a score of "
            + match.manOfTheMatchScore.toString() + "/5";
    }
  }

  Widget getButton(MatchStatusForUser matchStatusForUser,
      UserState userState) {
    switch (matchStatusForUser) {
      case MatchStatusForUser.join:
        return JoinButton(match: match);
      case MatchStatusForUser.leave:
        return LeaveButton(match: match);
      case MatchStatusForUser.full:
        return JoinButtonDisabled();
      case MatchStatusForUser.canceled:
        return JoinButtonDisabled();
      case MatchStatusForUser.to_rate:
        return RateButton(match: match);
      case MatchStatusForUser.no_more_to_rate:
        return Container();
      case MatchStatusForUser.rated:
        return UserAvatar(20.0, UsersState.getUserDetails(match.manOfTheMatch));
    }
  }

  @override
  Widget build(BuildContext context) {
    var status = context.watch<MatchesState>().getMatchStatus(match.documentId);
    print("match status is " + status.toString());

    if (status == null) {
      return Container();
    }

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
                bottom: 16.0 + MediaQuery.of(context).padding.bottom),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(getText(status), style: TextPalette.h2),
                      SizedBox(
                        height: 4,
                      ),
                      Text(getSubText(status, context.watch<UserState>()),
                          style: TextPalette.bodyText),
                    ],
                  ),
                ),
                Container(child: getButton(status, context.read<UserState>()))
              ],
            ),
          ),
        )
      ],
    );
  }
}

class RatePlayersBottomBar extends StatelessWidget {
  final Match match;
  final List<UserDetails> users;
  final double extraBottomPadding;

  const RatePlayersBottomBar(
      {Key key, this.match, this.users, this.extraBottomPadding})
      : super(key: key);

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
                bottom: 16.0 + extraBottomPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Rate players"),
                      SizedBox(
                        height: 4,
                      ),
                      Text(users.length.toString() + " players left to rate",
                          style: TextPalette.bodyText),
                    ],
                  ),
                ),
                Container(
                    child: GenericButtonWithLoader("RATE PLAYERS",
                        (BuildContext context) async {
                  await showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) =>
                          RatingPlayerBottomModal(
                            userDetails: users,
                            matchId: match.documentId,
                          ));
                  context.read<GenericButtonWithLoaderState>().change(false);
                }, Primary()))
              ],
            ),
          ),
        )
      ],
    );
  }
}
