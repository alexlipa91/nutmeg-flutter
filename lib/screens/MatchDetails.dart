import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:map_launcher/src/models.dart' as m;
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/model/SportCenter.dart';
import 'package:nutmeg/model/UserDetails.dart';
import 'package:nutmeg/screens/JoinModal.dart';
import 'package:nutmeg/screens/RatePlayersModal.dart';
import 'package:nutmeg/screens/UserPage.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/PageTemplate.dart';
import 'package:readmore/readmore.dart';
import 'package:skeletons/skeletons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/LoadOnceState.dart';
import '../state/MatchesState.dart';
import '../state/UserState.dart';
import '../utils/InfoModals.dart';
import '../widgets/Buttons.dart' as buttons;
import '../widgets/ModalBottomSheet.dart';
import '../widgets/PlayerBottomModal.dart';
import '../widgets/Skeletons.dart';
import 'BottomBarMatch.dart';
import 'PaymentDetailsDescription.dart';


class MatchDetails extends StatefulWidget {
  final String matchId;
  final String? paymentOutcome;

  const MatchDetails({Key? key,
    @PathParam('id') required this.matchId,
    @QueryParam('payment_outcome') this.paymentOutcome
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => MatchDetailsState();
}

class MatchDetailsState extends State<MatchDetails> {

  Future<void> myInitState() async {
    await refreshState();

    // check if payment outcome
    if (widget.paymentOutcome != null) {
      if (ModalBottomSheet.isOpen)
        Navigator.of(context).pop();
      if (widget.paymentOutcome! == "success") {
        PaymentDetailsDescription.communicateSuccessToUser(context,
            widget.matchId);
      } else
        GenericInfoModal(
            title: "Payment Failed!", description: "Please try again")
            .show(context);
    }

    // show rating modal
    var match = context.read<MatchesState>().getMatch(widget.matchId);
    var loggedUser = context.read<UserState>().getLoggedUserDetails();

    if (match?.status == MatchStatus.to_rate && match!.isUserGoing(loggedUser)) {
      var stillToVote = context.read<MatchesState>().stillToVote(
          widget.matchId, loggedUser!);

      if (stillToVote.isNotEmpty) {
        await RatePlayerBottomModal.rateAction(context, widget.matchId);
        setState(() {});
      }
    }

    if (loggedUser != null &&
        match != null &&
        match.getPotms().contains(loggedUser.documentId)) {
      UserController.showPotmIfNotSeen(context,
          widget.matchId, loggedUser.documentId);
    }
  }

  Future<void> refreshState() async {
    List<Future<dynamic>> futures = [
      context.read<MatchesState>().fetchRatings(widget.matchId),
      MatchesController.refresh(context, widget.matchId)
    ];

    var res = await Future.wait(futures);

    Match match = res[1];

    // get users details
    UserController.getBatchUserDetails(context, match.getGoingUsersByTime());

    // get organizer details
    UserController.getUserDetails(context, match.organizerId);
  }

  @override
  Widget build(BuildContext context) {
    var userState = context.watch<UserState>();
    var matchesState = context.watch<MatchesState>();

    Match? match = matchesState.getMatch(widget.matchId);
    SportCenter? sportCenter = (match == null)
        ? null : context.watch<LoadOnceState>().getSportCenter(match.sportCenterId);

    var status = match?.status;

    var isTest = match != null && match.isTest;
    var organizerView = userState.isLoggedIn() &&
        match != null &&
        match.organizerId == userState.getLoggedUserDetails()!.documentId;

    var bottomBar = BottomBarMatch.getBottomBar(context, widget.matchId, status);

    // add padding individually since because of shadow clipping some components need margin
    var widgets;
    if (match == null || sportCenter == null) {
      var skeletonRepeatedElement = Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SkeletonLine(
                style: SkeletonLineStyle(
                    borderRadius: BorderRadius.circular(20),
                    width: double.infinity,
                    height: 24)),
            Column(children: List<Widget>.filled(3,
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Row(children: [
                    SkeletonLine(
                      style: SkeletonLineStyle(
                          borderRadius: BorderRadius.circular(20),
                          width: 24,
                          height: 24),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: SkeletonLine(
                        style: SkeletonLineStyle(
                            borderRadius: BorderRadius.circular(20),
                            height: 24),
                      ),
                    ),
                  ],),
                )))
          ])
      );

