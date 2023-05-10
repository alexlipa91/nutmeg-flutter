import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nutmeg/utils/LocationUtils.dart';
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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../state/MatchesState.dart';
import '../state/UserState.dart';
import '../utils/InfoModals.dart';
import '../widgets/Buttons.dart' as buttons;
import '../widgets/ButtonsWithLoader.dart';
import '../widgets/ModalBottomSheet.dart';
import '../widgets/PlayerBottomModal.dart';
import '../widgets/Skeletons.dart';

import '../widgets/TeamsWidget.dart';
import 'BottomBarMatch.dart';
import 'PaymentDetailsDescription.dart';

class MatchDetails extends StatefulWidget {
  final String matchId;
  final String? paymentOutcome;

  const MatchDetails(
      {Key? key,
      @PathParam('id') required this.matchId,
      @QueryParam('payment_outcome') this.paymentOutcome})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => MatchDetailsState();
}

class MatchDetailsState extends State<MatchDetails> {

  Future<void> showRatingModalIfNeverSeen(
      Match match, UserDetails? loggedUser) async {
    bool? shown = (await SharedPreferences.getInstance())
        .getBool("${match.documentId}-rate-action-shown") ?? false;
    if (!shown) {
      if (match.status == MatchStatus.to_rate && match.isUserGoing(loggedUser)) {
        var stillToVote = context
            .read<MatchesState>()
            .getStillToVote(widget.matchId, loggedUser!.documentId);

        if (stillToVote != null && stillToVote.isNotEmpty) {
          await RatePlayerBottomModal.rateAction(context, widget.matchId);
          setState(() {});
        }
      }
      (await SharedPreferences.getInstance())
          .setBool("${match.documentId}-rate-action-shown", true);
    }
  }

