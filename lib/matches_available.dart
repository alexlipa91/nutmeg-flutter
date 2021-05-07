import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutmeg/login.dart';
import 'package:nutmeg/match_details.dart';
import 'package:nutmeg/user_info_screen.dart';
import 'model.dart';

class Utils {
  static getAppBar(String s, BuildContext context) {
    var rightMostWidget = (FirebaseAuth.instance.currentUser != null)
        ? InkWell( // logged in widget
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => UserInfoScreen(
                          user: FirebaseAuth.instance.currentUser)));
            },
            child: Image.network(FirebaseAuth.instance.currentUser.photoURL))
        : InkWell( // not logged in widget
            onTap: () {
              var newPage = SignInScreen();
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => newPage));
            },
            child: Icon(
              Icons.login,
              size: 26.0,
            ));

    return AppBar(title: Text(s), actions: [
      Padding(
          padding: EdgeInsets.only(right: 20.0),
          child: rightMostWidget
      )
    ]);
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Utils.getAppBar("Matches", context),
      body: MatchesCards(),
    );
  }
}

class MatchesCards extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return MatchesState();
  }
}

class MatchesState extends State<StatefulWidget> {
  var matches = [
    Match(
        DateTime.parse("2020-05-21 18:00:00Z"),
        new SportCenter(
            "SportCentrum De Pijp", 52.34995155532827, 4.894433669187803),
        "5-aside-football",
        10,
        4,
        5.50),
    Match(
        DateTime.parse("2020-05-27 18:00:00Z"),
        new SportCenter("Het Marnix", 52.37814776657895, 4.878418555693728),
        "5-aside-football",
        10,
        4,
        6.0),
    Match(
        DateTime.parse("2020-05-31 18:00:00Z"),
        new SportCenter(
            "SportCentrum Zuidplas", 51.985700943649064, 4.658921084515437),
        "5-aside-football",
        10,
        4,
        7.00),
  ];

  @override
  Widget build(BuildContext context) {
    return _myListView(context, matches);
  }
}

Widget _myListView(BuildContext context, List<Match> matches) {
  Widget getCard(Match m) {
    var font = "Lato";
    var faceIcon =
        new Icon(const IconData(0xe71a, fontFamily: 'MaterialIcons'));

    return InkWell(
        onTap: () {
          var newPage = new MatchDetails(m);
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => newPage));
        },
        child: Card(
            child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(m.sport,
                style: GoogleFonts.getFont(font,
                    textStyle: TextStyle(
                        fontSize: 24.0, fontWeight: FontWeight.bold))),
            Text(
                m.dateTime.hour.toString() + ":" + m.dateTime.minute.toString(),
                style: GoogleFonts.getFont(font,
                    textStyle: TextStyle(
                        fontSize: 24.0, fontWeight: FontWeight.normal)))
          ]),
          SizedBox(height: 15),
          Row(children: [Text(m.sportCenter.name)]),
          SizedBox(height: 15),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(m.joined.toString() + "/" + m.total.toString()),
            Row(children: [faceIcon, faceIcon, faceIcon, faceIcon])
          ])
        ])));
  }

  // build cards from matches
  // fixme add days separators
  var cards = matches.map((element) => getCard(element)).toList();

  return ListView(children: cards
      // Padding(
      //   padding: const EdgeInsets.all(10.0),
      //   child: Text("Today", textAlign: TextAlign.center),
      // ),
      // getCard(),
      // getCard(),
      // Padding(
      //   padding: const EdgeInsets.all(10.0),
      //   child: Text("Tomorrow", textAlign: TextAlign.center),
      // ),
      // getCard(),
      );
}
