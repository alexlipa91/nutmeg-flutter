import 'package:flutter/material.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/state/MatchesState.dart';
import 'package:nutmeg/state/RatingPlayersState.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';

import '../model/UserDetails.dart';
import '../rating_bar/RatingWidget.dart';
import '../widgets/PlayerBottomModal.dart';
import '../widgets/Texts.dart';

class RateButton extends StatelessWidget {
  final String matchId;

  const RateButton({Key key, this.matchId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GenericButtonWithLoader("RATE PLAYERS",
        (BuildContext context) async {
      context.read<GenericButtonWithLoaderState>().change(true);
      await RatePlayerBottomModal.rateAction(context, matchId);
      context.read<GenericButtonWithLoaderState>().change(false);
    }, Primary());
  }
}

class RatePlayerBottomModal extends StatelessWidget {
  static Future<void> rateAction(BuildContext context, String matchId) async {
    var match = context.read<MatchesState>().getMatch(matchId);

    List<UserDetails> users =
        (await UserController.getUsersToRateInMatchForLoggedUser(
                context, match.documentId))
            .toList();

    await showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        builder: (BuildContext context) => MultiProvider(
              providers: [
                ChangeNotifierProvider(
                    create: (context) => RatingPlayersState(users)),
              ],
              child: RatePlayerBottomModal(matchId),
            ));
    await MatchesController.refresh(context, matchId);
  }

  final String matchId;

  RatePlayerBottomModal(this.matchId);

  String _getName(BuildContext context) {
    var parts = UserDetails.getDisplayName(
            context.watch<RatingPlayersState>().getCurrent())
        .split(" ");
    return parts.first;
  }

  @override
  Widget build(BuildContext context) {
    var state = context.watch<RatingPlayersState>();
    var match = context.read<MatchesState>().getMatch(matchId);

    var alreadyRated = match.numPlayersGoing() - state.toRate.length;

    return PlayerBottomModal(
        state.getCurrent(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              SizedBox(height: 65),
              Text("How was " + _getName(context) + "'s performance?",
                  style: TextPalette.h2),
              SizedBox(height: 2),
              Text(_getName(context) + " won't see your score",
                  style: TextPalette.bodyText),
              SizedBox(height: 24),
              RatingBar(),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // trick for alignemnt
                  Text("ABCD", style: TextPalette.getLinkStyle(Palette.white)),
                  Container(
                    height: 40, // align to tappable area
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                          (alreadyRated + state.current).toString() +
                              "/" +
                              (match.numPlayersGoing() - 1).toString() +
                              " players",
                          style: TextPalette.getBodyText(Palette.black)),
                    ),
                  ),
                  TappableLinkText(
                      text: (state.currentScore > 0) ? "NEXT" : "SKIP",
                      onTap: (BuildContext context) async {
                        store(context);
                      }),
                ],
              ),
              SizedBox(height: 16),
            ],
          ),
        ));
  }

  Future<void> store(BuildContext context) async {
    var state = context.read<RatingPlayersState>();

    if (state.getCurrent() != null) {
      MatchesController.addRating(context, state.getCurrent().documentId,
          matchId, state.getCurrentScore());
    }

    if (state.isLast()) {
      Navigator.pop(context);
    } else {
      state.next();
    }
  }
}
