import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/state/MatchesState.dart';
import 'package:nutmeg/state/RatingPlayersState.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/ModalBottomSheet.dart';
import 'package:provider/provider.dart';

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
  static Future<bool> rateAction(BuildContext context, String matchId) async {
    var toRate = context
        .read<MatchesState>()
        .stillToVote(matchId, context.read<UserState>().getLoggedUserDetails());

    toRate.map((e) => UserController.getUserDetails(context, e));

    return await ModalBottomSheet.showNutmegModalBottomSheet(
        context,
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
                create: (context) => RatingPlayersState(toRate)),
          ],
          child: RatePlayerBottomModal(matchId),
        ));
    // don't refresh the status here because the last rating might have not yet propagated; instead leave RatePlayerBottomModal modify it if necessary
  }

  final String matchId;

  RatePlayerBottomModal(this.matchId);

  @override
  Widget build(BuildContext context) {
    var state = context.watch<RatingPlayersState>();
    var match = context.read<MatchesState>().getMatch(matchId);

    var alreadyRated = match.numPlayersGoing() - state.toRate.length;

    var current = context.watch<UserState>().getUserDetail(state.getCurrent());

    var nameParts = (current == null) ? null : current.name.split(" ");
    var name = (nameParts == null) ? null : nameParts.first;

    return PlayerBottomModal(
        current,
        Column(
          children: [
            RatingBar(),
            SizedBox(height: 12),
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
          ],
        ),
        (name == null) ? null : "How was " + name + "'s performance?",
        (name == null) ? null : name + " won't see your score");
  }

  Future<void> store(BuildContext context) async {
    var state = context.read<RatingPlayersState>();

    if (state.getCurrent() == null) {
      return;
    }

    MatchesController.addRating(context, state.getCurrent(), matchId,
        state.getCurrentScore());

    if (state.isLast()) {
      if (state.current + 1 == state.toRate.length) {
        // here we know for sure that there are no more players to rate. We quickly set the state so the bottom bar changes fast
        Get.back(result: true);
      } else {
        Get.back();
      }
    } else {
      state.next();
    }
  }
}
