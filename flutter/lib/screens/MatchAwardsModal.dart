import 'package:flutter/material.dart';
import 'package:nutmeg/state/MatchesState.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/state/UserRatings.dart';
import 'package:nutmeg/state/UsersState.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/ModalBottomSheet.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MatchAwardsButton extends StatelessWidget {
  final String matchId;

  const MatchAwardsButton({Key? key, required this.matchId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GenericButtonWithLoader(
      "MATCH AWARDS",
      (BuildContext context) async {
        context.read<GenericButtonWithLoaderState>().change(true);
        await MatchAwardsModal.showModal(context, matchId);
        context.read<GenericButtonWithLoaderState>().change(false);
      },
      Primary(),
    );
  }
}

class MatchAwardsModal extends StatelessWidget {
  static Future<bool?> bestAwardAction(
      BuildContext context, String matchId, UserRatings userRatings) async {
    // Wait for both ratings and awards to be loaded
    await Future.wait(
        [userRatings.fetchRatings(matchId), userRatings.fetchAwards(matchId)]);

    return await ModalBottomSheet.showNutmegModalBottomSheet(
      context,
      ChangeNotifierProvider<UserRatings>.value(
        value: userRatings,
        child: MatchAwardsModal(matchId: matchId),
      ),
    );
  }

  final String matchId;

  const MatchAwardsModal({Key? key, required this.matchId}) : super(key: key);

  static Future<bool?> showModal(BuildContext context, String matchId) async {
    return await ModalBottomSheet.showNutmegModalBottomSheet(
      context,
      ChangeNotifierProvider(
        create: (context) => UserRatings(matchId),
        child: MatchAwardsModal(matchId: matchId),
      ),
    );
  }

  // Define awards with their icons and names
  static final List<Map<String, dynamic>> awards = [
    {
      'id': 'best_goal',
      'icon': 'assets/icons/icons8-soccer-ball-48.png',
      'name': (BuildContext context) =>
          AppLocalizations.of(context)!.bestGoalAwardName,
      'description': (BuildContext context) =>
          AppLocalizations.of(context)!.bestGoalAwardDesc
    },
    {
      'id': 'best_striker',
      'icon': 'assets/icons/icons8-ronaldo-48.png',
      'name': (BuildContext context) =>
          AppLocalizations.of(context)!.bestStrikerAwardName,
      'description': (BuildContext context) =>
          AppLocalizations.of(context)!.bestStrikerAwardDesc
    },
    {
      'id': 'best_goalkeeper',
      'icon': 'assets/icons/icons8-goalkeeper-with-net-48.png',
      'name': (BuildContext context) =>
          AppLocalizations.of(context)!.bestGoalkeeperAwardName,
      'description': (BuildContext context) =>
          AppLocalizations.of(context)!.bestGoalkeeperAwardDesc
    },
    {
      'id': 'best_defender',
      'icon': 'assets/icons/icons8-runners-crossing-finish-line-48.png',
      'name': (BuildContext context) =>
          AppLocalizations.of(context)!.bestDefenderAwardName,
      'description': (BuildContext context) =>
          AppLocalizations.of(context)!.bestDefenderAwardDesc
    },
  ];

  @override
  Widget build(BuildContext context) {
    final match = context.read<MatchesState>().getMatch(matchId);

    // Get all players except current user
    final currentUserId = context.read<UserState>().getLoggedUserId();
    final players =
        match.match?.going.keys.where((id) => id != currentUserId).toList();

    final l10n = AppLocalizations.of(context)!;
    final userRatings = context.watch<UserRatings>();

    return Section(
      topSpace: 0,
      titleType: "big",
      title: l10n.matchAwardsTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.matchAwardsSubtitle,
            style: TextPalette.bodyText,
          ),
          SizedBox(height: 24),
          ...awards
              .map((award) => Container(
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Palette.greyLighter),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              child: Image.asset(
                                award['icon'],
                                width: 20,
                                height: 20,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  award['name'](context),
                                  style: TextPalette.h3,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: userRatings.getAward(award['id']),
                                isExpanded: true,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Palette.greyLight),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Palette.greyLight),
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Text(l10n.selectPlayerText,
                                        style: TextPalette.bodyText,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1),
                                  ),
                                  ...players!.map((playerId) {
                                    final user = context
                                        .watch<UsersState>()
                                        .getUserDetail(playerId);
                                    return DropdownMenuItem<String>(
                                      value: playerId,
                                      child: Row(
                                        children: [
                                          UserAvatar(10, user),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              user?.name ?? 'Unknown',
                                              style: TextPalette.bodyText,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                                onChanged: (String? value) {
                                  userRatings.setAward(award['id'], value);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ))
              .toList(),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GenericButtonWithLoaderAndErrorHandling(
                  l10n.submitRatesButtonText,
                  (BuildContext context) async {
                    userRatings.postAwards();
                    Navigator.of(context).pop(true);
                  },
                  Primary(),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
