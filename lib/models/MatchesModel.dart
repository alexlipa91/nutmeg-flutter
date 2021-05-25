import 'package:flutter/cupertino.dart';
import 'package:nutmeg/models/Model.dart';


class MatchesModel extends ChangeNotifier {

  final List<Match> matches;

  MatchesModel(this.matches);

  joinMatch(String user, Match match) {
    match.joining.add(user);
    notifyListeners();
  }

  refresh() async {
    print("simulating a refresh");
    // todo fix this when the backend is there
    // simulate a refresh
    // matches.add(matches.last);
    notifyListeners();
    print(matches.length);
  }
}