  Future<void> myInitState() async {
    print("MatchDetails init state");
    // check if payment outcome
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.paymentOutcome != null) {
        if (ModalBottomSheet.isOpen) Navigator.of(context).pop();
        if (widget.paymentOutcome! == "success") {
          await PaymentDetailsDescription.communicateSuccessToUser(
              context, widget.matchId);
        } else
          GenericInfoModal(
                  title: AppLocalizations.of(context)!.paymentFailedTitle,
                  description:
                      AppLocalizations.of(context)!.paymentFailedSubtitle)
              .show(context);
      }
    });

    Match match = await refreshMatch();
    refreshUsers(match);

    Ratings? ratings = context.read<MatchesState>().getRatings(widget.matchId);

    // show rating modal
    var loggedUser = context.read<UserState>().getLoggedUserDetails();
    await showRatingModalIfNeverSeen(match, loggedUser);

    if (loggedUser != null &&
        (ratings?.potms ?? []).contains(loggedUser.documentId) &&
        match.status == MatchStatus.rated) {
      UserController.showPotmIfNotSeen(
          context, widget.matchId, loggedUser.documentId);
    }
  }

  Future<Match> refreshMatch() async {
    List<Future<dynamic>> futures = [
      context.read<MatchesState>().fetchRatings(widget.matchId),
      context.read<MatchesState>().fetchMatch(widget.matchId),
      if (context.read<UserState>().isLoggedIn())
        context.read<MatchesState>().fetchStillToVote(
            widget.matchId, context.read<UserState>().currentUserId!),
    ];

    return (await Future.wait(futures))[1];
  }

  Future<void> refreshUsers(Match match) async {
    var users = Set();
    users.addAll(match.getGoingUsersByTime());
    if (match.organizerId != null) {
      users.add(match.organizerId);
    }
    users.forEach((u) => context.read<UserState>().getOrFetch(u));
  }

  Future<void> refreshState() async {
    Match match = await refreshMatch();
    var loggedUser = context.read<UserState>().getLoggedUserDetails();
    await showRatingModalIfNeverSeen(match, loggedUser);
    await refreshUsers(match);
  }

  @override
  Widget build(BuildContext context) {
    var userState = context.watch<UserState>();
    var matchesState = context.watch<MatchesState>();

    Match? match = matchesState.getMatch(widget.matchId);
    SportCenter? sportCenter = match?.sportCenter;

    var status = match?.status;

    var isTest = match != null && match.isTest;
    var organizerView = userState.isLoggedIn() &&
        match != null &&
        match.organizerId == userState.getLoggedUserDetails()!.documentId;

    var bottomBar =
        BottomBarMatch.getBottomBar(context, widget.matchId, status);

    var skeletons;
    if (match == null || sportCenter == null) {
      skeletons = [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxWidth: 700),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: SkeletonMatchDetails.imageSkeleton())
                      ]),
                      SkeletonMatchDetails.skeletonRepeatedElement(),
                      SkeletonMatchDetails.skeletonRepeatedElement(),
                      SkeletonMatchDetails.skeletonRepeatedElement(),
                      SkeletonMatchDetails.skeletonRepeatedElement(),
                      SkeletonMatchDetails.skeletonRepeatedElement(),
                    ]),
              ),
            )
          ],
        )
      ];
    }

    return LayoutBuilder(builder: (context, constraints) {
      var widgets;
      if (skeletons == null) {
        var completeOrganiserWidget = organizerView &&
                userState.getLoggedUserDetails()?.areChargesEnabled(isTest) !=
                    null &&
                !userState.getLoggedUserDetails()!.areChargesEnabled(isTest)
            ? CompleteOrganiserAccountWidget(isTest: isTest)
            : null;

        var testInfo = isTest
            ? InfoContainer(
                backgroundColor: Palette.accent,
                child: SelectableText(
                  "Test match: " + widget.matchId,
                  style: TextPalette.getBodyText(Palette.black),
                ))
            : null;

        var matchInfo = MatchInfo(match!, sportCenter!);

        var teamsWidget = match.going.length > 1 && match.hasTeams()
            ? TeamsWidget(matchId: widget.matchId)
            : null;

        var infoPlayersList = match.isMatchFinished()
            ? null
            : PlayerList(
                match: match,
                withJoinButton:
                    bottomBar is JoinMatchBottomBar && !match.isFull());

        var stats = ((status == MatchStatus.rated &&
                    matchesState.getRatings(match.documentId) != null) ||
                status == MatchStatus.to_rate)
            ? Stats(match: match, sportCenter: sportCenter)
            : null;

        var sportCenterDetails =
            SportCenterDetails(match: match, sportCenter: sportCenter);

        var rules = (bool large) {
          var rules = [];

          if (match.cancelBefore != null) {
            var cancellationDate =
            match.dateTime.subtract(match.cancelBefore!);

            if (cancellationDate.isAfter(DateTime.now())) {
              rules.add(AppLocalizations.of(context)!
                  .cancellationInfo(
                  MatchInfo.formatDay(
                      match.getLocalizedTime(sportCenter.timezoneId),
                      context),
                  match.minPlayers));
            }
          }

          if (match.price != null) {
            var refundString = (match.userFee == 0)
                ? AppLocalizations.of(context)!.fullRefund
                : AppLocalizations.of(context)!.refundWithoutFee;

            rules.add(AppLocalizations.of(context)!.refundInfo(refundString));
          }

          if (rules.length == 0) {
            return null;
          }

          return RuleCard(
              AppLocalizations.of(context)!.paymentPolicyHeader,
              rules.join("\n"),
              large);
        };

        var organiserBadge = match.organizerId != null
            ? Builder(builder: (context) {
                var ud = context
                    .watch<UserState>()
                    .getUserDetail(match.organizerId!);

                return InfoContainer(
                    child: Row(children: [
                  UserAvatarWithBottomModal(userData: ud),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.organizedBy,
                            style: TextPalette.bodyText),
                        SizedBox(height: 4),
                        (ud == null)
                            ? Skeletons.lText
                            : Text(ud.name!.split(" ").first,
                                style: TextPalette.h2),
                      ],
                    ),
                  ),
                ]));
              })
            : null;

        if (constraints.maxWidth < 800) {
          widgets = interleave([
            // title
            if (completeOrganiserWidget != null) completeOrganiserWidget,
            // info box
            if (testInfo != null) testInfo,
            matchInfo,
            // stats
            if (infoPlayersList != null) infoPlayersList,
            if (teamsWidget != null) teamsWidget,
            if (stats != null) stats,
            // horizontal players list or teams
            sportCenterDetails,
            if (rules(false) != null)
              rules(false)!,
            if (organiserBadge != null) organiserBadge
          ], SizedBox(height: 16));
        } else {
          widgets = [
            if (completeOrganiserWidget != null) completeOrganiserWidget,
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 700),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: interleave(
                            [
                              matchInfo,
                              if (infoPlayersList != null) infoPlayersList,
                              if (teamsWidget != null) teamsWidget,
                              if (stats != null) stats
                            ],
                            SizedBox(
                              height: 16,
                            ))),
                  ),
                ),
                SizedBox(width: 20),
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 700),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: interleave([
                        sportCenterDetails,
                        if (rules(true) != null)
                          rules(true)!,
                        if (organiserBadge != null) organiserBadge
                      ], SizedBox(height: 16)),
                    ),
                  ),
                )
              ],
            )
          ];
        }
      } else {
        widgets = skeletons;
      }

      return PageTemplate(
        initState: () => myInitState(),
        refreshState: () => refreshState(),
        widgets: widgets,
        appBar: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BackButton(color: Palette.black),
            if (!DeviceInfo().name.contains("ipad") && !kIsWeb)
              if (match != null)
                Align(
                    alignment: Alignment.centerRight,
                    child: buttons.ShareButton(() async {
                      await DynamicLinks.shareMatchFunction(context, match);
                    }, Palette.black, 25.0)),
          ],
        ),
        bottomNavigationBar: bottomBar,
      );
    });
  }
}

