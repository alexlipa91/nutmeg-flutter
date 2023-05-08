import 'package:flutter/material.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/rating_bar/RatingWidgetForMulti.dart';
import 'package:nutmeg/state/MatchesState.dart';
import 'package:nutmeg/state/RatingPlayersState.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/FeedbackBottomModal.dart';
import 'package:nutmeg/widgets/ModalBottomSheet.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../model/MatchRatings.dart';
import '../rating_bar/RatingWidget.dart';
import '../widgets/Avatar.dart';
import '../widgets/PlayerBottomModal.dart';
import '../widgets/Texts.dart';
import 'MatchDetails.dart';

class RateButton extends StatelessWidget {
  final String matchId;

  const RateButton({Key? key, required this.matchId}) : super(key: key);

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
  static bool multiPage = false;

  static Future<bool?> rateAction(BuildContext context, String matchId) async {
    var completed;
    if (multiPage) {
      var toRate = context
          .read<MatchesState>()
          .getStillToVote(matchId, context.read<UserState>().currentUserId!)!;

      toRate.forEach((e) => context.read<UserState>().getOrFetch(e));

      completed = await ModalBottomSheet.showNutmegModalBottomSheet(
          context,
          MultiProvider(
            providers: [
              ChangeNotifierProvider(
                  create: (context) => RatingPlayersState(toRate)),
            ],
            child: RatePlayerBottomModal(matchId),
          ));
      // if (completed != null && (completed as bool) == true)
      //   await FeedbackBottomModal.feedbackAction(context);
      // don't refresh the status here because the last rating might have not yet propagated; instead leave RatePlayerBottomModal modify it if necessary
    } else {
      completed = await ModalBottomSheet.showNutmegModalBottomSheet(
          context,
          MultiProvider(providers: [
            ChangeNotifierProvider(
                create: (context) => RatingPlayersMultiState(context
                    .read<MatchesState>()
                    .getMatch(matchId)!
                    .getToRate(context.read<UserState>().currentUserId!))),
          ], child: RatePlayerSingleSheet(matchId: matchId)));
    }
    return completed;
  }

  final String matchId;

  RatePlayerBottomModal(this.matchId);

  List<Widget> _getSkillsButtons(BuildContext context) => Skills.values
      .map(
        (s) => GenericButtonWithLoader(s.name, (BuildContext context) {
          var ratingsState = context.read<RatingPlayersState>();

          if (ratingsState.selectedSkills.contains(s))
            ratingsState.unselectSkill(s);
          else
            ratingsState.selectSkill(s);
        },
            context.watch<RatingPlayersState>().selectedSkills.contains(s)
                ? Primary()
                : Secondary()),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    var state = context.watch<RatingPlayersState>();
    var match = context.read<MatchesState>().getMatch(matchId);

    var alreadyRated = match!.numPlayersGoing() - state.toRate.length;

    var current = context.watch<UserState>().getUserDetail(state.getCurrent());

    // user data might still have to be loaded; in that case we wait
    if (current == null) return Container();

    var nameParts = current.name?.split(" ");
    var name = (nameParts == null) ? null : nameParts.first;

    bool showSkillsArea =
        context.watch<RatingPlayersState>().currentScore != -1;

    return PlayerBottomModal(
        current,
        Column(children: [
          RatingBar(),
          AnimatedSize(
            duration: Duration(milliseconds: 500),
            curve: Curves.fastOutSlowIn,
            child: Container(
              height: showSkillsArea ? null : 0,
              child: Column(
                children: [
                  SizedBox(height: 24),
                  Text("Select $name top skills",
                      style: TextPalette.getBodyText(Palette.greyDark)),
                  SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: _getSkillsButtons(context),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // trick for alignment
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
                  text: (state.currentScore > 0)
                      ? AppLocalizations.of(context)!.nextText
                      : AppLocalizations.of(context)!.skipText,
                  onTap: (BuildContext context) async {
                    store(context);
                  }),
            ],
          ),
        ]),
        (name == null) ? null : "How was " + name + "'s performance?",
        (name == null) ? null : name + " won't see your score");
  }

  Future<void> store(BuildContext context) async {
    var state = context.read<RatingPlayersState>();

    MatchesController.pushAddRating(context, state.getCurrent(), matchId,
        state.getCurrentScore(), state.selectedSkills);

    // store also locally so UI changes fast
    context.read<MatchesState>().hasVoted(
        matchId, context.read<UserState>().currentUserId!, state.getCurrent());

    if (state.isLast()) {
      Navigator.of(context).pop(true);
    } else {
      state.next();
    }
  }
}

class RatePlayerSingleSheet extends StatelessWidget {
  final String matchId;

  const RatePlayerSingleSheet({Key? key, required this.matchId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Section(
        topSpace: 0,
        titleType: "big",
        title: AppLocalizations.of(context)!.ratePlayersTitle,
        body: Column(
          children: [
            SizedBox(height: 16),
            Column(
                children: interleave(
                    context
                        .watch<RatingPlayersMultiState>()
                        .toRate
                        .asMap()
                        .entries
                        .map((e) => Row(
                              children: [
                                UserAvatar(
                                    16,
                                    context
                                        .watch<UserState>()
                                        .getUserDetail(e.value)),
                                SizedBox(
                                  width: 16,
                                ),
                                UserNameWidget(
                                    userDetails: context
                                        .watch<UserState>()
                                        .getUserDetail(e.value)),
                                Spacer(),
                                RatingBarForMulti(i: e.key)
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
                      (BuildContext context) async {
                    await CloudFunctionsClient().post(
                        "matches/$matchId/ratings/add_multi",
                        context.read<RatingPlayersMultiState>().getScored());
                    await context.read<MatchesState>().fetchStillToVote(matchId,
                        context.read<UserState>().currentUserId!);
                    Navigator.of(context).pop(true);
                  }, Primary()),
                )
              ],
            ),
          ],
        ));
  }
}
