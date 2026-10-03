import 'package:flutter/foundation.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';

/// A class that manages the ratings given by a user for a specific match.
/// It handles both fetching and posting ratings to the backend.
class UserRatings extends ChangeNotifier {
  /// The ID of the match these ratings belong to
  final String matchId;

  /// Whether the ratings are currently being loaded
  bool _isLoading = false;

  /// Gets the current loading state
  bool get isLoading => _isLoading;

  /// Creates a new UserRatings instance for a specific match.
  /// Automatically fetches existing ratings for the match.
  UserRatings(this.matchId) {
    fetchRatings(matchId);
  }

  /// Map storing ratings given by the user.
  /// Key is the user ID being rated, value is the rating score.
  Map<String, int> _ratings = {};

  /// Checks if the user has given any ratings for this match.
  bool isEmpty() {
    return _ratings.isEmpty;
  }

  /// Gets the rating given to a specific user.
  /// Returns null if no rating was given.
  int getRating(String userId) {
    return _ratings[userId] ?? 0;
  }

  void setRating(String userId, int rating) {
    _ratings[userId] = rating;
    notifyListeners();
  }

  /// Fetches the ratings given by the current user for this match from the backend.
  Future<void> fetchRatings(String matchId) async {
    _isLoading = true;
    notifyListeners();
    try {
      var ratings =
          await CloudFunctionsClient().get("matches/$matchId/ratings/given");
      _ratings = Map<String, int>.from(ratings ?? {});
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Posts multiple ratings to the backend.
  /// Updates the local state after successful posting.
  void postRatings() async {
    await CloudFunctionsClient()
        .post("matches/$matchId/ratings/add_multi", _ratings);
    _ratings = Map<String, int>.from(_ratings);
    notifyListeners();
  }
}