import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:map_launcher/src/models.dart' as m;
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/model/UserDetails.dart';
import 'package:nutmeg/screens/JoinModal.dart';
import 'package:nutmeg/screens/RatePlayersModal.dart';
import 'package:nutmeg/screens/UserPage.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/PageTemplate.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:provider/provider.dart';
import 'package:readmore/readmore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletons/skeletons.dart';

import '../state/LoadOnceState.dart';
import '../state/MatchesState.dart';
import '../state/UserState.dart';
import '../widgets/Buttons.dart' as buttons;
import '../widgets/ModalBottomSheet.dart';
import '../widgets/PlayerBottomModal.dart';
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
    List<Future<dynamic>> futures = [
      context.read<MatchesState>().fetchRatings(matchId),
      MatchesController.refresh(context, matchId)
    ];

    var res = await Future.wait(futures);

    Match match = res[1];

    // get users details
    UserController.getBatchUserDetails(context, match.getGoingUsersByTime());

    // get organizer details
    UserController.getUserDetails(context, match.organizerId);

    // fetch on-boarding url if needed
    context.read<UserState>().fetchOnboardingUrl(match.isTest);
  }

  @override
  void initState() {
    super.initState();
    // show potm
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      // show rating modal
      var statusForUser = context.read<MatchesState>()
          .getMatchStatusForUser(matchId,
          context.read<UserState>().getLoggedUserDetails());

      if (statusForUser == MatchStatusForUser.to_rate) {
        await RatePlayerBottomModal.rateAction(context, matchId);
        setState(() {});
      }

      // go to potm
      var prefs = await SharedPreferences.getInstance();
      var currentUser = context.read<UserState>().currentUserId;
      var preferencePath = "potm_screen_showed_" + matchId + "_"
          + currentUser;
      var alreadyShown = prefs.getBool(preferencePath) ?? false;

      if (context.read<UserState>().isLoggedIn()
          && context.read<MatchesState>()
              .getMatch(matchId).getPotms().contains(currentUser)
          && !alreadyShown) {
        Get.toNamed("/potm/" + currentUser);
        prefs.setBool(preferencePath, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var userState = context.watch<UserState>();
    var matchesState = context.watch<MatchesState>();
    var match = matchesState.getMatch(matchId);

    var status = match?.status;
    var statusForUser = context.read<MatchesState>().getMatchStatusForUser(matchId,
        context.read<UserState>().getLoggedUserDetails());

    var isTest = match != null && match.isTest;
    var organizerView = userState.isLoggedIn() &&
        match != null &&
        match.organizerId == userState.getLoggedUserDetails().documentId;

    padB(Widget w) => Padding(padding: EdgeInsets.only(bottom: 16), child: w);

    var bottomBar = BottomBarMatch.getBottomBar(context,
        matchId, status);

    // add padding individually since because of shadow clipping some components need margin
    var widgets = [
      // title
      if (organizerView &&
          userState.getOnboardingUrl(isTest) != null)
        padB(CompleteOrganiserAccountWidget(isTest: isTest)),
      padB(Title(matchId)),
      if (isTest)
        padB(InfoContainer(backgroundColor: Palette.accent,
            child: SelectableText("Test match: " + matchId, style: TextPalette.getBodyText(Palette.black),))),
      // info box
      MatchInfo(matchId),
      // stats
      if (status == MatchStatus.rated ||
          statusForUser == MatchStatusForUser.no_more_to_rate)
        Stats(matchId: matchId, matchDatetime: match.dateTime,
            matchStatusForUser: statusForUser),
      // horizontal players list
      if (match != null) PlayerList(match: match),
      if (match != null && match.dateTime.isAfter(DateTime.now()))
        Section(
            title: "DETAILS",
            body: Column(
              children: [
                RuleCard(
                    "Payment Policy",
                    ConfigsUtils.removeCreditsFunctionality() ?
                    "If you leave the match or the match is canceled you will get a refund on the payment method you used to pay.\n\n"
                            "If you don’t show up you won’t get a refund." :
                    "If you leave the match you will get a refund in credits that you can use for other Nutmeg matches.\n\n" +
                        "If the match is canceled by the organizer, you will get a refund on the payment method you used to pay.\n\n"
                            "If you don’t show up you won’t get a refund."),
                SizedBox(height: 16.0),
                MapCardImage(matchId),
                SizedBox(height: 16.0),
                if (match != null && match.organizerId != null)
                  Builder(builder: (context) {
                    var ud = context
                        .watch<UserState>()
                        .getUserDetail(match.organizerId);

                    return InfoContainer(
                        child: Row(children: [
                      (ud != null && ud.isAdmin)
                          ? NutmegAvatar(24.0)
                          : UserAvatarWithBottomModal(userData: ud),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Organized by", style: TextPalette.bodyText),
                            SizedBox(height: 4),
                            (ud == null)
                                ? Skeletons.lText
                                : Text(
                                    (ud.isAdmin)
                                        ? "Nutmeg"
                                        : ud.name.split(" ").first,
                                    style: TextPalette.h2),
                          ],
                        ),
                      ),
                    ]));
                  }),
              ],
            )),
    ];

    return PageTemplate(
      refreshState: () => refreshState(),
      widgets: widgets,
      appBar: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BackButton(color: Palette.black),
          if (!DeviceInfo().name.contains("ipad"))
            Align(
                alignment: Alignment.centerRight,
                child: buttons.ShareButton(() async {
                  await DynamicLinks.shareMatchFunction(matchId);
                }, Palette.black, 25.0)),
        ],
      ),
      bottomNavigationBar: bottomBar,
    );
  }
}

