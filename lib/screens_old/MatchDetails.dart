import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/screens/PaymentPage.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/AppBar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';


import '../screens/Login.dart';

isGoing(Match match, BuildContext context) {
  return context.read<UserChangeNotifier>().isLoggedIn() &&
      match.isUserGoing(context
          .read<UserChangeNotifier>()
          .getUserDetails());
}

class MatchDetails extends StatelessWidget {

  final Match match;

  MatchDetails(this.match);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Palette.primary,
        // appBar: MainAppBarOld(),
        body: Container(
          decoration: new BoxDecoration(color: Colors.grey.shade400),
          // fixme this is not working well; here we need something that fits the whole page vertically and can scroll if too big. Now this has the scroll animation on top but it actually fits so it shouldn't
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
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
                                    if (context.read<UserChangeNotifier>().isLoggedIn() &&
                                        match.isUserGoing(
                                            context
                                                .read<UserChangeNotifier>()
                                                .getUserDetails()))
                                      Icon(Icons.check_circle,
                                          color: Colors.white, size: 40),
                                  ],
                                )
                              ])),
                    ),
                    MatchInfoContainer(match),
                    PlayersList(
                        users: match.subscriptions
                            .where((s) => s.status == SubscriptionStatus.going)
                            .map((e) => e.userId)
                            .toList())
                  ],
                ),
              )
            ],
          ),
        ));
  }
}

class MatchInfoContainer extends StatelessWidget {
  static var formatCurrency = NumberFormat.simpleCurrency(name: "EUR");
  static var dateFormat = DateFormat('MMMM dd \'at\' HH:mm');

  final Match match;

  const MatchInfoContainer(this.match);

  @override
  Widget build(BuildContext context) {
    SportCenter sportCenter = context.read<SportCentersChangeNotifier>().getSportCenter(match.sportCenter);

    return Container(
        margin: EdgeInsets.all(15),
        decoration: infoMatchDecoration,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(children: [
            InfoWidget(
                title: dateFormat.format(match.dateTime), icon: Icons.watch),
            InkWell(
              child: InfoWidget(
                  title: sportCenter.name,
                  icon: Icons.place,
                  subTitle: sportCenter.address),
              onTap: () async {

                String googleUrl = "https://www.google.com/maps/search/?api=1&query=Google&query_place_id=" + sportCenter.placeId;

                if (await canLaunch(googleUrl)) {
                  await launch(googleUrl);
                } else {
                  // throw 'Could not open the map.';
                  CoolAlert.show(context: context, type: CoolAlertType.error, text: "Could not open maps");
                }
              },
            ),
            InfoWidget(
                title: match.sport.getDisplayTitle(),
                icon: Icons.sports_soccer,
                // todo fix info sport
                subTitle: sportCenter.tags.join(", ")),
            InfoWidget(
                title: formatCurrency.format(match.getPrice()),
                icon: Icons.money,
                subTitle: "Pay with Ideal"),
            Row(
              children: [
                Expanded(
                  child: MatchInfoMainButton(match),
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
  Match match;

  MatchInfoMainButton(this.match);

  @override
  Widget build(BuildContext context) {
    _onPressedJoinAction() async {
      bool isLoggedIn = false;

      if (!context.read<UserChangeNotifier>().isLoggedIn()) {
        isLoggedIn = await Navigator.push(
            context, MaterialPageRoute(builder: (context) => Login()))
            .then((isLoginSuccessfull) => isLoginSuccessfull);
      } else {
        isLoggedIn = true;
      }

      if (isLoggedIn) {
        var value = await showModalBottomSheet(
            context: context,
            builder: (context) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text("Join this match"),
                  Text('blablabla'),
                  Divider(),
                  Text("price"),
                  TextButton(
                      onPressed: () async {
                        final stripeCustomerId = await context.read<UserChangeNotifier>()
                            .getOrCreateStripeId();
                        print("stripeCustomerId " + stripeCustomerId);
                        final sessionId = await Server()
                            .createCheckout(stripeCustomerId, match.pricePerPersonInCents);
                        print("sessId " + sessionId);

                        var value = await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    CheckoutPage(sessionId: sessionId)));

                        // remove previous bottom sheet
                        Navigator.pop(context, value);
                      },
                      child: Text("Continue to payment"))
                ],
              );
            });
        if (value == "success") {
          await context.read<MatchesChangeNotifier>().joinMatch(match, context.read<UserChangeNotifier>().getUserDetails());
          showModalBottomSheet(context: context,
              builder: (context) {
                return TextButton(child: Text("close"), onPressed: () => Navigator.pop(context));
              });
        } else {
          CoolAlert.show(
              context: context,
              type: CoolAlertType.error,
              text: "Payment failed");
        }
      }
    }

    _onPressedLeaveAction() async {
      await showModalBottomSheet(
          context: context,
          builder: (context) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text("Are you sure? You are going to receive X euro back in your account for future matches"),
                Divider(),
                TextButton(
                    onPressed: () async {
                      await context.read<MatchesChangeNotifier>().leaveMatch(match, context.read<UserChangeNotifier>().getUserDetails());

                      // go to home
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: Text("Yes"))
              ],
            );
          });
    }

    var mainColor = isGoing(match, context) ? Colors.red : Palette.primary;

    return TextButton(
      child: Text(isGoing(match, context) ? "Leave" : "Join",
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
      isGoing(match, context)
          ? _onPressedLeaveAction()
          : _onPressedJoinAction(),
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
                  .map((e) =>
                  FutureBuilder<UserDetails>(
                      future: UserChangeNotifier.getSpecificUserDetails(e),
                      builder: (context, snapshot) =>
                      (snapshot.hasData &&
                          e != null)
                          ? PlayerCard(
                          name: snapshot.data.name.split(" ").first,
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
            if (name != null) Text(name)
          ]),
        ));
  }
}