class PlayerList extends StatelessWidget {
  static getTitle(BuildContext context, Match? match) => (match == null)
      ? ""
      : AppLocalizations.of(context)!
          .listOfPlayersHeader(match.numPlayersGoing(), match.maxPlayers);

  final Match match;
  final bool withJoinButton;

  const PlayerList(
      {Key? key, required this.match, required this.withJoinButton})
      : super(key: key);

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
    return InfoContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(getTitle(context, match), style: TextPalette.h2)),
          SizedBox(height: 24),
          LayoutBuilder(builder: (context, constraints) {
            if (MediaQuery.of(context).size.width < 800)
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: widgets),
              );
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(
                    child: Wrap(spacing: 16, runSpacing: 16, children: cards))
              ]),
            );
          })
        ],
      ),
      padding: EdgeInsets.symmetric(vertical: 16),
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
      sportCenter.getName() + " - " + sportCenter.getCourtType(),
      style: TextPalette.h1Default,
    );
  }
}

class AddressRow extends StatelessWidget {
  final SportCenter sportCenter;

  const AddressRow({Key? key, required this.sportCenter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(sportCenter.address);
  }
}

// info card
class MatchInfo extends StatelessWidget {
  final Match match;
  final SportCenter sportCenter;

  MatchInfo(this.match, this.sportCenter);

  static String formatDay(DateTime d, BuildContext context) {
    var dayDateFormatPastYear = DateFormat(
        "EEEE, MMM dd yyyy", getLanguageLocaleWatch(context).languageCode);
    var dayDateFormat =
        DateFormat("EEEE, MMM dd", getLanguageLocaleWatch(context).languageCode);
    return DateTime.now().year == d.year
        ? dayDateFormat.format(d)
        : dayDateFormatPastYear.format(d);
  }

