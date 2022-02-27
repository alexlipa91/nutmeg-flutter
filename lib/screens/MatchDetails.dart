import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:map_launcher/src/models.dart' as m;
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/controller/SportCentersController.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/screens/JoinModal.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/AppBar.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/PlayerBottomModal.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:provider/provider.dart';
import 'package:readmore/readmore.dart';
import 'package:shimmer/shimmer.dart';

import 'BottomBarMatch.dart';

class ScreenArguments {
  final String matchId;
  final bool isPast;

  ScreenArguments(this.matchId, this.isPast);
}

class MatchDetails extends StatefulWidget {
  static const routeName = "/match";

  @override
  State<StatefulWidget> createState() {
    return MatchDetailsState();
  }
}

class MatchDetailsState extends State<MatchDetails> {
  Match match;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      var userState = context.read<UserState>();
      var matchesState = context.read<MatchesState>();

      await FirebaseRemoteConfig.instance.fetch();
      await MatchesController.refresh(
          matchesState, userState, match.documentId);

      await Future.wait(
          match.going.keys.map((e) => UserController.getUserDetails(e)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context).settings.arguments as ScreenArguments;
    var matchesState = context.watch<MatchesState>();
    var userState = context.watch<UserState>();

    match = matchesState.getMatch(args.matchId);

    if (match == null) {
      return Container();
    }
    var matchId = args.matchId;

    var loadOnceState = context.read<LoadOnceState>();

    var sportCenter = loadOnceState.getSportCenter(match.sportCenterId);
    var sport = loadOnceState.getSport(match.sport);

    var title = (match.isTest)
        ? match.documentId
        : sportCenter.name + " - " + sport.displayTitle;

    pad(Widget w) =>
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: w);

    // add padding individually since because of shadow clipping some components need margin
    var widgets = [
      pad(Container(
          color: (match.isTest) ? Colors.orangeAccent : Colors.transparent,
          child: Text(title, style: TextPalette.h1Default))),
      SizedBox(height: 16),
      MatchInfo(match, sportCenter, sport),
      pad(Builder(
        builder: (context) {
          int going = match.numPlayersGoing();
          return Section(
            title: going.toString() +
                "/" +
                match.maxPlayers.toString() +
                " PLAYERS JOINED",
            body: SingleChildScrollView(
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              child: Row(
                  children: (match.going.isEmpty)
                      ? [EmptyPlayerCard(match: match)]
                      : match
                          .getGoingUsersByTime()
                          .map((s) => PlayerCard(s))
                          .toList()),
            ),
          );
        },
      )),
      pad(Section(
          title: "DETAILS",
          body: RuleCard(
              "Payment Policy",
              "If you leave the match more than 15 hours before the kick-off time the amount you paid will be returned to you in credits that you can use in other Nutmeg matches. "
                  "\n\nNo credits or refund will be provided if you drop out of a game less than 15 hours from kick-off."))),
      SizedBox(height: 200),
      // MapCard.big(sportCenter)
    ];

    return Scaffold(
        backgroundColor: Palette.light,
        body: RefreshIndicator(
            onRefresh: () async {
              await MatchesController.refresh(matchesState, userState, matchId);
            },
            child: CustomScrollView(
              slivers: [
                MatchAppBar(matchId: matchId),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return widgets[index];
                    },
                    childCount: widgets.length,
                  ),
                )
              ],
            )),
        bottomSheet: BottomBarMatch(
          match: match,
          extraBottomPadding: MediaQuery.of(context).padding.bottom,
        ));
  }
}

// info card
class MatchInfo extends StatelessWidget {
  static var dateFormat = DateFormat('MMMM dd \'at\' HH:mm');

  final Match match;
  final SportCenter sportCenter;
  final Sport sport;

  MatchInfo(this.match, this.sportCenter, this.sport);

