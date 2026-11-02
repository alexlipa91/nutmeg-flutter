import 'package:flutter/foundation.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/model/Traits.dart';

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

  /// Traits given by the user, optional.
  /// Key is the user ID being rated, value is the trait ids.
  Map<String, List<String>> _traits = {};

  /// Traits were already saved for this match, so an edit that takes them all
  /// back still has to be sent.
  bool _hadTraits = false;

  List<String> getTraits(String userId) => _traits[userId] ?? const [];

  /// Adds the trait, or takes it back; no more than [maxTraitsPerPlayer].
  void toggleTrait(String userId, String trait) {
    var current = List<String>.from(getTraits(userId));
    if (!current.remove(trait)) {
      if (current.length >= maxTraitsPerPlayer) return;
      current.add(trait);
    }
    _traits[userId] = current;
    notifyListeners();
  }

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
      try {
        var traits = await CloudFunctionsClient()
            .get("matches/$matchId/ratings/skills/given");
        _traits = (traits ?? {})
            .map((k, v) => MapEntry(k, List<String>.from(v as List)));
        _hadTraits = _traits.values.any((t) => t.isNotEmpty);
      } catch (_) {
        // a backend without traits yet: the ratings still work
      }
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
    await _postTraits();
    _ratings = Map<String, int>.from(_ratings);
    notifyListeners();
  }

  /// Posts the traits of the players rated now; nothing when there are none to
  /// send. They are optional, so a failure never loses the ratings.
  Future<void> _postTraits() async {
    var traits = {for (var id in _ratings.keys) id: getTraits(id)};
    var any = traits.values.any((t) => t.isNotEmpty);
    if (!any && !_hadTraits) return;
    try {
      await CloudFunctionsClient()
          .post("matches/$matchId/ratings/skills", traits);
      _hadTraits = any;
    } catch (_) {}
  }
}
