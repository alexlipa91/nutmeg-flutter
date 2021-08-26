import 'dart:async';
import 'dart:io';

import 'package:cool_alert/cool_alert.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/screens/PaymentPage.dart';
import 'package:nutmeg/utils/LocationUtils.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/AppBar.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:readmore/readmore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
    SportCenter sportCenter = context
        .read<SportCentersChangeNotifier>()
        .getSportCenter(match.sportCenter);

    var title =
        sportCenter.neighbourhood + " - " + match.sport.getDisplayTitle();

    return Scaffold(
      appBar: SecondaryAppBar(),
      body: SingleChildScrollView(
        child: Column(
          // fixme here we are repeating the padding just because cannot be applied globally as MatchInfo doesn't need
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 25),
                child: Text(title, style: TextPalette.h1Black)),
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
                    children: List.filled(
                  15,
                  PlayerCard(
                      name: "Andre",
                      imageUrl:
                          "https://lh3.googleusercontent.com/a-/AOh14GhDr8xTqP9vgkx2VYKVYLm3NHfG9zBtauDSizxNhfs=s96-c"),
                )),
              ),
            ),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                child: Text("Details")),
            RuleCard(),
            RuleCard(),
            MapCard(placeId: sportCenter.placeId)
          ],
        ),
      ),
      bottomNavigationBar:
          Container(height: 50, color: Colors.red, child: Text("Join Here")),
    );
  }
}

class MatchInfo extends StatelessWidget {
  static var formatCurrency = NumberFormat.simpleCurrency(name: "EUR");
  static var dateFormat = DateFormat('MMMM dd \'at\' HH:mm');

  final Match match;
  final SportCenter sportCenter;

  MatchInfo(this.match, this.sportCenter);

  @override
  Widget build(BuildContext context) {
    return InfoContainer.withoutMargin(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
              child: SportCenterImageCarousel(
                  images: sportCenter.getMainPicturesListUrls()))
        ]),
        InfoWidget(title: dateFormat.format(match.dateTime), icon: Icons.watch),
        InkWell(
          child: InfoWidget(
              title: sportCenter.name,
              icon: Icons.place,
              subTitle: sportCenter.getShortAddress()),
          onTap: () async {
            String googleUrl =
                "https://www.google.com/maps/search/?api=1&query=Google&query_place_id=" +
                    sportCenter.placeId;

            if (await canLaunch(googleUrl)) {
              await launch(googleUrl);
            } else {
              // throw 'Could not open the map.';
              CoolAlert.show(
                  context: context,
                  type: CoolAlertType.error,
                  text: "Could not open maps");
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

class InfoWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final String subTitle;

  const InfoWidget({Key key, this.title, this.icon, this.subTitle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        child: Row(
          children: [
            new Icon(icon),
            SizedBox(
              width: 20,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextPalette.h2Black),
                SizedBox(
                  height: 5,
                ),
                if (subTitle != null)
                  Text(subTitle, style: TextPalette.bodyText2Black)
              ],
            )
          ],
        ));
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
        margin: EdgeInsets.only(right: 10),
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

class RuleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return InfoContainer(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Title", style: TextPalette.h2Black),
      SizedBox(height: 10),
      ReadMoreText(
        'Flutter is Google’s mobile UI open source framework to build high-quality native (super fast) interfaces for iOS and Android apps with the unified codebase.',
        style: TextPalette.bodyText2Black,
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
  final String placeId;

  const MapCard({Key key, this.placeId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // fixme for some reason if we use InfoContainer it doesn't work https://stackoverflow.com/questions/53972558/how-to-add-border-radius-to-google-maps-in-flutter
    return InkWell(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        child: ClipRRect(
          borderRadius: InfoContainer.borderRadius,
          child: SizedBox(
            height: 100,
            child: FutureBuilder<LatLng>(
                future: LocationUtils.getPlaceCoordinates(placeId),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return GoogleMap(
                      onTap: (LatLng latLng) async {
                        // String url;
                        //
                        // if (Platform.isIOS) {
                        //   // iOS
                        //   url = 'http://maps.apple.com/?q=${snapshot.data.latitude},${snapshot.data.longitude}';
                        // } else {
                        //   url =
                        //       "https://www.google.com/maps/search/?api=1&query=Google&query_place_id=" +
                        //           placeId;
                        // }
                        // if (await canLaunch(url)) {
                        //   await launch(url);
                        // } else {
                        //   // throw 'Could not open the map.';
                        //   CoolAlert.show(
                        //       context: context,
                        //       type: CoolAlertType.error,
                        //       text: "Could not open maps");
                        // }
                        MapsLauncher.launchCoordinates(snapshot.data.latitude, snapshot.data.longitude);
                      },
                      myLocationButtonEnabled: false,
                      zoomGesturesEnabled: false,
                      markers: {
                        Marker(
                            markerId: MarkerId("id"),
                            position: snapshot.data)
                      },
                      initialCameraPosition: CameraPosition(
                          target: snapshot.data,
                          zoom: 12),
                    );
                  }
                  return Text("put skeleton here");
                }),
          ),
        ),
      ),
    );

    // TODO: implement build
    // return InfoContainer.withoutMargin(
    //   child: SizedBox(
    //     height: 100,
    //     // child: Container()
    //     child: GoogleMap(
    //       initialCameraPosition: _kInitialPosition,
    //     ),
    //   ),
    // );
  }
}
