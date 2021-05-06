import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutmeg/match_details.dart';
import 'model.dart';

void main() {
  runApp(MyApp());
}

class Utils {

  static getAppBar(String s) {
    return AppBar(title: Text(s), actions: [
      Padding(
          padding: EdgeInsets.only(right: 20.0),
          child: InkWell(
            onTap: () {
              print("login here");
            },
            child: Icon(
              Icons.login,
              size: 26.0,
            ),
          ))
    ]);
  }

}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ListViews',
      theme: ThemeData(
        // Define the default brightness and colors.
        brightness: Brightness.light,
        primaryColor: Colors.lightBlue[800],
        accentColor: Colors.cyan[600],

        // Define the default TextTheme. Use this to specify the default
        // text styling for headlines, titles, bodies of text, and more.
        textTheme: TextTheme(
          headline1: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          headline6: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
          bodyText2: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
        ),
      ),
      home: Scaffold(
        appBar: Utils.getAppBar("Matches"),
        body: MatchesCards(),
      ),
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
