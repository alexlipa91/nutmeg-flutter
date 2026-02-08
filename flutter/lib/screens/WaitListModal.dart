import 'package:flutter/material.dart';
import 'package:nutmeg/screens/BottomBarMatch.dart';
import 'package:nutmeg/screens/Login.dart';
import 'package:nutmeg/state/MatchState.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../state/UserState.dart';

class JoinWaitListButton extends StatelessWidget {
  final String matchId;

  const JoinWaitListButton({Key? key, required this.matchId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GenericButtonWithLoader(
      "JOIN WAITLIST",
      (BuildContext context) async {
        var loaderState = context.read<GenericButtonWithLoaderState>();
        loaderState.change(true);
        await WaitListModal.onJoinWaitListAction(context);
      },
      Secondary(),
    );
  }
}

class LeaveWaitListButton extends StatelessWidget {
  final String matchId;

  const LeaveWaitListButton({Key? key, required this.matchId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var matchState = context.read<MatchState>();

    return GenericButtonWithLoader(
      "LEAVE WAITLIST",
      (BuildContext context) async {
        await GenericInfoModal(
          title: "Leave Waitlist",
          description:
              "Are you sure you want to leave the waitlist for this match?",
          action: Row(children: [
            Expanded(
              child: ConfirmLeaveWaitListButton(matchState: matchState),
            )
          ]),
        ).show(context);
      },
      Secondary(),
    );
  }
}

class ConfirmLeaveWaitListButton extends StatelessWidget {
  final MatchState matchState;

  const ConfirmLeaveWaitListButton({Key? key, required this.matchState})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GenericButtonWithLoader(
      "CONFIRM",
      (BuildContext context) async {
        context.read<GenericButtonWithLoaderState>().change(true);
        await matchState.removeLoggedInUserFromWaitList();
        Navigator.of(context).pop(true);
      },
      Primary(),
    );
  }
}

class JoinWaitListBottomBar extends StatelessWidget {
  final String matchId;

  const JoinWaitListBottomBar({Key? key, required this.matchId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var match = context.watch<MatchState>().match;

    if (match == null) {
      return Container();
    }

    return BottomBarMatch(
      matchId: matchId,
      text: "Match is full",
      subText: match.numPlayersInWaitList() > 0
          ? "${match.numPlayersInWaitList()} in waitlist"
          : null,
      button: JoinWaitListButton(matchId: matchId),
    );
  }
}

class LeaveWaitListBottomBar extends StatelessWidget {
  final String matchId;

  const LeaveWaitListBottomBar({Key? key, required this.matchId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var match = context.watch<MatchState>().match;

    if (match == null) {
      return Container();
    }

    var position = 0;
    var userId =
        context.read<UserState>().getLoggedUserDetails()?.documentId ?? "";
    var waitListUsers = match.getWaitListUsersByTime();
    for (var i = 0; i < waitListUsers.length; i++) {
      if (waitListUsers[i] == userId) {
        position = i + 1;
        break;
      }
    }

    return BottomBarMatch(
      matchId: matchId,
      text: "You're on the waitlist",
      subText: position > 0 ? "Position #$position" : null,
      button: LeaveWaitListButton(matchId: matchId),
    );
  }
}

class WaitListModal {
  static Future<void> onJoinWaitListAction(BuildContext context) async {
    var userState = context.read<UserState>();
    var matchState = context.read<MatchState>();

    if (!userState.isLoggedIn()) {
      await Navigator.push(
          context, MaterialPageRoute(builder: (context) => Login()));
    }

    if (userState.isLoggedIn()) {
      await matchState.addLoggedInUserToWaitList();
    }
  }
}
