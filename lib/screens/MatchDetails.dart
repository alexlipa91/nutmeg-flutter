import 'package:flutter/material.dart';
import 'package:nutmeg/models/MatchesModel.dart';
import 'package:nutmeg/models/UserModel.dart';
import 'package:nutmeg/models/Model.dart';
import 'package:nutmeg/screens/Payment.dart';
import 'package:provider/provider.dart';

import '../Utils.dart';
import 'Login.dart';


class MatchDetails extends StatelessWidget {
  String matchId;

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
            if (context.read<UserModel>().isLoggedIn()) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Payment(matchId: matchId)));
            } else {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => Login()));
            }
          }

          _getTextButton(UserModel user, Match m) {
            var buttonStyle = ButtonStyle(
                side: MaterialStateProperty.all(
                    BorderSide(width: 2, color: Colors.purple)),
                foregroundColor: MaterialStateProperty.all(Colors.purple),
                padding: MaterialStateProperty.all(
                    EdgeInsets.symmetric(vertical: 10, horizontal: 50)),
                textStyle:
                    MaterialStateProperty.all(themeData.textTheme.headline3));

            if (user.isLoggedIn() && m.joining.contains(user.user.uid)) {
              return TextButton(
                  child: Text((match.status == MatchStatus.played)
                      ? "Played"
                      : "Going"),
                  style: buttonStyle);
            }
            return TextButton(
                onPressed: _goToNextStepToJoin,
                child: Text("Join"),
                style: buttonStyle);
          }

          _getTextDependingOnMatch(String userName) {
            return (match.status == MatchStatus.played)
                ? "Played"
                : match.joining.contains(userName)
                    ? "Going"
                    : "Join";
          }

          return Container(
            decoration: new BoxDecoration(color: Colors.grey.shade400),
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                  Text(match.sportCenter.name,
                      style: themeData.textTheme.headline1)
                ]),
                Spacer(),
                Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                  Text("8 spots left", style: themeData.textTheme.headline2)
                ]),
                Spacer(),
                Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                  _getTextButton(context.watch<UserModel>(), match)
                ]),
                Spacer(),
                new InfoWidget(
                    title: match.getFormattedDate(),
                    icon: Icons.watch,
                    // todo fix this
                    subTitle: "Wed Sept 2020"),
                new InfoWidget(
                    title: match.sportCenter.name,
                    icon: Icons.place,
                    // todo fix address
                    subTitle: "Madurastraat 15D, Amsterdam"),
                new InfoWidget(
                    title: match.sport.toString(),
                    icon: Icons.sports_soccer,
                    // todo fix info sport
                    subTitle: "Indoors, covered"),
                new InfoWidget(
                    title: "€ " + match.pricePerPerson.toString(),
                    icon: Icons.money,
                    subTitle: "Pay with Ideal"),
                Divider(),
                Spacer(),
                Row(children: [
                  Text(
                      match.joining.length.toString() +
                          "/" +
                          match.maxPlayers.toString() +
                          " players going",
                      style: themeData.textTheme.bodyText1),
                ]),
                Spacer(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: BouncingScrollPhysics(),
                    child: Row(
                        children: match.joining
                            .map((e) => FutureBuilder(
                                future: UserModel.getImageUrl(e),
                                builder: (context, snapshot) => (snapshot
                                        .hasData)
                                    ? Tab(icon: Image.network(snapshot.data))
                                    : Icon(Icons.face, size: 50.0)))
                            // Icon(Icons.face, size: 50.0)
                            .toList()),
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
        ));
  }
}
