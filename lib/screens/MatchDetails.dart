import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:map_launcher/src/models.dart' as m;
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/controller/SportCentersController.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/model/UserDetails.dart';
import 'package:nutmeg/screens/JoinModal.dart';
import 'package:nutmeg/screens/RatePlayersModal.dart';
import 'package:nutmeg/state/MatchStatsState.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/AppBar.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/GenericAvailableMatches.dart';
import 'package:nutmeg/widgets/PlayerBottomModal.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:provider/provider.dart';
import 'package:readmore/readmore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';


import '../model/SportCenter.dart';
import '../state/LoadOnceState.dart';
import '../state/MatchesState.dart';
import '../state/UserState.dart';
import '../widgets/Skeletons.dart';
import 'BottomBarMatch.dart';

class ScreenArguments {
  final String matchId;

  ScreenArguments(this.matchId);
}

class MatchDetails extends StatefulWidget {
  static const routeName = "/match";

  @override
  State<StatefulWidget> createState() =>
      MatchDetailsState(Get.parameters["matchId"]);
}

class MatchDetailsState extends State<MatchDetails> {
  final String matchId;

  MatchDetailsState(this.matchId);

  Future<void> refreshState() async {
    // refresh details
    var match = await MatchesController.refresh(context, matchId);

    // get users details
    Future.wait(
        match.going.keys.map((e) => UserController.getUserDetails(context, e)));

    // get status
    var statusAndUsers =
        await MatchesController.refreshMatchStatus(context, match);

    var status = statusAndUsers.item1;

    if (status == MatchStatusForUser.to_rate) {
      await RatePlayerBottomModal.rateAction(context, matchId);
    } else if (status == MatchStatusForUser.rated) {
      MatchesController.refreshMatchStats(context, matchId);
    }

    UserController.getBatchUserDetails(context, match.going.keys.toList());
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await refreshState();
    });
  }

  @override
  Widget build(BuildContext context) {
    var matchesState = context.watch<MatchesState>();
    var match = matchesState.getMatch(matchId);

    var loadOnceState = context.read<LoadOnceState>();

    var sportCenter;
    var sport;
    var title = "";
    var isTest = false;

    if (match != null) {
      isTest = isTest;
      sportCenter = loadOnceState.getSportCenter(match.sportCenterId);
      sport = loadOnceState.getSport(match.sport);
      title = (match.isTest)
          ? match.documentId
          : sportCenter.name + " - " + sport.displayTitle;
    }

    var matchStatus = matchesState.getMatchStatus(matchId);

    padLRB(Widget w) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child: w);

    // add padding individually since because of shadow clipping some components need margin
    var widgets = [
      // title
      if (match != null)
        padLRB(Container(
            color: (isTest) ? Colors.orangeAccent : Colors.transparent,
            child: Text(title, style: TextPalette.h1Default))),
      // info box
      padLRB(MatchInfo(matchId)),
      // horizontal players list
      if (match != null && matchStatus != MatchStatusForUser.rated)
        padLRB(Builder(
          builder: (context) {
            var title = (match == null)
                ? ""
                : match.numPlayersGoing().toString() +
                    "/" +
                    match.maxPlayers.toString() +
                    " PLAYERS";

            return Section(
              title: title,
              body: SingleChildScrollView(
                clipBehavior: Clip.none,
                scrollDirection: Axis.horizontal,
                child: Row(
                    children: (match.going.isEmpty)
                        ? [EmptyPlayerCard(matchId: matchId)]
                        : match
                            .getGoingUsersByTime()
                            .map((s) => PlayerCard(s))
                            .toList()),
              ),
            );
          },
        )),
      if (matchStatus == MatchStatusForUser.rated && match.manOfTheMatch == context.read<UserState>().currentUserId)
        padLRB(Section(title: "POTM", body: InkWell(
          onTap: () => Get.toNamed("/potm/" + matchId),
          child: InfoContainer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Congratulations!",
                        style: GoogleFonts.roboto(color: Palette.black, fontSize: 20, fontWeight: FontWeight.w500)),
                    SizedBox(height: 16,),
                    Text("You are the Player of the Match",
                        style: GoogleFonts.roboto(color: Palette.mediumgrey, fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
                Icon(MdiIcons.trophy, color: Palette.accent, size: 50,),
              ],
            ),
          ),
        ))),
      // stats
      if (matchStatus == MatchStatusForUser.rated ||
          matchStatus == MatchStatusForUser.no_more_to_rate)
        padLRB(Stats(
          matchStatusForUser: matchStatus,
          matchDatetime: match.dateTime,
        )),
      // payment policy
      if (!MatchesState.pastStates.contains(matchStatus))
        padLRB(Section(
            title: "DETAILS",
            body: RuleCard(
                "Payment Policy",
                "If you leave the match more than 15 hours before the kick-off time the amount you paid will be returned to you in credits that you can use in other Nutmeg matches. "
                    "\n\nNo credits or refund will be provided if you drop out of a game less than 15 hours from kick-off."))),
      // MapCard.big(sportCenter)
    ];

    return Scaffold(
        backgroundColor: Palette.grey_lightest,
        body: RefreshIndicator(
            onRefresh: () async {
              await refreshState();
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
        bottomNavigationBar: BottomBarMatch(
          matchId: matchId,
          extraBottomPadding: MediaQuery.of(context).padding.bottom,
        ));
  }
}

// info card
class MatchInfo extends StatelessWidget {
  static var dateFormat = DateFormat('MMMM dd \'at\' HH:mm');

  final String matchId;

  MatchInfo(this.matchId);