  @override
  Widget build(BuildContext context) {
    var hourDateFormat =
        DateFormat("HH:mm", getLanguageLocaleWatch(context).languageCode);

    var child;

    var matchWidget = getStatusWidget(context, match);
    var loggedUser = context.watch<UserState>().getLoggedUserDetails();
    var isOrganizerView = match.organizerId != null &&
        loggedUser != null &&
        match.organizerId == loggedUser.documentId;

    child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: SportCenterImageCarousel(match, sportCenter))
        ]),
        Padding(
          padding: EdgeInsets.all(16.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Title(match, sportCenter),
            SizedBox(height: 16),
            AddressRow(sportCenter: sportCenter),
            if (isOrganizerView)
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Row(children: [
                  Expanded(
                      child: GenericButtonWithLoader(
                          AppLocalizations.of(context)!.manageButton, (_) {
                    ModalBottomSheet.showNutmegModalBottomSheet(
                        context,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                                onTap: () async {
                                  context.go("/match/${match.documentId}/edit");
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                    AppLocalizations.of(context)!.editAction,
                                    style: TextPalette.listItem)),
                            Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: InkWell(
                                  onTap: () async {
                                    DynamicLinks.shareMatchFunction(
                                        context, match);
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                      AppLocalizations.of(context)!.shareAction,
                                      style: TextPalette.listItem)),
                            ),
                            if (match.dateTime.isAfter(DateTime.now()) &&
                                match.status != MatchStatus.cancelled)
                              Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: InkWell(
                                  onTap: () async {
                                    await GenericInfoModal(
                                        title: AppLocalizations.of(context)!
                                            .cancelMatchTitle,
                                        description:
                                            AppLocalizations.of(context)!
                                                .cancelMatchSubtitle,
                                        action: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child:
                                                  GenericButtonWithLoaderAndErrorHandling(
                                                      AppLocalizations.of(
                                                              context)!
                                                          .confirmButtonText,
                                                      (_) async {
                                                await MatchesController
                                                    .cancelMatch(
                                                        match.documentId);
                                                await context
                                                    .read<MatchesState>()
                                                    .fetchMatch(
                                                        match.documentId);
                                                Navigator.pop(context);
                                              }, Primary()),
                                            )
                                          ],
                                        )).show(context);

                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                      AppLocalizations.of(context)!
                                          .cancelMatchAction,
                                      style: TextPalette.getListItem(
                                          Palette.destructive)),
                                ),
                              ),
                          ],
                        ));
                  }, Primary()))
                ]),
              ),
            SizedBox(height: 16),
            IconList.fromIcon({
              Icons.calendar_month_outlined: formatDay(
                  match.getLocalizedTime(sportCenter.timezoneId), context),
              Icons.access_time_outlined:
                  "${hourDateFormat.format(match.getLocalizedTime(sportCenter.timezoneId))} - "
                          "${hourDateFormat.format(match.getLocalizedTime(sportCenter.timezoneId).add(match.duration))}" +
                      " (" +
                      gmtSuffix(sportCenter.timezoneId) +
                      ")",
              if (match.price != null)
                Icons.local_offer_outlined:
                    formatCurrency(match.price!.getTotalPrice()),
              if (match.isPrivate)
                Icons.lock_outline:
                    AppLocalizations.of(context)!.privateMatchDesc,
            }),
            if (isOrganizerView &&
                match.isMatchFinished() &&
                match.cancelledAt == null)
              Builder(builder: (context) {
                var date = match.payout != null
                    ? match.payout!.arrivalDate
                    : match.dateTime.add(Duration(days: 7));
                var amount = formatCurrency(match.payout?.amount ??
                    match.price!.basePrice * match.going.length);
                var success =
                    match.payout != null && match.payout!.status == "paid";
                var color = success ? Palette.green : Palette.darkWarning;

                return Column(
                  children: [
                    NutmegDivider(horizontal: true),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                            child: Icon(Icons.monetization_on_outlined,
                                color: color, size: 18)),
                        SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            child: Text(
                                success
                                    ? AppLocalizations.of(context)!
                                        .payoutInfoSuccessText(
                                            amount, formatDay(date, context))
                                    : AppLocalizations.of(context)!
                                        .payoutInfoOnItsWayText(
                                            amount, formatDay(date, context)),
                                maxLines: 2,
                                softWrap: true,
                                style: TextPalette.getListItem(color)),
                          ),
                        )
                      ],
                    ),
                  ],
                );
              }),
            if (matchWidget != null)
              Column(children: [
                SizedBox(height: 16),
                NutmegDivider(horizontal: true),
                SizedBox(height: 8),
                matchWidget
              ])
          ]),
        ),
      ],
    );

    return InfoContainer(padding: EdgeInsets.zero, child: child);
  }

  Row? getStatusWidget(BuildContext context, Match? match) {
    var color;
    var icon;
    var text;

    if (match == null) return null;

    if (match.status == MatchStatus.playing) {
      icon = Icons.history_toggle_off_outlined;
      color = Palette.greyDark;
      text = AppLocalizations.of(context)!.inProgressStatus;
    } else if (match.status == MatchStatus.cancelled) {
      icon = Icons.do_disturb_alt_outlined;
      color = Palette.destructive;
      text = AppLocalizations.of(context)!.cancelledStatus;
    } else if (match.status == MatchStatus.unpublished) {
      icon = Icons.warning_amber_outlined;
      color = Palette.darkWarning;
      text = AppLocalizations.of(context)!.notPublishedStatus;
    } else if (match.status == MatchStatus.open &&
        match.cancelBefore != null &&
        match.getMissingPlayers() > 0) {
      icon = Icons.hourglass_empty_outlined;
      color = Palette.primary;
      text = AppLocalizations.of(context)!
          .waitingForPlayersStatus(match.getMissingPlayers());
    } else if (match.status == MatchStatus.open &&
            (match.getMissingPlayers() == 0 || match.cancelBefore == null) ||
        (match.status == MatchStatus.pre_playing &&
            match.getMissingPlayers() == 0)) {
      icon = Icons.check_circle_outline;
      color = Palette.green;
      text = AppLocalizations.of(context)!.matchOnStatus;
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
  final SportCenter sportCenter;

  SportCenterImageCarousel(this.match, this.sportCenter);

  @override
  State<StatefulWidget> createState() => SportCenterImageCarouselState();
}

class SportCenterImageCarouselState extends State<SportCenterImageCarousel> {
  int _current = 0;
  final CarouselController _controller = CarouselController();

  @override
  Widget build(BuildContext context) {
    var itemsToShow = widget.sportCenter.getCarouselImages();

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
              }).toList()),
        ),
      ],
    );
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        DottedBorder(
          padding: EdgeInsets.zero,
          borderType: BorderType.Circle,
          color: Palette.greyDark,
          strokeWidth: 1,
          dashPattern: [4],
          child: CircleAvatar(
            radius: 29,
            child: Icon(Icons.add, color: Palette.greyDark, size: 24),
            backgroundColor: Colors.transparent,
          ),
        ),
        SizedBox(height: 10),
        Text(AppLocalizations.of(context)!.joinAction,
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
  final bool large;

  const RuleCard(this.title, this.body, this.large);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
      width: double.infinity,
      child: InfoContainerWithTitle(
          title: title,
          body: Column(children: [
            large
                ? Text(body, style: TextPalette.bodyText)
                : ReadMoreText(
                    body,
                    style: TextPalette.bodyText,
                    trimLines: 4,
                    colorClickableText: Colors.blue,
                    delimiter: "\n\n",
                    trimMode: TrimMode.Line,
                    trimCollapsedText: AppLocalizations.of(context)!.showMore,
                    trimExpandedText: AppLocalizations.of(context)!.showLess,
                    moreStyle: TextPalette.linkStyle,
                    lessStyle: TextPalette.linkStyle,
                  ),
            // Text("Rule" * 100, style: TextPalette.bodyText2Gray)
          ])),
    );
  }
}

