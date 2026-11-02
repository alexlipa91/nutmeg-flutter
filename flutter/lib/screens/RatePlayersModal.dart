import 'package:flutter/material.dart';
import 'package:nutmeg/model/Traits.dart';
import 'package:nutmeg/state/MatchesState.dart';
import 'package:nutmeg/state/UserRatings.dart';
import 'package:nutmeg/state/UsersState.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/ModalBottomSheet.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:provider/provider.dart';
import 'package:nutmeg/l10n/app_localizations.dart';

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
  // Get the existing UserRatings state from MatchDetails
  var userRatings = context.read<UserRatings>();

  await ModalBottomSheet.showNutmegModalBottomSheet(
      context,
      ChangeNotifierProvider.value(
        value: userRatings,
        child: RatePlayerSingleSheet(matchId: matchId),
      ),
      stickyBottom: ChangeNotifierProvider.value(
        value: userRatings,
        child: RatePlayersSubmitSticky(),
      ));
}

class RatePlayerSingleSheet extends StatefulWidget {
  final String matchId;

  const RatePlayerSingleSheet({Key? key, required this.matchId})
      : super(key: key);

  @override
  State<RatePlayerSingleSheet> createState() => _RatePlayerSingleSheetState();
}

class _RatePlayerSingleSheetState extends State<RatePlayerSingleSheet> {
  // the player whose traits are open: one at a time keeps the sheet short
  String? _open;

  @override
  Widget build(BuildContext context) {
    var matchId = widget.matchId;
    var usersToRate =
        context.watch<MatchesState>().getMatch(matchId).getUsersToRate();

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
                        .map((e) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    UserAvatar(
                                        16,
                                        context
                                            .watch<UsersState>()
                                            .getUserDetail(e.value)),
                                    SizedBox(
                                      width: 16,
                                    ),
                                    Expanded(
                                      child: UserNameWidget(
                                          userDetails: context
                                              .watch<UsersState>()
                                              .getUserDetail(e.value)),
                                    ),
                                    RatingBar(userId: e.value)
                                  ]),
                                  // under the name: 16 radius avatar + 16 gap
                                  Padding(
                                      padding: EdgeInsets.only(left: 48),
                                      child: TraitSection(
                                          userId: e.value,
                                          expanded: _open == e.value,
                                          onToggle: () => setState(() => _open =
                                              _open == e.value
                                                  ? null
                                                  : e.value))),
                                ]))
                        .toList(),
                    SizedBox(
                      height: 18,
                    ))),
          ],
        ));
  }
}

/// Submit row pinned under the scroll area in the rate-players bottom sheet.
class RatePlayersSubmitSticky extends StatelessWidget {
  const RatePlayersSubmitSticky({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GenericButtonWithLoaderAndErrorHandling(
            AppLocalizations.of(context)!.submitRatesButtonText,
            (BuildContext context) {
              context.read<UserRatings>().postRatings();
              Navigator.of(context).pop(true);
            },
            Primary(),
          ),
        ),
      ],
    );
  }
}

/// A line under the player that opens their traits: what is picked so far, or
/// "Add traits"; opened, one tap for each trait they stood out for, up to
/// [maxTraitsPerPlayer].
class TraitSection extends StatelessWidget {
  final String userId;
  final bool expanded;
  final VoidCallback onToggle;

  const TraitSection(
      {Key? key,
      required this.userId,
      required this.expanded,
      required this.onToggle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var ratings = context.watch<UserRatings>();
    var l10n = AppLocalizations.of(context)!;
    var picked = ratings.getTraits(userId);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InkWell(
        onTap: onToggle,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(
              child: Text(
                  picked.isEmpty
                      ? l10n.traitsAdd
                      : picked.map((id) => traitLabel(l10n, id)).join(" · "),
                  overflow: TextOverflow.ellipsis,
                  style: TextPalette.getBodyText(
                          picked.isEmpty ? Palette.greyDark : Palette.primary)
                      .copyWith(
                          fontSize: 13,
                          fontWeight: picked.isEmpty
                              ? FontWeight.w400
                              : FontWeight.w600)),
            ),
            Icon(expanded ? Icons.expand_less : Icons.expand_more,
                size: 18, color: Palette.greyDark),
          ]),
        ),
      ),
      AnimatedSize(
        duration: Duration(milliseconds: 200),
        alignment: Alignment.topLeft,
        child: expanded
            ? Padding(
                padding: EdgeInsets.only(top: 4, bottom: 4),
                child: Wrap(spacing: 6, runSpacing: 6, children: [
                  for (var id in traitIds)
                    _TraitChip(
                        label: traitLabel(l10n, id),
                        selected: picked.contains(id),
                        enabled: picked.contains(id) ||
                            picked.length < maxTraitsPerPlayer,
                        onTap: () => ratings.toggleTrait(userId, id)),
                ]),
              )
            : SizedBox(width: double.infinity),
      ),
    ]);
  }
}

class _TraitChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _TraitChip(
      {required this.label,
      required this.selected,
      required this.enabled,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: enabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Palette.primary : Colors.white,
          border:
              Border.all(color: selected ? Palette.primary : Palette.greyLight),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label,
            style: TextPalette.getBodyText(selected
                    ? Colors.white
                    : (enabled ? Palette.black : Palette.greyLight))
                .copyWith(fontSize: 13)),
      ),
    );
  }
}
