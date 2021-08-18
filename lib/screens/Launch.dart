import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/models/MatchesFirestore.dart';
import 'package:nutmeg/models/Model.dart';
import 'package:nutmeg/models/UserFirestore.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/screens/AvailableMatches.dart';
import 'package:provider/provider.dart';

class MatchesChangeNotifier extends ChangeNotifier {

  List<Match> matches;

  refresh() async {
    matches = await MatchesFirestore.fetchMatches();
    print("notifying");
    notifyListeners();
  }

  joinMatch(Match m, UserDetails u) async {
    await MatchesFirestore.joinMatch(u, m);
    await refresh();
  }
}

class SingleMatchChangeNotifier extends ChangeNotifier {

  Match match;

  refresh() async {
    match = await MatchesFirestore.fetchMatch(match);
    notifyListeners();
  }

  joinMatch(UserDetails u) async {
    await MatchesFirestore.joinMatch(u, match);
    await refresh();
  }
}


class UserChangeNotifier extends ChangeNotifier {

  UserDetails userDetails;

  Future<void> loginWithGoogle() async {
    userDetails = await UserFirestore.loginWithGoogle();
    notifyListeners();
  }

  bool isLoggedIn() => userDetails != null && userDetails.firebaseUser != null;

  void logout() async {
    await UserFirestore.logout();
    userDetails.firebaseUser = null;
    notifyListeners();
  }
}


void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => UserChangeNotifier()),
      ChangeNotifierProvider(create: (context) => MatchesChangeNotifier())
    ],
    child: new MaterialApp(
      debugShowCheckedModeBanner: false,
      home: new Container(
          decoration: new BoxDecoration(color: Colors.grey.shade400),
          child: Center(child: new LaunchWidget())),
      theme: appTheme,
    ),
  ));
}

Future<void> callAsyncFetch(BuildContext context) {
  Future<void> Function() loadFunction = () async {
    await Firebase.initializeApp();
    await context.read<MatchesChangeNotifier>().refresh();
  };

  return Future.delayed(Duration(seconds: 1), loadFunction);
}

class LaunchWidget extends StatefulWidget {
  @override
  _LaunchWidgetState createState() => _LaunchWidgetState();
}

class _LaunchWidgetState extends State<LaunchWidget> {
  @override
  void initState() {
    super.initState();
    callAsyncFetch(context)
        .then((matches) => matches) // no error message here
        .catchError((onError) => onError.toString())
        .then((matches) => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider(
                    create: (context) => FilterButtonState(FilterOption.ALL),
                    child: AvailableMatches()))));
  }

  @override
  Widget build(BuildContext context) {
    print("Building " + this.runtimeType.toString());

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          image: DecorationImage(
            image: AssetImage("assets/running_football.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}