  @override
  Widget build(BuildContext context) {
    return InfoContainer(
        margin: EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Expanded(child: SportCenterImageCarousel(match))]),
            InfoWidget(
                title: getFormattedDateLong(match.dateTime),
                subTitle: getStartAndEndHour(match.dateTime, match.duration)
                        .join(" - ") +
                    " - " +
                    match.duration.inMinutes.toString() +
                    " min",
                icon: Icons.schedule),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  if (await MapLauncher.isMapAvailable(m.MapType.google)) {
                    await MapLauncher.showMarker(
                      mapType: m.MapType.google,
                      coords: Coords(sportCenter.lat, sportCenter.lng),
                      title: "",
                      extraParams: {
                        "q": sportCenter.name + "," + sportCenter.address,
                        "z": "16"
                      },
                    );
                  } else if (await MapLauncher.isMapAvailable(
                      m.MapType.apple)) {
                    await MapLauncher.showMarker(
                      mapType: m.MapType.apple,
                      coords: Coords(sportCenter.lat, sportCenter.lng),
                      title: "",
                      // fixme do something
                    );
                  } else {
                    // fixme do something
                  }
                },
                splashColor: Palette.lighterGrey,
                child: InfoWidget.withRightWidget(
                    title: sportCenter.name +
                        (match.sportCenterSubLocation != null &&
                                match.sportCenterSubLocation.isNotEmpty
                            ? " - " + match.sportCenterSubLocation
                            : ""),
                    icon: Icons.place,
                    subTitle: sportCenter.getShortAddress(),
                    rightWidget: ClipRRect(
                        borderRadius: BorderRadius.circular(15.0),
                        child: Image.asset("assets/map.png", height: 45))),
              ),
            ),
            InfoWidget(
                title: sport.displayTitle,
                icon: Icons.sports_soccer,
                // todo fix info sport
                subTitle: sportCenter.tags.join(", ")),
            InfoWidget(
                title: formatCurrency(match.pricePerPersonInCents),
                icon: Icons.sell,
                subTitle: "Pay with Ideal"),
          ],
        ));
  }
}

class SportCenterImageCarousel extends StatefulWidget {
  final Match match;

  const SportCenterImageCarousel(this.match);

  @override
  State<StatefulWidget> createState() => SportCenterImageCarouselState(match);
}

class SportCenterImageCarouselState extends State<SportCenterImageCarousel> {
  int _current = 0;
  final Match match;
  final CarouselController _controller = CarouselController();

  SportCenterImageCarouselState(this.match);

  @override
  Widget build(BuildContext context) {
    var placeHolder = Container(
        height: 358,
        child: Shimmer.fromColors(
          baseColor: Palette.lighterGrey,
          highlightColor: Palette.lighterGrey,
          child: Container(
              decoration: BoxDecoration(
                  color: Palette.white,
                  borderRadius: BorderRadius.all(Radius.circular(10)))),
        ));

    return FutureBuilder(
        future: SportCentersController.getSportCenterPicturesUrls(
            match.sportCenterId),
        builder: (context, snapshot) {
          List<Widget> itemsToShow = (snapshot.hasData)
              ? List<Widget>.from(snapshot.data.map((i) => CachedNetworkImage(
                    imageUrl: i,
                    fadeInDuration: Duration(milliseconds: 0),
                    imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.fill,
                      ),
                    )),
                    placeholder: (context, imageProvider) => placeHolder,
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  )))
              : List<Widget>.from([placeHolder]);

          return Stack(
            children: [
              // fixme check animation when slide
              ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(15)),
                child: CarouselSlider(
                  carouselController: _controller,
                  options: CarouselOptions(
                      enableInfiniteScroll: false,
                      viewportFraction: 1,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _current = index;
                        });
                      }),
                  items: itemsToShow,
                ),
              ),
              Positioned(
                bottom: 10,
                left: 1,
                right: 1,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: itemsToShow.asMap().entries.map((entry) {
                      return GestureDetector(
                        onTap: () => _controller.animateToPage(entry.key),
                        child: Container(
                          width: 12.0,
                          height: 12.0,
                          margin: EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 4.0),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (itemsToShow.length > 1)
                                  ? Colors.white.withOpacity(
                                      _current == entry.key ? 0.9 : 0.4)
                                  : Colors.transparent),
                        ),
                      );
                    }).toList()),
              ),
            ],
          );
        });
  }
}

