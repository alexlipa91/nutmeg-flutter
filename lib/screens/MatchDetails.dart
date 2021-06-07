import 'package:flutter/material.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/models/MatchesModel.dart';
import 'package:nutmeg/models/Model.dart';
import 'package:nutmeg/models/SubscriptionsModel.dart';
import 'package:nutmeg/models/UserModel.dart';
import 'package:nutmeg/screens/PaymentTest.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../UsersUtils.dart';
import '../Utils.dart';
import 'Login.dart';


class MatchDetails extends StatelessWidget {

  String matchId;

  MatchDetails(this.matchId);

  @override
  Widget build(BuildContext context) {
    print("Building " + this.runtimeType.toString());

    var match = context.watch<MatchesModel>().getMatch(matchId);
    var user = context.watch<UserModel>().getUser();
    var subs = context.watch<SubscriptionsBloc>().getSubscriptions();

    return SafeArea(
      child: Scaffold(
          backgroundColor: Palette.green,
          appBar: getAppBar(context),
          body: Container(
            decoration: new BoxDecoration(color: Colors.grey.shade400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: topBoxDecoration,
                  child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(match.sport.getDisplayTitle(),
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800)),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                    decoration: new BoxDecoration(
                                      color: Colors.red.shade300,
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                      border: new Border.all(
                                        color: Colors.white70,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Padding(
                                        padding: EdgeInsets.all(5),
                                        child: Text(
                                            match.getSpotsLeft().toString() +
                                                " spots left",
                                            style: TextStyle(
                                                color: Colors.grey.shade50,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400)))),
                                if (MatchesController.isUserInMatch(match, subs, user))
                                  Icon(Icons.check_circle,
                                      color: Colors.white, size: 40),
                              ],
                            )
                          ])),
                ),
                MatchInfoContainer(match: match),
                PlayersList(users: match.joining)
              ],
            ),
          )),
    );
  }
}

class MatchInfoContainer extends StatelessWidget {
  static var formatCurrency = NumberFormat.simpleCurrency(name: "EUR");
  static var dateFormat = DateFormat('MMMM dd \'at\' HH:mm');

  final Match match;

  const MatchInfoContainer({Key key, this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.all(20),
        decoration: infoMatchDecoration,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(children: [
            InfoWidget(
                title: dateFormat.format(match.dateTime), icon: Icons.watch),
            InfoWidget(
                title: match.sportCenter.name,
                icon: Icons.place,
                subTitle: match.sportCenter.address),
            InfoWidget(
                title: match.sport.getDisplayTitle(),
                icon: Icons.sports_soccer,
                // todo fix info sport
                subTitle: match.sportCenter.getTags()),
            InfoWidget(
                title: formatCurrency.format(match.pricePerPerson),
                icon: Icons.money,
                subTitle: "Pay with Ideal"),
            Row(
              children: [
                Expanded(
                  child: MatchInfoMainButton(match: match),
                )
              ],
            )
          ]),
        ));
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
                if (subTitle != null)
                  Text(subTitle, style: themeData.textTheme.bodyText2)
              ],
            )
          ],
        ));
  }
}

class MatchInfoMainButton extends StatelessWidget {
  final Match match;
  final bool isGoing;

  const MatchInfoMainButton({Key key, this.match, this.isGoing}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    _onPressedJoinAction() {
      if (context.read<UserModel>().isLoggedIn()) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PaymentPage(match: match)));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Login()));
      }
    }

    _onPressedLeaveAction() {
      showDialog(
          context: context,
          builder: (_) =>
              new AlertDialog(title: Text("Implement leave match")));
    }

    var mainColor = isGoing ? Colors.red : Palette.green;

    return TextButton(
      child: Text(isGoing ? "Leave" : "Join",
          style: TextStyle(
              color: mainColor, fontSize: 20, fontWeight: FontWeight.w700)),
      style: ButtonStyle(
        side: MaterialStateProperty.all(BorderSide(width: 2, color: mainColor)),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        )),
      ),
      onPressed: () =>
          isGoing ? _onPressedLeaveAction() : _onPressedJoinAction(),
    );
  }
}

class PlayersList extends StatelessWidget {
  final List<String> users;

  const PlayersList({Key key, this.users}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: BouncingScrollPhysics(),
          child: Row(
              children: users
                  .map((e) => FutureBuilder<User>(
                      future: UsersUtils.getUser(e),
                      builder: (context, snapshot) => (snapshot.hasData &&
                              e != null)
                          ? PlayerCard(
                              name: snapshot.data.name,
                              imageUrl: snapshot.data.image)
                          : Icon(Icons.face, size: 50.0)))
                  .toList()),
        ),
      ),
    );
  }
}

class PlayerCard extends StatelessWidget {
  final String name;
  final String imageUrl;

  const PlayerCard({Key key, this.name, this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: infoMatchDecoration,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(children: [
            CircleAvatar(
                backgroundImage: NetworkImage(imageUrl),
                radius: 25,
                backgroundColor: Palette.white),
            SizedBox(height: 10),
            if(name != null) Text(name)
          ]),
        ));
  }
}
