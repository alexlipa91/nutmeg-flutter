import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/state/UsersState.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/ModalBottomSheet.dart';
import 'package:provider/provider.dart';
import 'package:nutmeg/l10n/app_localizations.dart';

class UserAwardsReceivedList extends StatelessWidget {
  final Map<String, Map<String, int>>
      awards; // awardId -> userId -> number of votes
  final int distinctVoters;

  static const int _maxVisibleAwards = 2;

  const UserAwardsReceivedList(
      {Key? key, required this.awards, required this.distinctVoters})
      : super(key: key);

  static List<Map<String, String>> _getAwardTypes(AppLocalizations l10n) => [
        {
          'id': 'best_goal',
          'icon': 'assets/icons/icons8-soccer-ball-48.png',
          'label': l10n.bestGoalAwardName,
        },
        {
          'id': 'best_striker',
          'icon': 'assets/icons/icons8-ronaldo-48.png',
          'label': l10n.bestStrikerAwardName,
        },
        {
          'id': 'best_goalkeeper',
          'icon': 'assets/icons/icons8-goalkeeper-with-net-48.png',
          'label': l10n.bestGoalkeeperAwardName,
        },
        {
          'id': 'best_defender',
          'icon': 'assets/icons/icons8-runners-crossing-finish-line-48.png',
          'label': l10n.bestDefenderAwardName,
        },
      ];

  static Widget _buildAwardCard(
    BuildContext context,
    Map<String, String> award,
    Map<String, int> userVotes,
    UsersState usersState,
    AppLocalizations l10n,
    bool showVotesHeader,
  ) {
    final sortedVotes = userVotes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sortedVotes.isEmpty) return const SizedBox.shrink();

    int maxVotes = sortedVotes.first.value;
    int numWinners =
        sortedVotes.where((e) => e.value == maxVotes).length;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.greyLighter, width: 1),
        boxShadow: [
          BoxShadow(
            color: Palette.greyLightest,
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Center(
                    child: Image.asset(award['icon']!, width: 32, height: 32),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    award['label']!,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showVotesHeader)
                  Text(
                    l10n.votes,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.4),
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...sortedVotes.asMap().entries.map((entryWithIndex) {
              final index = entryWithIndex.key;
              final entry = entryWithIndex.value;
              final user = usersState.getUserDetail(entry.key);
              final isWinner = index == 0 &&
                  entry.value == maxVotes &&
                  numWinners == 1;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Container(
                  decoration: isWinner
                      ? BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        )
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Center(child: UserAvatar(20, user)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user?.name ?? 'Unknown',
                            style: TextPalette.bodyText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text('${entry.value}', style: TextPalette.bodyText),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersState = context.watch<UsersState>();
    final l10n = AppLocalizations.of(context)!;
    final awardTypes = _getAwardTypes(l10n);

    // Filter to only awards that have votes
    final visibleAwards = awardTypes.where((award) {
      final userVotes = awards[award['id']] ?? {};
      return userVotes.isNotEmpty;
    }).toList();

    final hasMore = visibleAwards.length > _maxVisibleAwards;
    final displayedAwards =
        hasMore ? visibleAwards.take(_maxVisibleAwards).toList() : visibleAwards;

    return InfoContainerWithTitleAndSubtitle(
      subtitle: l10n.matchStatsSubTitle(distinctVoters),
      title: l10n.matchAwardsTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < displayedAwards.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _buildAwardCard(
              context,
              displayedAwards[i],
              awards[displayedAwards[i]['id']] ?? {},
              usersState,
              l10n,
              i == 0,
            ),
          ],
          if (hasMore)
            InkWell(
              onTap: () {
                ModalBottomSheet.showNutmegModalBottomSheet(
                  context,
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(l10n.matchAwardsTitle, style: TextPalette.h2),
                      ),
                      for (int i = 0; i < visibleAwards.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _buildAwardCard(
                            context,
                            visibleAwards[i],
                            awards[visibleAwards[i]['id']] ?? {},
                            usersState,
                            l10n,
                            i == 0,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Palette.greyDark,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
