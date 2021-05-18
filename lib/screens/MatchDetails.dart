import 'package:flutter/material.dart';
import 'package:nutmeg/models/MatchesModel.dart';
import 'package:nutmeg/models/UserModel.dart';
import 'package:nutmeg/Model.dart';
import 'package:nutmeg/screens/Payment.dart';
import 'package:provider/provider.dart';

import '../Utils.dart';
import 'Login.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => UserModel("u")),
      ChangeNotifierProvider(
          create: (context) => MatchesModel([
                Match(
                    1,
                    DateTime.parse("2020-05-21 18:00:00Z"),
                    new SportCenter("SportCentrum De Pijp", 52.34995155532827,
                        4.894433669187803),
                    "5-aside",
                    10,
                    [],
                    5.50,
                    MatchStatus.open)
              ]))
    ],
    child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MatchDetails(1),
        theme: appTheme),
  ));
}

class MatchDetails extends StatelessWidget {
  int matchId;

  MatchDetails(this.matchId);

  @override
  Widget build(BuildContext context) {
    print("Building " + this.runtimeType.toString());

    final Size size = MediaQuery.of(context).size;
    final ThemeData themeData = Theme.of(context);
    final padding = 15.0;

    return SafeArea(
      child: Scaffold(
        appBar: getAppBar(context),
        body: Consumer<MatchesModel>(builder: (context, matches, child) {
          Match match = matches.getMatch(matchId);

          // function for when clicking join
          _goToNextStepToJoin() {
            if (Provider.of<UserModel>(context, listen: false)
                .name !=
                null) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          Payment(matchId: matchId)));
            } else {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => Login()));
            }
          }

          _getTextDependingOnMatch(String userName) {
            return (match.status == MatchStatus.played) ? "Played" : 
                match.joining.contains(userName) ? "Going" : "Join";
          }
          
          return Container(
            decoration: new BoxDecoration(color: Colors.grey.shade400),
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                  Text(match.sport, style: themeData.textTheme.headline1)
                ]),
                Spacer(),
                Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                  Text("8 spots left", style: themeData.textTheme.headline2)
                ]),
                Spacer(),
                Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                  Consumer<UserModel>(
                    builder: (context, user, child) {
                      return TextButton(
                          onPressed: (match.joining.contains(user.name)) ? null
                              : _goToNextStepToJoin,
                          child: Text(_getTextDependingOnMatch(user.name)),
                          style: ButtonStyle(
                              side: MaterialStateProperty.all(
                                  BorderSide(width: 2, color: Colors.purple)),
                              foregroundColor:
                              MaterialStateProperty.all(Colors.purple),
                              padding: MaterialStateProperty.all(
                                  EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 50)),
                              textStyle: MaterialStateProperty.all(
                                  themeData.textTheme.headline3)));
                    }
                  ),
                ]),
                Spacer(),
                new InfoWidget(
                    title: "Today at 18:00",
                    icon: Icons.watch,
                    subTitle: "Wed Sept 2020"),
                new InfoWidget(
                    title: match.sportCenter.name,
                    icon: Icons.place,
                    subTitle: "Madurastraat 15D, Amsterdam"),
                new InfoWidget(
                    title: "Futsal",
                    icon: Icons.sports_soccer,
                    subTitle: "Indoors, covered"),
                new InfoWidget(
                    title: "5.50",
                    icon: Icons.money,
                    subTitle: "Pay with Ideal"),
                Divider(),
                Spacer(),
                Row(children: [
                  Text("2/10 players going",
                      style: themeData.textTheme.bodyText1),
                ]),
                Spacer(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        Icon(Icons.face, size: 50.0),
                        Icon(Icons.face, size: 50.0),
                        Icon(Icons.face, size: 50.0),
                        Icon(Icons.face, size: 50.0),
                        Icon(Icons.face, size: 50.0),
                        Icon(Icons.face, size: 50.0),
                        Icon(Icons.face, size: 50.0),
                        Icon(Icons.face, size: 50.0),
                        Icon(Icons.face, size: 50.0),
                        Icon(Icons.face, size: 50.0),
                      ],
                    ),
                  ),
                )
              ],
            ),
          );
        }),
      ),
    );
  }
}

// test commit
// test number 2
class InfoWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final String subTitle;

  const InfoWidget({Key key, this.title, this.icon, this.subTitle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Container(
        margin: EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: [
            new Icon(icon),
            SizedBox(
              width: 20,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: themeData.textTheme.bodyText1),
                SizedBox(
                  height: 5,
                ),
                Text(subTitle, style: themeData.textTheme.bodyText2),
              ],
            )
          ],
        )
    );
  }
}