      widgets = [
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Expanded(child: SportCenterImageCarouselState.getPlaceholder())]),
              skeletonRepeatedElement,
              skeletonRepeatedElement,
              skeletonRepeatedElement
            ])
      ];
    } else {
      widgets = [
        // title
        if (organizerView &&
            userState.getLoggedUserDetails()?.areChargesEnabled(isTest) != null &&
            !userState.getLoggedUserDetails()!.areChargesEnabled(isTest))
          CompleteOrganiserAccountWidget(isTest: isTest),
        if (isTest)
          InfoContainer(
              backgroundColor: Palette.accent,
              child: SelectableText(
                "Test match: " + widget.matchId,
                style: TextPalette.getBodyText(Palette.black),
              )),
        // info box
        MatchInfo(match, sportCenter),
        // stats
        if (status == MatchStatus.rated || status == MatchStatus.to_rate)
          Stats(match: match),
        // horizontal players list or teams
          match.hasTeams()
              ? TeamsWidget(matchId: widget.matchId)
              : PlayerList(match: match,
              withJoinButton: bottomBar is JoinMatchBottomBar && !match.isFull()),
        SportCenterDetails(match: match, sportCenter: sportCenter),
        RuleCard(
            "Payment Policy",
              "If you leave the match you will get a refund (excluding Nutmeg service fee).\n"
                  "If the match is cancelled you will get a full refund.\n\n"
                  "If you don’t show up you won’t get a refund." +
                  (match.cancelBefore != null
                      ? "\n\nThe match will be automatically canceled "
                      "${getFormattedDateLongWithHour(match.dateTime
                      .subtract(match.cancelBefore!))} "
                      "if less than ${match.minPlayers} players have joined."
                      : "")),
        if (match.organizerId != null)
          Builder(builder: (context) {
            var ud = context.watch<UserState>().getUserDetail(match.organizerId!);

            return InfoContainer(
                child: Row(children: [
                  (ud != null && ud.isAdmin!)
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
                            : Text((ud.isAdmin!) ? "Nutmeg" : ud.name!.split(" ").first,
                            style: TextPalette.h2),
                      ],
                    ),
                  ),
                ]));
          }),
      ];
    }

    return PageTemplate(
        initState: () => myInitState(),
        refreshState: () => refreshState(),
        widgets: interleave(widgets, SizedBox(height: 16)),
        appBar: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BackButton(color: Palette.black),
            if (!DeviceInfo().name.contains("ipad") && !kIsWeb)
              Align(
                  alignment: Alignment.centerRight,
                  child: buttons.ShareButton(() async {
                    await DynamicLinks.shareMatchFunction(widget.matchId);
                  }, Palette.black, 25.0)),
          ],
        ),
        bottomNavigationBar: bottomBar,
      );
  }
}

class PlayerList extends StatelessWidget {
  static getTitle(Match? match) => (match == null)
      ? ""
      : "Players (${match.numPlayersGoing().toString()}/${match.maxPlayers.toString()})";

  final Match match;
  final bool withJoinButton;

  const PlayerList({Key? key, required this.match, required this.withJoinButton}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];

    var space = (min(475, MediaQuery.of(context).size.width) - 300) / 4.5;

    List<Widget> cards = [];
    if (withJoinButton) {
      cards.add(EmptyPlayerCard(matchId: match.documentId));
    }
    match.getGoingUsersByTime().forEach((s) => cards.add(PlayerCard(s)));

    widgets.add(SizedBox(width: 16));
    widgets.addAll(interleave(cards, SizedBox(width: space)));
    widgets.add(SizedBox(width: 16));

    // we need to copy this instead of using InfoContainerWithTitle so we can play with the padding and the scrolling
    return InfoContainer(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(getTitle(match), style: TextPalette.h2)),
        SizedBox(height: 24),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: widgets),
        ),
      ],),
      padding: EdgeInsets.symmetric(vertical: 16),
    );
  }
}

class TeamsWidget extends StatelessWidget {
  final String matchId;