class PlayerList extends StatelessWidget {
  final Match match;

  const PlayerList({Key key, this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                ? [EmptyPlayerCard(matchId: match.documentId)]
                : match
                    .getGoingUsersByTime()
                    .map((s) => PlayerCard(s))
                    .toList()),
      ),
    );
  }
}

class Title extends StatelessWidget {
  final String matchId;

  Title(this.matchId);

  @override
  Widget build(BuildContext context) {
    var loadOnceState = context.read<LoadOnceState>();

    var match = context.read<MatchesState>().getMatch(matchId);

    var skeleton = SkeletonLine(
      style: SkeletonLineStyle(
          borderRadius: BorderRadius.circular(20),
          width: double.infinity,
          height: 24),
    );

    if (match == null) {
      return skeleton;
    }
    var sportCenter = loadOnceState.getSportCenter(match.sportCenterId);
    var sport = match.sport;
    if (sport == null || sportCenter == null) {
      return skeleton;
    }

    var title = sportCenter.name + " - " + sport;

    return Text(title,
        style: TextPalette.h1Default, textAlign: TextAlign.start);
  }
}

// info card
class MatchInfo extends StatelessWidget {
  static var dateFormat = DateFormat('MMMM dd \'at\' HH:mm');

  final String matchId;

  MatchInfo(this.matchId);

  @override
  Widget build(BuildContext context) {
    var child;

    var match = context.watch<MatchesState>().getMatch(matchId);

    var sportCenter = (match == null)
        ? null
        : context.watch<LoadOnceState>().getSportCenter(match.sportCenterId);

    child = Column(
      children: [
        Row(children: [Expanded(child: SportCenterImageCarousel(match))]),
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(children: [
            InfoWidget(
                title: (match == null)
                    ? null
                    : getFormattedDateLong(match.dateTime),
                subTitle: (match == null)
                    ? null
                    : getStartAndEndHour(match.dateTime, match.duration)
                            .join(" - ") +
                        " - " +
                        match.duration.inMinutes.toString() +
                        " min",
                icon: Icons.schedule),
            SizedBox(height: 16),
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
                    title: (sportCenter == null)
                        ? null
                        : sportCenter.name +
                            (match.sportCenterSubLocation != null &&
                                    match.sportCenterSubLocation.isNotEmpty
                                ? " - " + match.sportCenterSubLocation
                                : ""),
                    icon: Icons.place,
                    subTitle: (sportCenter == null)
                        ? null
                        : sportCenter.getShortAddress(),
                    rightWidget: ClipRRect(
                        borderRadius: BorderRadius.circular(15.0),
                        child: Image.asset("assets/map.png", height: 45))),
              ),
            ),
            SizedBox(height: 16),
            InfoWidget(
                title: match?.sport,
                icon: Icons.sports_soccer,
                // todo fix info sport
                subTitle:
                    (sportCenter == null) ? null : sportCenter.tags.join(", ")),
            SizedBox(height: 16),
            InfoWidget(
                title: (match == null)
                    ? null
                    : formatCurrency(match.pricePerPersonInCents),
                icon: Icons.sell,
                subTitle: "Pay with Ideal"),
          ]),
        )
      ],
    );

    return InfoContainer(padding: EdgeInsets.zero, child: child);
  }
}

class SportCenterImageCarousel extends StatefulWidget {
  final Match match;

  SportCenterImageCarousel(this.match);

  @override
  State<StatefulWidget> createState() => SportCenterImageCarouselState();
}

class SportCenterImageCarouselState extends State<SportCenterImageCarousel> {
  int _current = 0;
  final CarouselController _controller = CarouselController();

