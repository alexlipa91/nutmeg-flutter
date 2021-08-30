import 'package:cool_alert/cool_alert.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/screens/PaymentPage.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/AppBar.dart';
import 'package:nutmeg/widgets/Buttons.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:readmore/readmore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer/shimmer.dart';

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
    ],
    child: new MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MatchDetails(matchesChangeNotifier.getMatches().first)),
  ));
}

var formatCurrency = NumberFormat.simpleCurrency(name: "EUR");

class MatchDetails extends StatelessWidget {
  final Match match;

  MatchDetails(this.match);

  @override
  Widget build(BuildContext context) {
    SportCenter sportCenter = context
        .read<SportCentersChangeNotifier>()
        .getSportCenter(match.sportCenter);

    var title =
        sportCenter.neighbourhood + " - " + match.sport.getDisplayTitle();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            // fixme here we are repeating the padding just because cannot be applied globally as MatchInfo doesn't need
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SecondaryAppBar(),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: Text(title, style: TextPalette.h1Default)),
              MatchInfo(match, sportCenter),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  child: Text(
                      match.numPlayersGoing().toString() + " players going")),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 25),
                child: SingleChildScrollView(
                  clipBehavior: Clip.none,
                  scrollDirection: Axis.horizontal,
                  // physics: BouncingScrollPhysics(),
                  child: Row(
                      // fixme pass real data here
                      children: match.subscriptions
                          .where((s) => s.status == SubscriptionStatus.going)
                          .map((s) => PlayerCard(s.userId))
                          .toList()),
                ),
              ),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  child: Text("Details")),
              RuleCard(),
              RuleCard(),
              MapCard.big(sportCenter)
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomBar(match: match),
    );
  }
}

// info card
class MatchInfo extends StatelessWidget {
  static var formatCurrency = NumberFormat.simpleCurrency(name: "EUR");
  static var dateFormat = DateFormat('MMMM dd \'at\' HH:mm');

  final Match match;
  final SportCenter sportCenter;

  MatchInfo(this.match, this.sportCenter);

  @override
  Widget build(BuildContext context) {
    return InfoContainer.withoutPadding(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
              child: SportCenterImageCarousel(
                  images: sportCenter.getMainPicturesListUrls()))
        ]),
        InfoWidget(title: match.getFormattedDate(), icon: Icons.watch),
        InfoWidget.withRightWidget(
            title: sportCenter.name,
            icon: Icons.place,
            subTitle: sportCenter.getShortAddress()),
        InfoWidget(
            title: match.sport.getDisplayTitle(),
            icon: Icons.sports_soccer,
            // todo fix info sport
            subTitle: sportCenter.tags.join(", ")),
        InfoWidget(
            title: formatCurrency.format(match.getPrice()),
            icon: Icons.money,
            subTitle: "Pay with Ideal"),
      ],
    ));
  }
}

class SportCenterImageCarousel extends StatefulWidget {
  final List<String> images;

  const SportCenterImageCarousel({Key key, this.images}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SportCenterImageCarouselState(images);
}

class SportCenterImageCarouselState extends State<SportCenterImageCarousel> {
  int _current = 0;
  final List<String> images;
  final CarouselController _controller = CarouselController();

  SportCenterImageCarouselState(this.images);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // fixme check animation when slide
        CarouselSlider(
          carouselController: _controller,
          options: CarouselOptions(
              enableInfiniteScroll: false,
              viewportFraction: 1,
              onPageChanged: (index, reason) {
                setState(() {
                  _current = index;
                });
              }),
          items: images.map((i) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          fit: BoxFit.fill, image: AssetImage(i)),
                      borderRadius: BorderRadius.all(Radius.circular(15))),
                );
              },
            );
          }).toList(),
        ),
        Positioned(
          bottom: 10,
          left: 1,
          right: 1,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: images.asMap().entries.map((entry) {
                return GestureDetector(
                  onTap: () => _controller.animateToPage(entry.key),
                  child: Container(
                    width: 12.0,
                    height: 12.0,
                    margin:
                        EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white
                            .withOpacity(_current == entry.key ? 0.9 : 0.4)),
                  ),
                );
              }).toList()),
        ),
      ],
    );
  }
}

// single line with icon and texts in the info card
class InfoWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final String subTitle;

  Widget rightWidget;

  InfoWidget({this.title, this.icon, this.subTitle});

  InfoWidget.withRightWidget(
      {this.title, this.icon, this.subTitle, Widget rightWidget})
      : rightWidget = rightWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(left: 15, top: 15, bottom: 10),
        child: Row(
          children: [
            new Icon(icon),
            SizedBox(
              width: 20,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextPalette.h2),
                SizedBox(
                  height: 5,
                ),
                if (subTitle != null) Text(subTitle, style: TextPalette.bodyText)
              ],
            ),
            if (rightWidget != null) Expanded(child: rightWidget)
          ],
        ));
  }
}

// single player card
class PlayerCard extends StatelessWidget {
  final String userId;

