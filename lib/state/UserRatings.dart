import 'package:flutter/foundation.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';

/// A class that manages the ratings and awards given by a user for a specific match.
/// It handles both fetching and posting ratings and awards to the backend.
class UserRatings extends ChangeNotifier {
  /// The ID of the match these ratings belong to
  final String matchId;

  /// Creates a new UserRatings instance for a specific match.
  /// Automatically fetches existing ratings and awards for the match.
  UserRatings(this.matchId) {
    fetchRatings(matchId);
    fetchAwards(matchId);
  }

  /// Map storing ratings given by the user.
  /// Key is the user ID being rated, value is the rating score.
  Map<String, int> _ratings = {};

  /// Map storing awards given by the user.
  /// Key is the award ID, value is the user ID who received the award.
  Map<String, String?> _awards = {
    'best_goal': null,
    'best_striker': null,
    'best_goalkeeper': null,
    'best_defender': null,
  };

  /// Checks if the user has given any ratings or awards for this match.
  bool isEmpty() {
    return _ratings.isEmpty && _awards.values.every((value) => value == null);
  }

  /// Gets the rating given to a specific user.
  /// Returns null if no rating was given.
  int? getRating(String userId) {
    return _ratings[userId];
  }

  /// Gets the user ID who received a specific award.
  /// Returns null if no award was given.
  String? getAward(String awardId) {
    return _awards[awardId];
  }

  /// Fetches the ratings given by the current user for this match from the backend.
  Future<void> fetchRatings(String matchId) async {
    var ratings = await CloudFunctionsClient().get("matches/$matchId/ratings/given");
    _ratings = Map<String, int>.from(ratings ?? {});
    notifyListeners();
  }

  /// Fetches the awards given by the current user for this match from the backend.
  Future<void> fetchAwards(String matchId) async {
    var awards = await CloudFunctionsClient().get("matches/$matchId/awards/given");
    if (awards != null) {
      _awards = Map<String, String?>.from(awards);
    }
    notifyListeners();
  }

  /// Posts multiple ratings to the backend.
  /// Updates the local state after successful posting.
  void postRatings(Map<String, int> ratings) async {
    await CloudFunctionsClient().post("matches/$matchId/ratings/add_multi", ratings);
    _ratings = Map<String, int>.from(ratings);
    notifyListeners();
  }

  /// Posts awards to the backend.
  /// Only posts non-null awards and updates the local state after successful posting.
  void postAwards(Map<String, String?> awards) async {
    // Filter out null values
    var awardsToPost = Map.fromEntries(awards.entries.where((e) => e.value != null));
    if (awardsToPost.isNotEmpty) {
      await CloudFunctionsClient().post("matches/$matchId/awards/add", awardsToPost);
      _awards = Map<String, String?>.from(awards);
      notifyListeners();
    }
  }
} 