  @override
  Widget build(BuildContext context) {
    var placeHolder = SkeletonAvatar(
      style: SkeletonAvatarStyle(
          width: double.infinity,
          height: 190,
          borderRadius: BorderRadius.circular(10.0)),
    );

    if (widget.match == null) {
      return placeHolder;
    }

    var sportCenter = context
        .read<LoadOnceState>()
        .getSportCenter(widget.match.sportCenterId);

    if (sportCenter == null) {
      return placeHolder;
    }

    List<Widget> itemsToShow = List<Widget>.from(
        sportCenter.getImagesUrls().map((i) => CachedNetworkImage(
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
            )));

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
                    margin:
                        EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (itemsToShow.length > 1)
                            ? Colors.white
                                .withOpacity(_current == entry.key ? 0.9 : 0.4)
                            : Colors.transparent),
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

  final Widget rightWidget;

  InfoWidget({this.title, this.icon, this.subTitle}) : rightWidget = null;

  InfoWidget.withRightWidget(
      {this.title, this.icon, this.subTitle, Widget rightWidget})
      : rightWidget = rightWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          child: Column(
            // mainAxisSize: MainAxisSize.max,
            children: [
              Icon(icon, size: 20, color: UiUtils.fromHex("#999999")),
            ],
          ),
        ),
        SizedBox(
          width: 20,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title == null
                ? Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Skeletons.xlText)
                : Text(title, style: TextPalette.h2),
            SizedBox(
              height: 4,
            ),
            subTitle == null
                ? Skeletons.lText
                : Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Text(subTitle, style: TextPalette.bodyText))
          ],
        ),
        if (rightWidget != null)
          Expanded(
              child:
                  Align(alignment: Alignment.centerRight, child: rightWidget))
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

    return Padding(
        padding: EdgeInsets.only(right: 10),
        child: SizedBox(
          width: 100,
          child: InfoContainer(
              child: Column(children: [
            UserAvatarWithBottomModal(userData: userData),
            SizedBox(height: 10),
            (userData == null)
                ? Skeletons.sText
                : Text((userData?.name ?? "Player").split(" ").first,
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
        trimLines: 3,
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

class MapCardImage extends StatelessWidget {
  final String matchId;

  MapCardImage(this.matchId);

  @override
  Widget build(BuildContext context) {
    var skeleton = SkeletonAvatar(
      style: SkeletonAvatarStyle(
          width: double.infinity,
          height: 190,
          borderRadius: BorderRadius.circular(10.0)),
    );

    var match = context.read<MatchesState>().getMatch(matchId);

    if (match == null)
      return skeleton;

    var sportCenter =
        context.read<LoadOnceState>().getSportCenter(match.sportCenterId);

    if (sportCenter == null)
      return skeleton;

    var lat = sportCenter.lat;
    var lng = sportCenter.lng;

    var url = "https://maps.googleapis.com/maps/api/staticmap?center=" +
        lat.toString() +
        "," +
        lng.toString() +
        "&key=AIzaSyDlU4z5DbXqoafB-T-t2mJ8rGv3Y4rAcWY&zoom=16&size=600x300&markers=color:red%7C" +
        lat.toString() +
        "," +
        lng.toString();

    return InkWell(
      onTap: () async {
        if (await MapLauncher.isMapAvailable(m.MapType.google)) {
          await MapLauncher.showMarker(
            mapType: m.MapType.google,
            coords: Coords(lat, lng),
            title: "",
            extraParams: {
              "q": sportCenter.name + "," + sportCenter.address,
              "z": "16"
            },
          );
        } else if (await MapLauncher.isMapAvailable(m.MapType.apple)) {
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
      child: ClipRRect(
          borderRadius: InfoContainer.borderRadius,
          child: CachedNetworkImage(imageUrl: url)),
    );
  }
}

class Stats extends StatelessWidget {
  final String matchId;
  final DateTime matchDatetime;
  final bool extended;
  final MatchStatusForUser matchStatusForUser;

  const Stats(
      {Key key, this.matchId, this.matchDatetime, this.matchStatusForUser,
        this.extended = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var child;
    var showingPartial =
        matchStatusForUser == null && extended;

    // in extended mode, we show also partial results
    if (matchStatusForUser == MatchStatusForUser.no_more_to_rate && !extended) {
      child = Container(
          width: double.infinity,
          child: Column(
            children: [
              CircleAvatar(
                  radius: 36,
                  backgroundColor: Palette.grey_lightest,
                  child: Image.asset(
                    "assets/empty_state/stats.png",
                    height: 24,
                  )),
              SizedBox(height: 16),
              Text(
                "Stats available soon",
                style: TextPalette.h2,
              ),
              SizedBox(height: 8),
              Text(
                "Statistics for this match will be available\n" +
                    getFormattedDate(matchDatetime.add(Duration(days: 1)))
                        .toLowerCase(),
                style: TextPalette.bodyText,
                textAlign: TextAlign.center,
              ),
            ],
          ));
    } else {
      var ratings = context.watch<MatchesState>().getRatings(matchId);
      var userState = context.watch<UserState>();

      var loadSkeleton = (ratings == null || userState == null);
      child = (loadSkeleton)
          ? StatsSkeleton()
          : Builder(
              builder: (context) {
                var match = context.watch<MatchesState>().getMatch(matchId);
                var finalRatings =
                    ratings.getFinalRatings(match.getGoingUsersByTime());

                var sortedTmp = finalRatings.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                var potms = match.getPotms();
                var sorted = List<MapEntry<String, double>>.from([]);

                // first add potms
                potms.forEach((p) {
                  sorted.add(MapEntry(p, finalRatings[p]));
                });
                // then the rest
                sortedTmp.forEach((p) {
                  if (!potms.contains(p.key))
                    sorted.add(MapEntry(p.key, p.value));
                });

                int index = 1;

                return Container(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (extended)
                      Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                    "V=votes   S=skips        Received    Given     Vote",
                                    textAlign: TextAlign.end,
                                    style: TextPalette.bodyText),
                              )
                            ],
                          )),
                    Column(
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
                          UserAvatar(16, userDetails),
                          // SizedBox(width: 8),
                          Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Row(
                              children: [
                                Builder(builder: (context) {
                                  // fixme text overflow
                                  if (userDetails == null)
                                    return Skeletons.mText;

                                  var name =
                                      UserDetails.getDisplayName(userDetails)
                                          .split(" ")
                                          .first;
                                  var n =
                                      name.substring(0, min(name.length, 11));
                                  return Text(n,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextPalette.getBodyText(
                                          Palette.black));
                                }),
                                SizedBox(width: 8),
                                if (userDetails != null &&
                                    potms.contains(userDetails.documentId) &&
                                    score > 0)
                                  Image.asset(
                                    "assets/potm_badge.png",
                                    width: 20,
                                  )
                              ],
                            ),
                          ),
                          Spacer(),
                          if (!extended)
                            Container(
                              height: 8,
                              width: 72,
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                child: LinearProgressIndicator(
                                  value: score / 5,
                                  color: Palette.primary,
                                  backgroundColor: Palette.grey_lighter,
                                ),
                              ),
                            ),
                          if (extended)
                            Row(
                              children: [
                                Text(
                                    "V: " +
                                        ratings
                                            .getNumberOfVotes(
                                                userDetails.documentId)
                                            .toString(),
                                    style:
                                        TextPalette.getBodyText(Colors.green)),
                                SizedBox(
                                  width: 6,
                                ),
                                Text(
                                    "S: " +
                                        ratings
                                            .getNumberOfSkips(
                                                userDetails.documentId)
                                            .toString(),
                                    style: TextPalette.getBodyText(
                                        Palette.grey_dark)),
                                SizedBox(
                                  width: 6,
                                ),
                                Text(
                                    "V: " +
                                        ratings
                                            .getNumberOfGivenVotes(
                                                userDetails.documentId)
                                            .toString(),
                                    style:
                                        TextPalette.getBodyText(Colors.green)),
                                SizedBox(
                                  width: 6,
                                ),
                                Text(
                                    "S: " +
                                        ratings
                                            .getNumberOfGivenSkips(
                                                userDetails.documentId)
                                            .toString(),
                                    style: TextPalette.getBodyText(
                                        Palette.grey_dark))
                              ],
                            ),
                          SizedBox(width: 16),
                          Container(
                            width: 22,
                            child: Text(
                                (score == 0) ? "  -" : score.toStringAsFixed(1),
                                style: TextPalette.getBodyText(Palette.black)),
                          ),
                        ];

                        index++;
                        return Padding(
                            padding: (index > 2)
                                ? EdgeInsets.only(top: 16)
                                : EdgeInsets.zero,
                            child: InkWell(
                                onTap: () =>
                                    ModalBottomSheet.showNutmegModalBottomSheet(
                                        context,
                                        JoinedPlayerBottomModal(userDetails)),
                                child: Row(children: widgets)));
                      }).toList(),
                    )
                  ],
                ));
              },
            );
    }

    return Container(
      child: Section(
        title: "MATCH STATS " + (showingPartial ? " (partial)" : ""),
        body: InfoContainer(child: child),
      ),
    );
  }
}
