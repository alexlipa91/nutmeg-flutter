import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/match_details.dart';

import 'package:nutmeg/user_info_screen.dart';

import 'login.dart';
import 'model.dart';


class ListPage extends StatefulWidget {
  ListPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ListPageState createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  List matches;

  @override
  void initState() {
    matches = getMatches();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    var dayFormat = DateFormat('yyyy-MM-dd');
    var hourMinuteFormat = DateFormat('hh:mm');

    ListTile makeListTile(Match m) => ListTile(
      contentPadding:
      EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      leading: Container(
          padding: EdgeInsets.only(right: 12.0),
          decoration: new BoxDecoration(
              border: new Border(
                  right: new BorderSide(width: 1.0, color: Colors.white24))),
          child: Column(
            children: <Widget>[
              Padding(padding: EdgeInsets.all(5.0),),
              Text("MAY",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: Colors.white24),),
              Text("28", style: TextStyle(fontSize: 20, color: Colors.yellow),),
            ],
          )
      ),
      title: Text(
        m.sportCenter.name,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      // subtitle: Text("Intermediate", style: TextStyle(color: Colors.white)),

      subtitle: Padding(
          padding: EdgeInsets.only(top: 10.0),
          child: Row(
            children: <Widget>[
              Expanded(
                  flex: 5,
                  child: Container(
                    // tag: 'hero',
                    child: Text(
                        "4 spots", style: TextStyle(color: Colors.green)),
                  )),
              Expanded(
                flex: 4,
                child: Padding(
                    padding: EdgeInsets.only(left: 10.0),
                    child:
                    Text(m.sport, style: TextStyle(color: Colors.white))),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                    padding: EdgeInsets.only(left: 10.0),
                    child:
                    Text(hourMinuteFormat.format(m.dateTime), style: TextStyle(color: Colors.white))),
              )
            ],
          )),
      trailing:
      Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 30.0),
      onTap: () {
        var newPage = new DetailPage(match: m);
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => newPage));
      },
    );

    Card makeCard(Match m) => Card(
      elevation: 8.0,
      margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(color: Color.fromRGBO(64, 75, 96, .9)),
        child: makeListTile(m),
      ),
    );

    final makeBody = Container(
      // decoration: BoxDecoration(color: Color.fromRGBO(58, 66, 86, 1.0)),
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: matches.length,
        itemBuilder: (BuildContext context, int index) {
          return makeCard(matches[index]);
        },
      ),
    );

    final makeBottom = Container(
      height: 55.0,
      child: BottomAppBar(
        color: Color.fromRGBO(58, 66, 86, 1.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.home, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.account_box, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.contact_mail, color: Colors.white),
              onPressed: () {},
            )
          ],
        ),
      ),
    );
    // final topAppBar = AppBar(
    //   elevation: 0.1,
    //   backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
    //   title: Text(widget.title),
    //   actions: <Widget>[
    //     IconButton(
    //       icon: Icon(Icons.list),
    //       onPressed: () {},
    //     )
    //   ],
    // );

    return Scaffold(
      backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
      appBar: getAppBar(context),
      body: makeBody,
      bottomNavigationBar: makeBottom,
    );
  }
}

List getMatches() {
  return [
    Match(
        DateTime.parse("2020-05-21 18:00:00Z"),
        new SportCenter(
            "SportCentrum De Pijp", 52.34995155532827, 4.894433669187803),
        "5-aside",
        10,
        4,
        5.50),
    Match(
        DateTime.parse("2020-05-27 18:00:00Z"),
        new SportCenter("Het Marnix", 52.37814776657895, 4.878418555693728),
        "5-aside",
        10,
        4,
        6.0),
    Match(
        DateTime.parse("2020-05-31 18:00:00Z"),
        new SportCenter(
            "SportCentrum Zuidplas", 51.985700943649064, 4.658921084515437),
        "5-aside",
        10,
        4,
        7.00),
  ];
}

getAppBar(BuildContext context) {
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

  return AppBar(
    elevation: 0.1,
    backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
    title: Text("Matches Available"),
    actions: <Widget>[
      rightMostWidget
    ],
  );
}