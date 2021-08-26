import 'package:cool_alert/cool_alert.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/screens/PaymentPage.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/AppBar.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  var matchesChangeNotifier = MatchesChangeNotifier();
  var sportCenterChangeNotifier = SportCentersChangeNotifier();

  await matchesChangeNotifier.refresh();
  await sportCenterChangeNotifier.refresh();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => UserChangeNotifier()),
      ChangeNotifierProvider(create: (context) => matchesChangeNotifier),
      ChangeNotifierProvider(create: (context) => sportCenterChangeNotifier),
      ChangeNotifierProvider(create: (context) => LocationChangeNotifier()),
    ],
    child: new MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MatchDetails(matchesChangeNotifier.getMatches().first)),
  ));
}

class MatchDetails extends StatelessWidget {
  final Match match;

  MatchDetails(this.match);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SecondaryAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            MatchInfo(match),
            Text("X players going"),
            Row(
              children: [PlayerCard(), PlayerCard()],
            ),
            Text("Details"),
            RuleCard(),
            RuleCard(),
            MapCard()
          ],
        ),
      ),
      bottomNavigationBar:
          Container(height: 50, color: Colors.red, child: Text("Join Here")),
    );
  }
}

class MatchInfo extends StatelessWidget {
  final Match match;

  MatchInfo(this.match);

  @override
  Widget build(BuildContext context) {
    return InfoContainer(child: Text("a"));
  }
}

class PlayerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InfoContainer(
      child: Text("picture"),
    );
  }
}

class RuleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return InfoContainer(child: Text("Rule" * 100));
  }
}

class MapCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return InfoContainer(child: Text("Map"));
  }
}