  const TeamsWidget({Key? key, required this.matchId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var match = context.watch<MatchesState>().getMatch(matchId);

    var teamA = match!.teams.entries.first;
    var teamB = match.teams.entries.last;

    return InfoContainerWithTitle(
        title: PlayerList.getTitle(match),
        body: IntrinsicHeight(
          child: Row(children: [
            getTeamColumn(context, teamA.key, teamA.value),
            VerticalDivider(
              thickness: 1,
              color: Palette.grey_light,
            ),
            getTeamColumn(context, teamB.key, teamB.value),
          ]),
        ));
  }

  getTeamColumn(BuildContext context, String teamName, List<String> players) {
    var playersWidgets = interleave(
        players.map((e) {
          var ud = context.watch<UserState>().getUserDetail(e);

          return InkWell(
              onTap: ud == null
                  ? null
                  : () => ModalBottomSheet.showNutmegModalBottomSheet(
                      context, JoinedPlayerBottomModal(ud)),
              child: SizedBox(
                height: 32,
                child: Row(children: [
                  UserAvatar(16, ud),
                  SizedBox(width: 16),
                  UserNameWidget(userDetails: ud)
                ]),
              ));
        }).toList(),
        SizedBox(height: 16));

    List<Widget> childrenWidgets = [];
    childrenWidgets.addAll([
      Text("Team ${teamName.toUpperCase()}",
          style: TextPalette.getListItem(Palette.black)),
      SizedBox(height: 24),
    ]);
    childrenWidgets.addAll(playersWidgets);

    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: childrenWidgets,
        ),
      ),
    );
  }
}

class Title extends StatelessWidget {
  final Match match;
  final SportCenter sportCenter;

  Title(this.match, this.sportCenter);

  @override
  Widget build(BuildContext context) {
    return Text(
      sportCenter.name + " - " + sportCenter.getCourtType()!,
      style: TextPalette.h1Default,
    );
  }
}

class AddressRow extends StatelessWidget {

  final SportCenter sportCenter;

  const AddressRow({Key? key, required this.sportCenter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      var addressItems = sportCenter.address.split(",");

      var firstRowText = addressItems[0].trim();
      if (addressItems.length > 1)
        firstRowText = firstRowText + ", " + addressItems[1].trim();

      String? secondRowText = (addressItems.length > 2)
          ? addressItems[2].trim() : null;

      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(firstRowText, style: TextPalette.bodyText),
            if (secondRowText != null)
              Text(secondRowText, style: TextPalette.bodyText)
          ]);
    });
  }
}


// info card
class MatchInfo extends StatelessWidget {
  static var dateFormat = DateFormat('MMMM dd \'at\' HH:mm');

  final Match match;
  final SportCenter sportCenter;

  MatchInfo(this.match, this.sportCenter);

