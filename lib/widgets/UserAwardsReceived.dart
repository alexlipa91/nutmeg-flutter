import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/state/UsersState.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class UserAwardsReceivedList extends StatelessWidget {
  final Map<String, Map<String, int>>
      awards; // awardId -> userId -> number of votes

  const UserAwardsReceivedList({Key? key, required this.awards})
      : super(key: key);

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

    // Compute the number of distinct voters
    final Set<String> distinctVoters =
        awards.values.expand((userVotes) => userVotes.keys).toSet();

    return InfoContainerWithTitleAndSubtitle(
      subtitle: l10n.matchStatsSubTitle(distinctVoters.length),
      title: l10n.matchAwardsTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < awardTypes.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            (() {
              final award = awardTypes[i];
              final awardId = award['id']!;
              final userVotes = awards[awardId] ?? {};
              final sortedVotes = userVotes.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              if (sortedVotes.isEmpty) return const SizedBox.shrink();

              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Palette.greyLighter,
                    width: 1,
                  ),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: Center(
                                  child: Image.asset(award['icon']!,
                                      width: 32, height: 32),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  award['label']!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (i == 0)
                                Text(
                                  l10n.votes,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.4),
                                      ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...(() {
                            // Find if there is a single winner
                            int maxVotes = sortedVotes.isNotEmpty
                                ? sortedVotes.first.value
                                : 0;
                            int numWinners = sortedVotes
                                .where((e) => e.value == maxVotes)
                                .length;
                            return sortedVotes
                                .asMap()
                                .entries
                                .map((entryWithIndex) {
                              final index = entryWithIndex.key;
                              final entry = entryWithIndex.value;
                              final user = usersState.getUserDetail(entry.key);
                              final isWinner = index == 0 &&
                                  sortedVotes.isNotEmpty &&
                                  entry.value == maxVotes &&
                                  numWinners == 1;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2.0),
                                child: Container(
                                  decoration: isWinner
                                      ? BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          // boxShadow: [
                                          //   BoxShadow(
                                          //     color: Colors.black.withOpacity(0.1),
                                          //     offset: const Offset(1, 1),
                                          //     blurRadius: 10,
                                          //   ),
                                          // ],
                                        )
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0, horizontal: 8.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Center(
                                            child: UserAvatar(20, user),
                                          ),
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
                                        Text(
                                          '${entry.value}',
                                          style: TextPalette.bodyText,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            });
                          })(),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            })(),
          ]
        ],
      ),
    );
  }
}
