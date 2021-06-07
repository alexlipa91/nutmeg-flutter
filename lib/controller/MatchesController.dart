import 'package:nutmeg/models/Model.dart';

class MatchesController {

  static Iterable<Match> getUserMatches(Iterable<Match> matches, Iterable<Subscription> subs, User user) {
    var idSet = subs.where((e) => e.userId == user.id).map((e) => e.matchId).toSet();
    matches.where((e) => idSet.contains(e.id));
  }

  static bool isUserInMatch(Match match, Iterable<Subscription> subs, User user) {
    return true;
  }
}