  PlayerCard(this.userId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserDetails>(
        future: UserChangeNotifier.getSpecificUserDetails(userId),
        builder: (context, snapshot) {
          return Container(
              constraints: BoxConstraints(maxWidth: 100),
              decoration: infoMatchDecoration,
              margin: EdgeInsets.only(right: 10),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: (snapshot.hasData)
                    ? Column(children: [
                        InkWell(
                          onTap: () {
                            showModalBottomSheet(
                                context: context,
                                builder: (context) {
                                  return Stack(
                                      alignment:
                                          AlignmentDirectional.bottomStart,
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          height: 200,
                                          color: Palette.white,
                                          child: Column(
                                            children: [
                                              SizedBox(height: 70),
                                              Text(snapshot.data.name,
                                                  style: TextPalette.h2),
                                              SizedBox(height: 20),
                                              // fixme feed real data
                                              Text(
                                                  context
                                                          .watch<
                                                              MatchesChangeNotifier>()
                                                          .numPlayedByUser(
                                                              userId)
                                                          .toString() +
                                                      " games played",
                                                  style: TextPalette.bodyText)
                                            ],
                                          ),
                                        ),
                                        Positioned(
                                          top: -30,
                                          left: 0,
                                          right: 0,
                                          child: CircleAvatar(
                                            backgroundColor: Palette.white,
                                            radius: 38,
                                            child: CircleAvatar(
                                                backgroundImage: NetworkImage(
                                                    snapshot.data.image),
                                                radius: 34,
                                                backgroundColor: Palette.white),
                                          ),
                                        ),
                                      ]);
                                });
                          },
                          child: CircleAvatar(
                              backgroundImage:
                                  NetworkImage(snapshot.data.image),
                              radius: 25,
                              backgroundColor: Palette.white),
                        ),
                        SizedBox(height: 10),
                        Text(snapshot.data.name.split(" ").first,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                                color: Palette.mediumgrey,
                                fontSize: 12,
                                fontWeight: FontWeight.w400))
                      ])
                    : Shimmer.fromColors(
                        baseColor: Colors.grey[300],
                        highlightColor: Colors.grey[100],
                        child: Column(children: [
                          CircleAvatar(
                              radius: 25, backgroundColor: Palette.white),
                          SizedBox(height: 10),
                          Container(
                              height: 10,
                              width: double.infinity,
                              color: Colors.white)
                        ]),
                      ),
              ));
        });
  }
}

// single rule card
class RuleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return InfoContainer(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Title", style: TextPalette.h2),
      SizedBox(height: 10),
      ReadMoreText(
        'Flutter is Google’s mobile UI open source framework to build high-quality native (super fast) interfaces for iOS and Android apps with the unified codebase.',
        style: TextPalette.bodyText,
        trimLines: 2,
        colorClickableText: Colors.blue,
        delimiter: "\n\n",
        trimMode: TrimMode.Line,
        trimCollapsedText: 'SHOW MORE',
        trimExpandedText: 'SHOW LESS',
        moreStyle: TextPalette.linkStyle,
        lessStyle: TextPalette.linkStyle,
      ),
      // Text("Rule" * 100, style: TextPalette.bodyText2Gray)
    ]));
  }
}

class MapCard extends StatelessWidget {
  final SportCenter sportCenter;

  final margin;
  final width;
  final height;

  MapCard.big(this.sportCenter)
      : margin = EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        height = 100.0,
        width = null;

  @override
  Widget build(BuildContext context) {
    // fixme for some reason if we use InfoContainer it doesn't work https://stackoverflow.com/questions/53972558/how-to-add-border-radius-to-google-maps-in-flutter
    return InkWell(
      child: Container(
        margin: margin,
        child: ClipRRect(
          borderRadius: InfoContainer.borderRadius,
          child: SizedBox(
              height: height,
              width: width,
              child: GoogleMap(
                onTap: (LatLng latLng) async {
                  print("launching" + latLng.toString());
                  MapsLauncher.launchCoordinates(
                      sportCenter.lat, sportCenter.lng, sportCenter.name);
                },
                myLocationButtonEnabled: false,
                zoomGesturesEnabled: false,
                markers: {
                  Marker(
                      markerId: MarkerId(sportCenter.placeId),
                      position: LatLng(sportCenter.lat, sportCenter.lng))
                },
                initialCameraPosition: CameraPosition(
                    target: LatLng(sportCenter.lat, sportCenter.lng), zoom: 12),
              )),
        ),
      ),
    );
  }
}

class BottomBar extends StatelessWidget {
  final Match match;

  const BottomBar({Key key, this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var isUserGoing = context.watch<UserChangeNotifier>().isLoggedIn() &&
        match.isUserGoing(context.watch<UserChangeNotifier>().getUserDetails());

    return Container(
        height: 100,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      (isUserGoing)
                          ? "You are going!"
                          : match.getSpotsLeft().toString() + " spots left",
                      style: TextPalette.h2),
                  if (!isUserGoing)
                    Text(formatCurrency.format(match.getPrice()))
                ],
              ),
              (isUserGoing)
                  ? RoundedButton("LEAVE GAME", () async {
                      var hasUserConfirmed = await showModalBottomSheet(
                          context: context,
                          builder: (context) => LeaveMatchConfirmation(match)
                      );
                      print("return from bottom sheet " +
                          hasUserConfirmed.toString());
                    })
                  : RoundedButton("JOIN GAME", () async {
                      if (!context.read<UserChangeNotifier>().isLoggedIn()) {
                        bool couldLogIn = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Login()))
                            .then((isLoginSuccessfull) => isLoginSuccessfull);

                        if (!couldLogIn) {
                          CoolAlert.show(
                              context: context,
                              type: CoolAlertType.error,
                              text: "Could not loging");
                          Navigator.pop(context);
                          return;
                        }
                      }