class SportCenterDetails extends StatelessWidget {
  final SportCenter sportCenter;
  final Match match;

  const SportCenterDetails(
      {Key? key, required this.match, required this.sportCenter})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InfoContainerWithTitle(
      title: AppLocalizations.of(context)!.locationHeader,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MapCardImage(sportCenter),
          SizedBox(height: 16),
          AddressRow(sportCenter: sportCenter),
          SizedBox(height: 16),
          IconList.fromSvg({
            "assets/icons/nutmeg_icon_court.svg": AppLocalizations.of(context)!
                .courtType(sportCenter.getCourtType()),
            "assets/icons/nutmeg_icon_shoe.svg":
                sportCenter.getSurface(context),
            if (sportCenter.getHasChangingRooms() ?? false)
              "assets/icons/nutmeg_icon_changing_rooms.svg":
                  AppLocalizations.of(context)!.changingRooms,
            if ((match.sportCenterSubLocation ?? "").isNotEmpty)
              "assets/icons/nutmeg_icon_court_number.svg":
                  AppLocalizations.of(context)!
                      .courtNumber(match.sportCenterSubLocation!),
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
    return InkWell(
      onTap: () async {
        if (kIsWeb) {
          // todo get cid for dynamic sportcenter
          // launchUrl(Uri.parse("https://maps.google.com/?cid=${sportCenter.cid}"));
        } else if (await MapLauncher.isMapAvailable(m.MapType.google) ??
            false) {
          await MapLauncher.showMarker(
            mapType: m.MapType.google,
            coords: Coords(sportCenter.lat, sportCenter.lng),
            title: "",
            extraParams: {
              "q": sportCenter.getName() + "," + sportCenter.address,
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
          child: CachedNetworkImage(
              imageUrl: buildMapUrl(sportCenter.lat, sportCenter.lng))),
    );
  }
}

class Stats extends StatelessWidget {
  final Match match;
  final SportCenter sportCenter;

  Stats({Key? key, required this.match, required this.sportCenter})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var child;
    var dayDateFormat = DateFormat(
        "EEEE, MMM dd HH:mm", getLanguageLocaleWatch(context).languageCode);

    if (match.status == MatchStatus.to_rate) {
      child = Container(
          width: double.infinity,
          child: Column(
            children: [
              CircleAvatar(
                  radius: 36,
                  backgroundColor: Palette.greyLightest,
                  child: Image.asset(
                    "assets/empty_state/stats.png",
                    height: 24,
                  )),
              SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.statsWaiting,
                style: TextPalette.h2,
              ),
              SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.statsAvailableAt(
                    dayDateFormat.format(match
                            .getLocalizedTime(sportCenter.timezoneId)
                            .add(Duration(days: 1))) +
                        " ${gmtSuffix(sportCenter.timezoneId)}"),
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
                int index = 1;

                return Container(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(
                      builder: (context) {
                        Map<String, double?> userAndRate = {};
                        match.going.keys.forEach(
                            (u) => userAndRate[u] = (ratings?.scores ?? {})[u]);
                        var entries = userAndRate.entries.toList();
                        entries.sort((a, b) =>
                            (b.value ?? -1).compareTo((a.value ?? -1)));

                        return Column(
                          children: entries.map((e) {
                            var userDetails = userState.getUserDetail(e.key);
                            double? rate = e.value;
                            bool isPotm =
                                (ratings?.potms ?? []).contains(e.key);

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
                                        isPotm &&
                                        rate != null)
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
                                    value: (rate ?? 0) / 5,
                                    color: Palette.primary,
                                    backgroundColor: Palette.greyLighter,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Container(
                                width: 22,
                                child: Text(
                                    (rate == null)
                                        ? "  -"
                                        : rate.toStringAsFixed(1),
                                    style:
                                        TextPalette.getBodyText(Palette.black)),
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
                        );
                      },
                    )
                  ],
                ));
              },
            );
    }

    return InfoContainerWithTitle(
        title: AppLocalizations.of(context)!.matchStatsTitle, body: child);
  }
}

class UserNameWidget extends StatelessWidget {
  final UserDetails? userDetails;

  const UserNameWidget({Key? key, this.userDetails}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // fixme text overflow
    if (userDetails == null) return Skeletons.sText;

    var name = UserDetails.getDisplayName(userDetails).split(" ").first;

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
      : widgetAndText = svgAndText.map((i, t) =>
            MapEntry(SvgPicture.asset(i, width: size, height: size), t));

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