  @override
  Widget build(BuildContext context) {
    var child;

    var matchWidget = getStatusWidget(match);

    child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Expanded(child: SportCenterImageCarousel(match))]),
        Padding(
          padding: EdgeInsets.all(16.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Title(match, sportCenter),
            SizedBox(height: 16),
            AddressRow(sportCenter: sportCenter),
            SizedBox(height: 16),
            IconList.fromIcon({
              Icons.calendar_month_outlined: getFormattedDateLong(match.dateTime),
              Icons.access_time_outlined: getStartAndEndHour(match.dateTime, match.duration).join(" - "),
              Icons.local_offer_outlined: formatCurrency(match.pricePerPersonInCents)
            }),
            if (matchWidget != null)
              Column(children: [
                SizedBox(height: 16),
                Divider(color: Palette.grey_light),
                SizedBox(height: 8),
                matchWidget
              ])
          ]),
        ),
      ],
    );

    return InfoContainer(padding: EdgeInsets.zero, child: child);
  }

  Row? getStatusWidget(Match? match) {
    var color;
    var icon;
    var text;

    if (match == null)
      return null;

    if (match.status == MatchStatus.playing) {
      icon = Icons.history_toggle_off_outlined;
      color = Palette.grey_dark;
      text = "In Progress";
    } else if (match.status == MatchStatus.cancelled) {
      icon = Icons.do_disturb_alt_outlined;
      color = Palette.destructive;
      text = "Canceled";
    } else if (match.status == MatchStatus.unpublished) {
      icon = Icons.warning_amber_outlined;
      color = Palette.darkWarning;
      text = "Not published";
    } else if (match.status == MatchStatus.open &&
        match.cancelBefore != null &&
        match.getMissingPlayers() > 0) {
      icon = Icons.hourglass_empty_outlined;
      color = Palette.primary;
      text = "Waiting for ${match.getMissingPlayers()} more players";
    } else if (match.status == MatchStatus.open &&
            (match.getMissingPlayers() == 0 || match.cancelBefore == null) ||
        (match.status == MatchStatus.pre_playing &&
            match.getMissingPlayers() == 0)) {
      icon = Icons.check_circle_outline;
      color = Palette.green;
      text = "Match is on";
    } else {
      return null;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        SizedBox(width: 8),
        Text(text, style: TextPalette.getListItem(color))
      ],
    );
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

  static Widget getPlaceholder() => SkeletonAvatar(
    style: SkeletonAvatarStyle(
        width: double.infinity,
        borderRadius: BorderRadius.circular(10.0)),
  );

  @override
  Widget build(BuildContext context) {
    var placeHolder = getPlaceholder();

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
                    width: 10.0,
                    height: 10.0,
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
              }
            ).toList()),
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

  final Widget? rightWidget;

  InfoWidget({required this.title, required this.icon, required this.subTitle}) : rightWidget = null;

  InfoWidget.withRightWidget(
      {required this.title, required this.icon, required this.subTitle, required Widget rightWidget})
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
  static var width = 80.0;

  final String userId;

  PlayerCard(this.userId);

  @override
  Widget build(BuildContext context) {
    var userData = context.watch<UserState>().getUserDetail(userId);

    return Column(children: [
      UserAvatarWithBottomModal(userData: userData, radius: 30),
      SizedBox(height: 10),
      (userData == null)
          ? Skeletons.sText
          : Text((userData.name ?? "Player").split(" ").first,
              overflow: TextOverflow.ellipsis,
              style: TextPalette.getBodyText(Palette.black))
    ]);
  }
}

class EmptyPlayerCard extends StatelessWidget {
  final String matchId;