                      var value = await showModalBottomSheet(
                          context: context,
                          builder: (context) =>
                              PrepaymentBottomBar(match: match));
                      if (value == "success") {
                        await context.read<MatchesChangeNotifier>().joinMatch(
                            match,
                            context
                                .read<UserChangeNotifier>()
                                .getUserDetails());
                        showModalBottomSheet(
                            context: context,
                            builder: (context) => PostPaymentBottomBar(match: match));
                      } else if (value == "payment-failed") {
                        CoolAlert.show(
                            context: context,
                            type: CoolAlertType.error,
                            text: "Payment failed");
                      }
                    })
            ],
          ),
        ));
  }
}

class PrepaymentBottomBar extends StatelessWidget {
  final Match match;

  const PrepaymentBottomBar({Key key, this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // fixme why not having borders?
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.only(topRight: Radius.circular(10)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
                padding: EdgeInsets.only(bottom: 20.0),
                child: Text("Join this game", style: TextPalette.h2)),
            Text(
              "You can cancel up to 24h before the game starting time to get a full refund in credits to use on your next game. \n After that you won't get a refund.",
              style: TextPalette.bodyText,
            ),
            Divider(),
            Row(
              children: [
                CircleAvatar(
                    backgroundImage: NetworkImage(context
                        .watch<UserChangeNotifier>()
                        .getUserDetails()
                        .getPhotoUrl()),
                    radius: 15),
                SizedBox(width: 30),
                Text("1x player", style: TextPalette.h3),
                Expanded(
                    child: Text(
                  match.getFormattedPrice() + " euro",
                  style: TextPalette.h3,
                  textAlign: TextAlign.end,
                ))
              ],
            ),
            Divider(),
            Row(
              children: [
                Expanded(
                  child: RoundedButton("CONTINUE TO PAYMENT", () async {
                    final stripeCustomerId = await context
                        .read<UserChangeNotifier>()
                        .getOrCreateStripeId();
                    print("stripeCustomerId " + stripeCustomerId);
                    final sessionId = await Server().createCheckout(
                        stripeCustomerId, match.pricePerPersonInCents);
                    print("sessId " + sessionId);

                    var value = await Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => CheckoutPage(sessionId: sessionId)));

                    // remove previous bottom sheet
                    Navigator.pop(context, value);
                  }),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class PostPaymentBottomBar extends StatelessWidget {
  final Match match;

  const PostPaymentBottomBar({Key key, this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // fixme why not having borders?
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.only(topRight: Radius.circular(10)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
                padding: EdgeInsets.only(bottom: 20.0),
                child: Text("You are going to this game", style: TextPalette.h2)),
            Padding(
              padding: EdgeInsets.only(bottom: 20.0),
              child: Text(
                "You have successfully paid and joined this game.",
                style: TextPalette.bodyText,
              ),
            ),
            InkWell(
              child: Row(
                children: [
                  Icon(Icons.share, color: Palette.primary),
                  SizedBox(width: 20),
                  Text("SHARE", style: TextPalette.linkStyle)
                ],
              ),
              onTap: () => CoolAlert.show(context: context, type: CoolAlertType.info, text: "Implement this"),
            ),
          ],
        ),
      ),
    );
  }
}

// widget to show when user is leaving
class LeaveMatchConfirmation extends StatelessWidget {
  final Match match;

  LeaveMatchConfirmation(this.match);

  @override
  Widget build(BuildContext context) {
    return Container(
      // fixme why not having borders?
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.only(topRight: Radius.circular(10)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
                padding: EdgeInsets.only(bottom: 20.0),
                child: Text("Leaving this game?", style: TextPalette.h2)),
            Text(
              "We will refund you in credits that you can use in your next games. (HERE WE NEED TO DISABLE THINGS IF WE ARE < 24 H).",
              style: TextPalette.bodyText,
            ),
            Divider(),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                children: [
                  Text("Credits refund", style: TextPalette.h3),
                  Expanded(
                      child: Text(
                        match.getFormattedPrice() + " euro",
                        style: TextPalette.h3,
                        textAlign: TextAlign.end,
                      ))
                ],
              ),
            ),
            Divider(),
            Row(
              children: [
                Expanded(
                  child: RoundedButton("CONFIRM", () async {
                    await context.read<MatchesChangeNotifier>().leaveMatch(
                        match,
                        context
                            .read<UserChangeNotifier>()
                            .getUserDetails());
                    Navigator.pop(context);
                  }),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
