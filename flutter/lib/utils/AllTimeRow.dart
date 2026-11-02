import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';

final _logger = CrashlyticsLogger('AllTimeRow');

/// A player's row of their group's All time table: the score for the card's
/// OVR and the share of games won. Asked for separately from the player
/// because it needs their matches; both are null if it can't be had.
Future<({int? score, int? winPercent})> fetchAllTimeRow(String userId) async {
  try {
    var r = await CloudFunctionsClient().get("users/$userId/all_time_score");
    var played = (r?["played"] as num?)?.toInt() ?? 0;
    var wins = (r?["wins"] as num?)?.toInt() ?? 0;
    return (
      score: (r?["all_time_score"] as num?)?.toInt(),
      winPercent: played > 0 ? (100 * wins / played).round() : null,
    );
  } catch (e) {
    _logger.warning("Could not load the all time row: $e");
    return (score: null, winPercent: null);
  }
}