  const EmptyPlayerCard({Key? key, required this.matchId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: context.watch<MatchesState>().getMatch(matchId)!.status ==
          MatchStatus.unpublished
          ? null
          : () => JoinModal.onJoinGameAction(context, matchId),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            DottedBorder(
              padding: EdgeInsets.zero,
              borderType: BorderType.Circle,
              color: Palette.grey_dark,
              strokeWidth: 1,
              dashPattern: [4],
              child: CircleAvatar(
                  radius: 29,
                  child: Icon(Icons.add, color: Palette.grey_dark, size: 24),
                  backgroundColor: Colors.transparent,
              ),
            ),
        SizedBox(height: 10),
        Text("Join",
            overflow: TextOverflow.ellipsis,
            style: TextPalette.getBodyText(Palette.primary))
      ]),
    );
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
    return InfoContainerWithTitle(
        title: title,
        body: Column(children: [
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

class SportCenterDetails extends StatelessWidget {
  final SportCenter sportCenter;
  final Match match;

  const SportCenterDetails({Key? key, required this.match,
    required this.sportCenter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InfoContainerWithTitle(
      title: "Location",
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MapCardImage(sportCenter),
          SizedBox(height: 16),
          AddressRow(sportCenter: sportCenter),
          SizedBox(height: 16),
          IconList.fromSvg({
            "assets/icons/nutmeg_icon_court.svg":
                (sportCenter.getCourtType() == null)
                    ? null
                    : sportCenter.getCourtType()! + " court type",
            if (sportCenter.getSurface() != null)
              "assets/icons/nutmeg_icon_shoe.svg": sportCenter.getSurface(),
            if (sportCenter.hasChangingRooms())
              "assets/icons/nutmeg_icon_changing_rooms.svg": "Change rooms available",
            if ((match.sportCenterSubLocation ?? "").isNotEmpty)
              "assets/icons/nutmeg_icon_court_number.svg": "Court number ${match.sportCenterSubLocation}"
          })
        ],
      ),
    );
  }
}

class MapCardImage extends StatelessWidget {
  final SportCenter sportCenter;

  MapCardImage(this.sportCenter);

  @override
  Widget build(BuildContext context) {
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
        if (kIsWeb) {
          launchUrl(Uri.parse("https://maps.google.com/?cid=${sportCenter.cid}"));
        } else if (await MapLauncher.isMapAvailable(m.MapType.google) ?? false) {
          await MapLauncher.showMarker(
            mapType: m.MapType.google,
            coords: Coords(lat, lng),
            title: "",
            extraParams: {
              "q": sportCenter.name + "," + sportCenter.address,
              "z": "16"
            },
          );
        } else if (await MapLauncher.isMapAvailable(m.MapType.apple) ?? false) {
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
  final Match match;

  Stats({Key? key, required this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var child;

    if (match.status == MatchStatus.to_rate) {
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
                    getFormattedDate(match.dateTime.add(Duration(days: 1)))
                        .toLowerCase(),
                style: TextPalette.bodyText,
                textAlign: TextAlign.center,
              ),
            ],
          ));
    } else {
      var ratings = context.watch<MatchesState>().getRatings(match.documentId);
      var userState = context.watch<UserState>();

      var loadSkeleton = ratings == null;
      child = (loadSkeleton)
          ? StatsSkeleton()
          : Builder(
              builder: (context) {
                var finalRatings = ratings!.getFinalRatings(
                    match.getGoingUsersByTime(), match.getPotms());

                int index = 1;

                return Container(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: finalRatings.map((r) {
                        var userDetails = userState.getUserDetail(r.user);

                        var widgets = [
                          Container(
                              width: 18,
                              child: Text(index.toString(),
                                  style: TextPalette.bodyText)),
                          SizedBox(width: 8),
                          UserAvatar(16, userDetails),
                          Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Row(
                              children: [
                                UserNameWidget(userDetails: userDetails),
                                SizedBox(width: 8),
                                if (userDetails != null &&
                                    r.isPotm &&
                                    r.vote > 0)
                                  Image.asset(
                                    "assets/potm_badge.png",
                                    width: 20,
                                  )
                              ],
                            ),
                          ),
                          Spacer(),
                          Container(
                            height: 8,
                            width: 72,
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              child: LinearProgressIndicator(
                                value: r.vote / 5,
                                color: Palette.primary,
                                backgroundColor: Palette.grey_lighter,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Container(
                            width: 22,
                            child: Text(
                                (r.vote == 0)
                                    ? "  -"
                                    : r.vote.toStringAsFixed(1),
                                style: TextPalette.getBodyText(Palette.black)),
                          ),
                        ];

                        index++;
                        return Padding(
                            padding: (index > 2)
                                ? EdgeInsets.only(top: 16)
                                : EdgeInsets.zero,
                            child: InkWell(
                                onTap: userDetails == null
                                    ? null
                                    : () => ModalBottomSheet
                                        .showNutmegModalBottomSheet(
                                            context,
                                            JoinedPlayerBottomModal(
                                                userDetails)),
                                child: Row(children: widgets)));
                      }).toList(),
                    )
                  ],
                ));
              },
            );
    }

    return InfoContainerWithTitle(title: "Match Stats", body: child);
  }
}

class UserNameWidget extends StatelessWidget {
  final UserDetails? userDetails;

  const UserNameWidget({Key? key, this.userDetails}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // fixme text overflow
    if (userDetails == null) return Skeletons.mText;

    var name = UserDetails.getDisplayName(userDetails)!.split(" ").first;

    var n = name.substring(0, min(name.length, 11));

    return Text(n,
        overflow: TextOverflow.ellipsis,
        style: TextPalette.getBodyText(Palette.black));
  }
}

class IconList extends StatelessWidget {
  static var size = 18.0;
  final Map<Widget, String?> widgetAndText;

  IconList.fromIcon(Map<IconData, String?> iconAndText)
      : widgetAndText = iconAndText.map(
            (i, t) => MapEntry(Icon(i, color: Palette.black, size: size), t));

  IconList.fromSvg(Map<String, String?> svgAndText)
      : widgetAndText = svgAndText.map(
            (i, t) => MapEntry(SvgPicture.asset(i, width: size, height: size), t));

  @override
  Widget build(BuildContext context) {
    Iterable<Row> rows = widgetAndText.entries.map((e) => Row(children: [
          e.key,
          SizedBox(width: 16),
          e.value == null
              ? Skeletons.lText
              : Text(e.value!, style: TextPalette.listItem)
        ]));

    List<Widget> widgets = interleave(rows.toList(), SizedBox(height: 12));

    return Column(children: widgets);
  }
}
