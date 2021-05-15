import 'package:flutter/material.dart';
import 'package:nutmeg/model.dart';

import '../Utils.dart';

void main() {
  runApp(new MaterialApp(
    debugShowCheckedModeBanner: false,
    home: new MatchDetails(Match(
        DateTime.parse("2020-05-21 18:00:00Z"),
        new SportCenter(
            "SportCentrum De Pijp", 52.34995155532827, 4.894433669187803),
        "5-aside",
        10,
        4,
        5.50)),
    theme: appTheme
  ));
}

class MatchDetails extends StatelessWidget {
  Match match;

  MatchDetails(this.match);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final ThemeData themeData = Theme.of(context);
    final padding = 15.0;

    return SafeArea(
      child: Scaffold(
        appBar: getAppBar(context),
        body: Container(
          decoration: new BoxDecoration(color: Colors.grey.shade400),
          padding: EdgeInsets.all(padding),
          child: Column(
            children: [
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Icon(Icons.menu),
              //
              //     getTopBottomWidget(context)
              //   ],
              // ),
              Spacer(),
              Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                Text(match.sport, style: themeData.textTheme.headline1)
              ]),
              Spacer(),
              Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                Text("8 spots left", style: themeData.textTheme.headline2)
              ]),
              Spacer(),
              Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                TextButton(
                    onPressed: () {},
                    child: Text(
                      'Join',
                    ),
                    style: ButtonStyle(
                        side: MaterialStateProperty.all(
                            BorderSide(width: 2, color: Colors.purple)),
                        foregroundColor: MaterialStateProperty.all(Colors.purple),
                        padding: MaterialStateProperty.all(
                            EdgeInsets.symmetric(vertical: 10, horizontal: 50)),
                        textStyle: MaterialStateProperty.all(
                            themeData.textTheme.headline3))),
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
                  title: "5.50", icon: Icons.money, subTitle: "Pay with Ideal"),
              Divider(),
              Spacer(),
              Row(children: [
                Text("2/10 players going", style: themeData.textTheme.bodyText1),
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
        ),
      ),
    );
  }
}

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
        ));
  }
}