  @override
  Widget build(BuildContext context) {
    var match = context.watch<MatchesState>().getMatch(matchId);
    if (match == null) return SkeletonMatchDetails();

    var sportCenter =
        context.watch<LoadOnceState>().getSportCenter(match.sportCenterId);
    var sport = context.watch<LoadOnceState>().getSport(match.sport);

    if (sportCenter == null || sport == null) {
      return MatchInfoSkeleton();
    }
    return InfoContainer(
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
                splashColor: Palette.grey_lighter,
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
          baseColor: Palette.grey_lighter,
          highlightColor: Palette.grey_lighter,
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
                    fadeOutDuration: Duration(milliseconds: 0),
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
    var userData = context.watch<UserState>().getUserDetail(userId);
    var placeHolder = Shimmer.fromColors(
        baseColor: Colors.grey[300],
        highlightColor: Colors.grey[100],
        child: Column(children: [
          CircleAvatar(radius: 25, backgroundColor: Palette.white),
          SizedBox(height: 10),
          Container(height: 10, width: 100, color: Colors.white)
        ]));

    return Padding(
        padding: EdgeInsets.only(right: 10),
        child: SizedBox(
          width: 100,
          child: InfoContainer(
              child: (userData == null)
                  ? placeHolder
                  : Column(children: [
                      InkWell(
                          onTap: () {
                            showModalBottomSheet(
                                context: context,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20.0)),
                                ),
                                builder: (context) =>
                                    JoinedPlayerBottomModal(userData));
                          },
                          child: UserAvatar(24, userData)),
                      SizedBox(height: 10),
                      Text((userData?.name ?? "Player").split(" ").first,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                              color: Palette.grey_dark,
                              fontSize: 12,
                              fontWeight: FontWeight.w400))
                    ])),
        ));
  }
}

class EmptyPlayerCard extends StatelessWidget {
  final String matchId;

  const EmptyPlayerCard({Key key, this.matchId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(right: 10),
        child: SizedBox(
          width: 100,
          child: InfoContainer(
              child: Column(children: [
            InkWell(
              onTap: () => JoinModal.onJoinGameAction(context, matchId),
              child: CircleAvatar(
                  radius: 25,
                  child: Icon(Icons.add, color: Palette.grey_dark, size: 24),
                  backgroundColor: Palette.grey_lighter),
            ),
            SizedBox(height: 10),
            Text("Join",
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                    color: Palette.grey_dark,
                    fontSize: 12,
                    fontWeight: FontWeight.w400))
          ])),
        ));
  }
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

class Stats extends StatelessWidget {
  final MatchStatusForUser matchStatusForUser;
  final DateTime matchDatetime;

  const Stats({Key key, this.matchStatusForUser, this.matchDatetime})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var child;

    if (matchStatusForUser == MatchStatusForUser.no_more_to_rate) {
      child = Container(
          width: double.infinity,
          child: Column(
            children: [
              Icon(
                Icons.timeline,
                size: 80,
                color: Palette.grey_light,
              ),
              SizedBox(
                height: 16,
              ),
              Text(
                "Stats available soon",
                style: TextPalette.h2,
              ),
              SizedBox(
                height: 16,
              ),
              Text(
                "Statistics for this match will be available on " +
                    getFormattedDate(matchDatetime.add(Duration(days: 1))),
                style: TextPalette.bodyText,
                textAlign: TextAlign.center,
              ),
            ],
          ));
    } else {
      var ratings = context.watch<MatchStatState>().ratings;
      var userState = context.watch<UserState>();

      var loadSkeleton =
          (ratings == null || ratings.isEmpty || userState == null);
      child = (loadSkeleton)
          ? StatsSkeleton()
          : Builder(
              builder: (context) {
                var sorted = ratings.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                int index = 1;

                return Container(
                  child: Column(
                    children: sorted.map((e) {
                      var user = e.key;
                      var score = e.value;

                      var userDetails = userState.getUserDetail(user);

                      var widgets = [
                        Container(
                            width: 18,
                            child: Text(index.toString(),
                                style: TextPalette.bodyText)),
                        SizedBox(width: 8),
                        UserAvatar(10, userDetails),
                        SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Builder(builder: (context) {
                                // fixme text overflow
                                var name =
                                    UserDetails.getDisplayName(userDetails)
                                        .split(" ")
                                        .first;
                                var n = name.substring(0, min(name.length, 11));
                                return Text(n,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextPalette.bodyText);
                              }),
                              SizedBox(width: 1),
                              if (index == 1)
                                Icon(
                                  Icons.sports_soccer,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                        Container(
                          height: 10,
                          width: 100,
                          child: ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            child: LinearProgressIndicator(
                              value: score / 5,
                              color: Palette.primary,
                              backgroundColor: Palette.grey_light,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Container(
                          width: 22,
                          child: Text((score == 0) ? "  -" : score.toStringAsFixed(1),
                              style: TextPalette.bodyText),
                        ),
                      ];

                      index++;
                      return Padding(
                          padding: (index > 2)
                              ? EdgeInsets.only(top: 16)
                              : EdgeInsets.zero,
                          child: InkWell(
                              onTap: () => showModalBottomSheet(
                                  context: context,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20.0)),
                                  ),
                                  builder: (context) =>
                                      JoinedPlayerBottomModal(userDetails)),
                              child: Row(children: widgets)));
                    }).toList(),
                  ),
                );
              },
            );
    }

    return Container(
      // color: Colors.red,
      child: Section(
        title: "MATCH STATS",
        body: InfoContainer(child: child),
      ),
    );
  }
}
