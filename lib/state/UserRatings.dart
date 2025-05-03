import 'package:flutter/foundation.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';

/// A class that manages the ratings and awards given by a user for a specific match.
/// It handles both fetching and posting ratings and awards to the backend.
class UserRatings extends ChangeNotifier {
  /// The ID of the match these ratings belong to
  final String matchId;

  /// Whether the ratings and awards are currently being loaded
  bool _isLoading = false;

  /// Gets the current loading state
  bool get isLoading => _isLoading;

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
  int getRating(String userId) {
    return _ratings[userId] ?? 0;
  }

  void setRating(String userId, int rating) {
    _ratings[userId] = rating;
    notifyListeners();
  }

  void setAward(String awardId, String userId) {
    _awards[awardId] = userId;
    notifyListeners();
  }

  /// Gets the user ID who received a specific award.
  /// Returns null if no award was given.
  String? getAward(String awardId) {
    return _awards[awardId];
  }

  /// Fetches the ratings given by the current user for this match from the backend.
  Future<void> fetchRatings(String matchId) async {
    _isLoading = true;
    notifyListeners();
    try {
      var ratings = await CloudFunctionsClient().get("matches/$matchId/ratings/given");
      _ratings = Map<String, int>.from(ratings ?? {});
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches the awards given by the current user for this match from the backend.
  Future<void> fetchAwards(String matchId) async {
    _isLoading = true;
    notifyListeners();
    try {
      var awards = await CloudFunctionsClient().get("matches/$matchId/awards/given");
      if (awards != null) {
        _awards = Map<String, String?>.from(awards);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Posts multiple ratings to the backend.
  /// Updates the local state after successful posting.
  void postRatings() async {
    await CloudFunctionsClient().post("matches/$matchId/ratings/add_multi", _ratings);
    _ratings = Map<String, int>.from(_ratings);
    notifyListeners();
  }

  /// Posts awards to the backend.
  /// Only posts non-null awards and updates the local state after successful posting.
  void postAwards() async {
    await CloudFunctionsClient().post("matches/$matchId/awards/add", _awards);
    _awards = Map<String, String?>.from(_awards);
    notifyListeners();  
  }

  /// Copies ratings and awards from another UserRatings instance
  void copyFrom(UserRatings other) {
    _ratings = Map<String, int>.from(other._ratings);
    _awards = Map<String, String?>.from(other._awards);
    notifyListeners();
  }
} 