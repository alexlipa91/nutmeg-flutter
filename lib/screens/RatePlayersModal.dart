import 'package:flutter/material.dart';
import 'package:nutmeg/screens/MatchAwardsModal.dart';
import 'package:nutmeg/state/MatchesState.dart';
import 'package:nutmeg/state/UserRatings.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/state/UsersState.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/ModalBottomSheet.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../rating_bar/RatingWidget.dart';
import '../widgets/Avatar.dart';
import 'MatchDetails.dart';

class RateButton extends StatelessWidget {
  final String matchId;
  final bool hasRated;

  const RateButton({Key? key, required this.matchId, required this.hasRated})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GenericButtonWithLoader(
        hasRated
            ? AppLocalizations.of(context)!.updateRatesPlayersButtonText
            : AppLocalizations.of(context)!.ratePlayersButtonText,
        (BuildContext context) async {
      context.read<GenericButtonWithLoaderState>().change(true);
      await rateAction(context, matchId);
      context.read<GenericButtonWithLoaderState>().change(false);
    }, Primary());
  }
}

Future<void> rateAction(BuildContext context, String matchId) async {
  bool userDismissedRateAction = false;

  // Get the existing UserRatings state from MatchDetails
  var userRatings = context.read<UserRatings>();

  bool completed = await ModalBottomSheet.showNutmegModalBottomSheet(
          context,
          ChangeNotifierProvider.value(
            value: userRatings,
            child: RatePlayerSingleSheet(matchId: matchId),
          )) ??
      false;

  userDismissedRateAction = !completed;

  if (!userDismissedRateAction) {
    // Create a new UserRatings instance for the awards modal
    var awardsUserRatings = UserRatings(matchId);
    // Copy the ratings from the previous instance
    awardsUserRatings.copyFrom(userRatings);
    await MatchAwardsModal.bestAwardAction(context, matchId, awardsUserRatings);
  }
}

class RatePlayerSingleSheet extends StatelessWidget {
  final String matchId;

  const RatePlayerSingleSheet({Key? key, required this.matchId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var usersToRate =
        context.watch<MatchesState>().getMatch(matchId)!.getUsersToRate();

    return Section(
        topSpace: 0,
        titleType: "big",
        title: AppLocalizations.of(context)!.ratePlayersTitle,
        body: Column(
          children: [
            SizedBox(height: 16),
            Column(
                children: interleave(
                    usersToRate
                        .asMap()
                        .entries
                        .map((e) => Row(
                              children: [
                                UserAvatar(
                                    16,
                                    context
                                        .watch<UsersState>()
                                        .getUserDetail(e.value)),
                                SizedBox(
                                  width: 16,
                                ),
                                UserNameWidget(
                                    userDetails: context
                                        .watch<UsersState>()
                                        .getUserDetail(e.value)),
                                Spacer(),
                                RatingBar(userId: e.value)
                              ],
                            ))
                        .toList(),
                    SizedBox(
                      height: 18,
                    ))),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GenericButtonWithLoaderAndErrorHandling(
                      AppLocalizations.of(context)!.submitRatesButtonText,
                      (BuildContext context) {
                    context.read<UserRatings>().postRatings();
                    Navigator.of(context).pop(true);
                  }, Primary()),
                )
              ],
            ),
          ],
        ));
  }
}
