import 'package:nutmeg/l10n/app_localizations.dart';

/// What a player can be tagged for when rating them, one tap each and optional.
/// The ids are what the backend stores (it checks them against its own list);
/// each is a vote for a FIFA-style attribute: pace, shooting, passing,
/// dribbling, defending, physical and goalkeeping.
const traitIds = [
  'fast',
  'shooter',
  'great_passer',
  'dribbler',
  'solid_defender',
  'strong',
  'great_in_goal',
];

/// A rater can pick only a couple per player, so that a trait means something.
const maxTraitsPerPlayer = 2;

String traitLabel(AppLocalizations l10n, String id) => switch (id) {
      'fast' => l10n.traitFast,
      'shooter' => l10n.traitShooter,
      'great_passer' => l10n.traitGreatPasser,
      'dribbler' => l10n.traitDribbler,
      'solid_defender' => l10n.traitSolidDefender,
      'strong' => l10n.traitStrong,
      'great_in_goal' => l10n.traitGreatInGoal,
      _ => id,
    };
