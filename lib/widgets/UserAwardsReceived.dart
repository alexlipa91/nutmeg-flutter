import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/state/UsersState.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class UserAwardsReceivedList extends StatelessWidget {
  final Map<String, Map<String, int>> awards; // awardId -> userId -> number of votes

  const UserAwardsReceivedList({Key? key, required this.awards}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final usersState = context.watch<UsersState>();
    final l10n = AppLocalizations.of(context)!;

    // Award metadata
    final awardTypes = [
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

    return InfoContainerWithTitle(
      title: l10n.matchAwardsTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < awardTypes.length; i++) ...[
            if (i > 0)
              Divider(height: 24, thickness: 1, color: Palette.greyLighter),
            (() {
              final award = awardTypes[i];
              final awardId = award['id']!;
              final userVotes = awards[awardId] ?? {};
              final sortedVotes = userVotes.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              if (sortedVotes.isEmpty) return SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(award['icon']!, width: 32, height: 32),
                        const SizedBox(width: 8),
                        Text(award['label']!, style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...(() {
                      // Find if there is a single winner
                      int maxVotes = sortedVotes.isNotEmpty ? sortedVotes.first.value : 0;
                      int numWinners = sortedVotes.where((e) => e.value == maxVotes).length;
                      return sortedVotes.asMap().entries.map((entryWithIndex) {
                        final index = entryWithIndex.key;
                        final entry = entryWithIndex.value;
                        final user = usersState.getUserDetail(entry.key);
                        final isWinner = index == 0 && sortedVotes.isNotEmpty && entry.value == maxVotes && numWinners == 1;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Container(
                            decoration: isWinner
                                ? BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  )
                                : null,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    '${entry.value}',
                                    textAlign: TextAlign.right,
                                    style: TextPalette.bodyText,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Row(
                                  children: [
                                    UserAvatar(14, user),
                                    const SizedBox(width: 8),
                                    Text(user?.name ?? 'Unknown', style: TextPalette.bodyText),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      });
                    })(),
                  ],
                ),
              );
            })(),
          ]
        ].where((widget) => widget is! SizedBox).toList(),
      ),
    );
  }
}