// single line with icon and texts in the info card
class InfoWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final String subTitle;

  final Widget rightWidget;

  InfoWidget({this.title, this.icon, this.subTitle}) : rightWidget = null;

  InfoWidget.withRightWidget(
      {this.title, this.icon, this.subTitle, Widget rightWidget})
      : rightWidget = rightWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(left: 15, top: 15, bottom: 10),
        child: Row(
          children: [
            new Icon(
              icon,
              size: 20,
              color: UiUtils.fromHex("#999999"),
            ),
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
                if (subTitle != null)
                  Text(subTitle, style: TextPalette.bodyText)
              ],
            ),
            if (rightWidget != null)
              Expanded(
                  child: Padding(
                padding: EdgeInsets.only(right: 25),
                child:
                    Align(alignment: Alignment.centerRight, child: rightWidget),
              ))
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
    var userData = UsersState.getUserDetails(userId);
    return Padding(
        padding: EdgeInsets.only(right: 10),
        child: SizedBox(
          width: 100,
          child: InfoContainer(
              child: Column(children: [
            InkWell(
                onTap: () {
                  showModalBottomSheet(
                      context: context,
                      builder: (context) =>
                          PlayerBottomModal(userDetails: userData));
                },
                child: UserAvatar(24, UsersState.getUserDetails(userId))),
            SizedBox(height: 10),
            Text((userData?.name ?? "Player").split(" ").first,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                    color: Palette.mediumgrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w400))
          ])),
        ));
  }
}

class EmptyPlayerCard extends StatelessWidget {
  final Match match;

  const EmptyPlayerCard({Key key, this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(right: 10),
        child: SizedBox(
          width: 100,
          child: InfoContainer(
              child: Column(children: [
            InkWell(
              onTap: () => JoinModal.onJoinGameAction(context, match),
              child: CircleAvatar(
                  radius: 25,
                  child: Icon(Icons.add, color: Palette.mediumgrey, size: 24),
                  backgroundColor: Palette.lighterGrey),
            ),
            SizedBox(height: 10),
            Text("Join",
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                    color: Palette.mediumgrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w400))
          ])),
        ));
  }

  Widget buildCard(String text) {}
}

// single rule card
class RuleCard extends StatelessWidget {
  final String title;
  final String body;

  const RuleCard(this.title, this.body);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return InfoContainer(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(title, style: TextPalette.h2),
      SizedBox(height: 10),
      ReadMoreText(
        body,
        style: TextPalette.bodyText,
        trimLines: 4,
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
      : margin = EdgeInsets.only(right: 25, left: 25, bottom: 10),
        height = 150.0,
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
                  if (await MapLauncher.isMapAvailable(m.MapType.google)) {
                    await MapLauncher.showMarker(
                      mapType: m.MapType.google,
                      coords: Coords(sportCenter.lat, sportCenter.lng),
                      title: "",
                      extraParams: {
                        "q": sportCenter.name + "," + sportCenter.address,
                        "z": "16"
                      },
                    );
                  } else if (await MapLauncher.isMapAvailable(
                      m.MapType.apple)) {
                    await MapLauncher.showMarker(
                      mapType: m.MapType.apple,
                      coords: Coords(sportCenter.lat, sportCenter.lng),
                      title: "",
                      // fixme do something
                    );
                  } else {
                    // fixme do something
                  }
                },
                liteModeEnabled: true,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomGesturesEnabled: false,
                zoomControlsEnabled: false,
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
