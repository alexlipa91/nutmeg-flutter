import 'dart:math';
import 'dart:ui' as ui;
import 'dart:html' as html;
import 'dart:convert';
import 'package:js/js_util.dart' as js_util;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nutmeg/state/MatchState.dart';
import 'package:nutmeg/state/UsersState.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';
import 'package:nutmeg/utils/LocationUtils.dart';
import 'package:nutmeg/widgets/UserAwardsReceived.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
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
import 'package:url_launcher/url_launcher.dart';

import '../state/MatchesState.dart';
import '../state/UserState.dart';
import '../state/UserRatings.dart';
import '../utils/InfoModals.dart';
import '../widgets/Buttons.dart' as buttons;
import '../widgets/ButtonsWithLoader.dart';
import '../widgets/ModalBottomSheet.dart';
import '../widgets/PlayerBottomModal.dart';
import '../widgets/Skeletons.dart';

import '../utils/web_url.dart';
import '../widgets/TeamsWidget.dart';
import 'BottomBarMatch.dart';
import 'PaymentDetailsDescription.dart';
import 'package:nutmeg/screens/Launch.dart';

final logger = CrashlyticsLogger('MatchDetails');

// MatchDetails is a stateless widget that provides a UserRatings provider to the MatchDetailsImpl widget
class MatchDetails extends StatelessWidget {
  final String matchId;
  final String? paymentOutcome;
  final Key? key;

  const MatchDetails({this.key, required this.matchId, this.paymentOutcome});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => UserRatings(matchId),
        child: MatchDetailsImpl(
            matchId: matchId, paymentOutcome: paymentOutcome, key: key));
  }
}

class MatchDetailsImpl extends StatefulWidget {
  final String matchId;
  final String? paymentOutcome;
  final Key? key;

  const MatchDetailsImpl({
    this.key,
    required this.matchId,
    this.paymentOutcome,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => MatchDetailsImplState();
}

class MatchDetailsImplState extends State<MatchDetailsImpl> {
  Future<void> showRatingModalIfNeverSeen(
      Match match, UserDetails? loggedUser) async {
    var sharedPrefs = await SharedPreferences.getInstance();
    var rateActionShownKey = "${match.documentId}-rate-action-shown";
    bool? rateActionShown = sharedPrefs.getBool(rateActionShownKey) ?? false;

    if (match.status == MatchStatus.to_rate && match.isUserGoing(loggedUser)) {
      if (!rateActionShown) {
        await rateAction(context, widget.matchId);
        sharedPrefs.setBool(rateActionShownKey, true);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    myInitState();
  }

  Future<void> myInitState() async {
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

    var state = context.read<MatchState>();

    await refreshState();
    // we need to wait to load all logged user info before building the UI

    var match = state.match!;
    match.going.forEach((key, value) {
      context.read<UsersState>().fetchUserDetails(key);
    });

    Ratings? ratings = state.ratings;

    // show rating modal
    var loggedUser = context.read<UserState>().getLoggedUserDetails();
    showRatingModalIfNeverSeen(context.read<MatchState>().match!, loggedUser);

    if (loggedUser != null &&
        (ratings?.potms ?? []).contains(loggedUser.documentId) &&
        context.read<MatchState>().match!.status == MatchStatus.rated) {
      UserController.showPotmIfNotSeen(
          context, widget.matchId, loggedUser.documentId);
    }
  }

  Future<void> refreshState() async {
    logger.info("refreshing state for MatchDetails widget");
    var state = context.read<MatchState>();
    var usersState = context.read<UsersState>();
    List<Future<dynamic>> futures = [
      state.fetchRatings(),
      state.fetchMatch(),
    ];

    await Future.wait(futures);
    if (state.match?.organizerId != null) {
      usersState.fetchUserDetails(state.match!.organizerId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      var matchState = context.watch<MatchState>();

      Match? match = matchState.match;
      SportCenter? sportCenter = match?.sportCenter;

      var isTest = match != null && match.isTest;
      var organizerView = matchState.isLoggedUserOrganizer();

      var bottomBar = BottomBarMatch.getBottomBar(
          matchState, widget.matchId, match?.status);

      return PageTemplate(
        widgets: getWidgets(context, matchState, sportCenter,
            matchState.ratings, organizerView, isTest, constraints),
        appBar: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BackButton(color: Palette.black),
            if (match != null)
              Align(
                alignment: Alignment.centerRight,
                child: buttons.ShareButton(() async {
                  if (kIsWeb) {
                    final baseUrl = getWebBaseUrl();
                    final url = '$baseUrl/match/${match.documentId}';
                    await Clipboard.setData(ClipboardData(text: url));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.linkCopiedToClipboard,
                            style: TextStyle(color: Palette.greyDark),
                          ),
                          backgroundColor: Palette.white.withOpacity(0.92),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } else {
                    await DynamicLinks.shareMatchFunction(context, match);
                  }
                }, Palette.black, 25.0),
              ),
          ],
        ),
        bottomNavigationBar: bottomBar,
      );
    });
  }
}

List<Widget> getWidgets(
    BuildContext context,
    MatchState matchState,
    SportCenter? sportCenter,
    Ratings? ratings,
    bool organizerView,
    bool isTest,
    BoxConstraints constraints) {
  var match = matchState.match;

  if (matchState.match == null || sportCenter == null) {
    return [
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

  var completeOrganiserWidget = organizerView && match?.price != null
      ? CompleteOrganiserAccountWidget(isTest: isTest)
      : null;

  var testInfo = isTest
      ? InfoContainer(
          backgroundColor: Palette.accent,
          child: SelectableText(
            "Test match: " + match!.documentId,
            style: TextPalette.getBodyText(Palette.black),
          ))
      : null;

  var matchInfo = MatchInfo(match!, sportCenter);

  var teamsWidget = match.going.length > 1 && match.hasTeams()
      ? TeamsWidget(matchId: match.documentId)
      : null;

  var infoPlayersList = match.isMatchFinished()
      ? null
      : PlayerList(match: match, withJoinButton: false);

  var status = match.status;
  var stats = ((status == MatchStatus.rated && ratings != null) ||
          status == MatchStatus.to_rate)
      ? Stats()
      : null;

  var awards = null;

  if (ratings != null && ratings.awards.isNotEmpty) {
    // Compute the number of distinct voters for awards
    awards = UserAwardsReceivedList(
      awards: ratings.awards,
      distinctVoters: ratings.numDistinctAwardVoters,
    );
  }

  var sportCenterDetails =
      SportCenterDetails(match: match, sportCenter: sportCenter);

  var rules = (bool large) {
    var rules = [];

    if (match.cancelBefore != null) {
      var cancellationDate = match.dateTime.subtract(match.cancelBefore!);

      if (cancellationDate.isAfter(DateTime.now())) {
        rules.add(AppLocalizations.of(context)!.cancellationInfo(
            MatchInfo.formatDay(match.getLocalizedTimeCancellation(), context),
            MatchInfo.formatHour(match.getLocalizedTimeCancellation(), context),
            match.minPlayers));
      }
    }

    if (match.price != null) {
      var refundString = (match.price!.userFee == 0)
          ? AppLocalizations.of(context)!.fullRefund
          : AppLocalizations.of(context)!.refundWithoutFee;

      rules.add(AppLocalizations.of(context)!.refundInfo(refundString));
    }

    if (rules.length == 0) {
      return null;
    }

    return RuleCard(AppLocalizations.of(context)!.paymentPolicyHeader,
        rules.join("\n"), large);
  };

  var organiserBadge = match.organizerId != null
      ? Builder(builder: (context) {
          var ud =
              context.watch<UsersState>().getUserDetail(match.organizerId!);

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
                      : Text(ud.name!.split(" ").first, style: TextPalette.h2),
                ],
              ),
            ),
          ]));
        })
      : null;

  var widgets = List<Widget>.empty();

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
      if (awards != null) awards,
      // horizontal players list or teams
      sportCenterDetails,
      if (rules(false) != null) rules(false)!,
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
                        if (stats != null) stats,
                        if (awards != null) awards,
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
                  if (rules(true) != null) rules(true)!,
                  if (organiserBadge != null) organiserBadge
                ], SizedBox(height: 16)),
              ),
            ),
          )
        ],
      )
    ];
  }

  return widgets;
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
    var canRemovePlayers = context.watch<MatchState>().isLoggedUserOrganizer() &&
        match.status != MatchStatus.cancelled &&
        !match.isMatchFinished();

    List<Widget> cards = [];
    if (withJoinButton) {
      cards.add(EmptyPlayerCard(matchId: match.documentId));
    }
    match.getGoingUsersByTime().forEach((s) => cards.add(PlayerCard(
          s,
          matchId: match.documentId,
          showRemove: canRemovePlayers && match.organizerId != s,
        )));

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

  static String formatDayHour(DateTime d, BuildContext context) {
    var dayDateFormatPastYear = DateFormat(
        "MMM dd HH:mm", getLanguageLocaleWatch(context).languageCode);
    return dayDateFormatPastYear.format(d);
  }

  static String formatDay(DateTime d, BuildContext context) {
    var dayDateFormatPastYear = DateFormat(
        "EEEE, MMM dd yyyy", getLanguageLocaleWatch(context).languageCode);
    var dayDateFormat = DateFormat(
        "EEEE, MMM dd", getLanguageLocaleWatch(context).languageCode);
    return DateTime.now().year == d.year
        ? dayDateFormat.format(d)
        : dayDateFormatPastYear.format(d);
  }

  static String formatHour(DateTime d, BuildContext context) {
    var hourDateFormat =
        DateFormat("HH:mm", getLanguageLocaleWatch(context).languageCode);
    return hourDateFormat.format(d);
  }

  @override
  Widget build(BuildContext context) {
    var child;

    var matchWidget = getStatusWidget(context, match);
    var loggedUser = context.watch<UserState>().getLoggedUserDetails();
    // Use MatchState's organizer check (which includes test mode override)
    var matchState = context.watch<MatchState>();
    var isOrganizerView = matchState.isLoggedUserOrganizer();

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
                                                    .getMatch(match.documentId)
                                                    .fetchMatch();
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
              Icons.calendar_month_outlined:
                  formatDay(match.getLocalizedTime(), context),
              Icons.access_time_outlined:
                  "${MatchInfo.formatDayHour(match.getLocalizedTime(), context)} - "
                          "${MatchInfo.formatDayHour(match.getLocalizedTime().add(match.duration), context)}" +
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
                match.price != null &&
                match.isMatchFinished() &&
                match.cancelledAt == null &&
                match.going.length > 0)
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
  final CarouselSliderController _controller = CarouselSliderController();

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
  final String? matchId;
  final bool showRemove;

  PlayerCard(this.userId, {this.matchId, this.showRemove = false});

  @override
  Widget build(BuildContext context) {
    var userData = context.watch<UsersState>().getUserDetail(userId);

    return Column(children: [
      Padding(
        padding: EdgeInsets.only(top: showRemove ? 6 : 0, right: showRemove ? 6 : 0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            UserAvatarWithBottomModal(userData: userData, radius: 30),
            if (showRemove)
              Positioned(
                right: -6,
                top: -6,
                child: InkWell(
                onTap: () async {
                  if (matchId == null) return;

                  var name =
                      (userData?.name ?? "Player").split(" ").first.trim();
                  if (name.isEmpty) name = "Player";

                  var match = context.read<MatchState>().match;
                  var refundInfo = (match?.price != null)
                      ? ("\n\n" +
                          AppLocalizations.of(context)!.removePlayerRefundInfo)
                      : "";

                  await GenericInfoModal(
                    title: AppLocalizations.of(context)!.removePlayerTitle,
                    description: AppLocalizations.of(context)!
                            .removePlayerSubtitle(name) +
                        refundInfo,
                    action: Row(
                      children: [
                        Expanded(
                          child: GenericButtonWithLoaderAndErrorHandling(
                            AppLocalizations.of(context)!.confirmButtonText,
                            (_) async {
                              await context
                                  .read<MatchState>()
                                  .removeUserFromMatch(userId);
                              Navigator.of(context).pop(true);
                            },
                            Destructive(),
                          ),
                        )
                      ],
                    ),
                  ).show(context);
                },
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Palette.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 6,
                        color: Colors.black.withOpacity(0.15),
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: Icon(
                    Icons.remove_circle,
                    color: Palette.destructive,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
    var userState = context.read<UserState>();
    var matchState = context.read<MatchState>();
    var matchesState = context.read<MatchesState>();

    return InkWell(
      onTap:
          context.watch<MatchState>().match?.status == MatchStatus.unpublished
              ? null
              : () => JoinModal.onJoinGameAction(
                  context, userState, matchState, matchesState),
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
          launchUrl(Uri.parse(
              "https://www.google.com/maps/search/?api=1&query=Google&query_place_id=${sportCenter.placeId}"));
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
  static Widget userRow(BuildContext context, MapEntry<String, double?> e,
      int index, UsersState userState, Ratings ratings) {
    var userDetails = userState.getUserDetail(e.key);
    double? rate = e.value;
    bool isPotm = (ratings.potms ?? []).contains(e.key);

    var widgets = [
      Container(
          width: 18,
          child: Text(index.toString(), style: TextPalette.bodyText)),
      SizedBox(width: 8),
      UserAvatar(16, userDetails),
      const SizedBox(width: 16),
      Padding(
        padding: EdgeInsets.only(left: 16),
        child: Row(
          children: [
            UserNameWidget(userDetails: userDetails),
            SizedBox(width: 8),
            if (userDetails != null && isPotm && rate != null)
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
          borderRadius: BorderRadius.all(Radius.circular(10)),
          child: LinearProgressIndicator(
            value: (rate ?? 0) / 5.0,
            color: Palette.primary,
            backgroundColor: Palette.greyLighter,
          ),
        ),
      ),
      SizedBox(width: 16),
      Container(
        width: 22,
        child: Text((rate == null) ? "  -" : rate.toStringAsFixed(1),
            style: TextPalette.getBodyText(Palette.black)),
      ),
    ];

    index++;
    return Padding(
        padding: (index > 2) ? EdgeInsets.only(top: 16) : EdgeInsets.zero,
        child: InkWell(
            onTap: userDetails == null
                ? null
                : () => ModalBottomSheet.showNutmegModalBottomSheet(
                    context, JoinedPlayerBottomModal(userDetails)),
            child: Row(children: widgets)));
  }

  @override
  Widget build(BuildContext context) {
    var child;
    var dayDateFormat = DateFormat(
        "EEEE, MMM dd HH:mm", getLanguageLocaleWatch(context).languageCode);

    var state = context.watch<MatchState>();
    var match = state.match;

    if (match == null) {
      return Container();
    }

    var sportCenter = match.sportCenter!;
    var ratings = state.ratings;

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
                    dayDateFormat.format(
                            match.getLocalizedTime().add(Duration(days: 1))) +
                        " ${gmtSuffix(sportCenter.timezoneId)}"),
                style: TextPalette.bodyText,
                textAlign: TextAlign.center,
              ),
            ],
          ));
    } else {
      var userState = context.watch<UsersState>();

      var loadSkeleton = ratings == null;
      child = (loadSkeleton)
          ? StatsSkeleton()
          : Builder(
              builder: (context) {
                int index = 1;

                return Column(
                  children: [
                    Builder(
                      builder: (context) {
                        Map<String, double?> userAndRate = {};
                        match.going.keys
                            .forEach((u) => userAndRate[u] = ratings.scores[u]);
                        var entries = userAndRate.entries.toList();
                        entries.sort((a, b) =>
                            (b.value ?? -1).compareTo((a.value ?? -1)));

                        var filteredEntries = entries.take(5).toList();

                        return Column(
                          children: [
                            ...filteredEntries.map((e) {
                              index++;
                              return userRow(
                                  context, e, index, userState, ratings);
                            }).toList(),
                            if (entries.length > 5) ...[
                              InkWell(
                                onTap: () {
                                  ModalBottomSheet.showNutmegModalBottomSheet(
                                    context,
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(
                                            AppLocalizations.of(context)!
                                                .matchStatsTitle,
                                            style: TextPalette.h2,
                                          ),
                                        ),
                                        ...entries.map((e) {
                                          return userRow(
                                              context,
                                              e,
                                              entries.indexOf(e) + 1,
                                              userState,
                                              ratings);
                                        }).toList(),
                                      ],
                                    ),
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Palette.greyDark,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    )
                  ],
                );
              },
            );
    }

    return InfoContainerWithTitleAndSubtitleAndAction(
      title: AppLocalizations.of(context)!.matchStatsTitle,
      subtitle: AppLocalizations.of(context)!
          .matchStatsSubTitle(ratings?.numDistinctScoreVoters ?? 0),
      body: child,
      actionIcon: match.status == MatchStatus.rated ? Icons.share : null,
      onActionPressed: match.status == MatchStatus.rated
          ? () {
              ModalBottomSheet.showNutmegModalBottomSheet(
                context,
                ChangeNotifierProvider.value(
                  value: context.read<MatchState>(),
                  child: ShareableStats(
                    match: match,
                    ratings: ratings!,
                    userState: context.read<UserState>(),
                  ),
                ),
              );
            }
          : null,
    );
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

class ShareableStats extends StatefulWidget {
  final Match match;
  final Ratings ratings;
  final UserState userState;

  ShareableStats({
    required this.match,
    required this.ratings,
    required this.userState,
    Key? key,
  }) : super(key: key);

  @override
  State<ShareableStats> createState() => _ShareableStatsState();
}

class _ShareableStatsState extends State<ShareableStats> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _current = 0;
  final GlobalKey _statsKey = GlobalKey();
  final GlobalKey _awardsKey = GlobalKey();
  final GlobalKey _potmKey = GlobalKey();
  final GlobalKey _teamsKey = GlobalKey();

  Future<void> _captureAndShare(BuildContext context) async {
    try {
      final key = _current == 0 ? _statsKey : (_current == 1 ? _teamsKey : (_current == 2 ? _potmKey : _awardsKey));
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) {
        print('Failed to find render boundary');
        return;
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        print('Failed to convert image to byte data');
        return;
      }

      final params = ShareParams(
        text: AppLocalizations.of(context)!.shareMatchStatsText,
        files: [
          XFile.fromData(byteData.buffer.asUint8List(), name: 'match_stats.png')
        ],
      );

      final result = await SharePlus.instance.share(params);

      if (result.status != ShareResultStatus.success) {
        print('Failed to share the picture');
        print(result.status);
      }
    } catch (e) {
      print('Error sharing image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the total number of pages
    int totalPages = 1; // Stats page is always present
    if (widget.match.going.length > 1 && widget.match.hasTeams()) totalPages++;
    if (widget.ratings.potms != null && widget.ratings.potms!.isNotEmpty) totalPages++;
    totalPages++; // Awards page is always present

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
          child: Text(
            AppLocalizations.of(context)!.shareMatchStats,
            style: TextPalette.h2,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: CarouselSlider(
            carouselController: _carouselController,
            options: CarouselOptions(
              height: 400,
              viewportFraction: 1.0,
              enableInfiniteScroll: false,
              onPageChanged: (index, reason) {
                setState(() {
                  _current = index;
                });
              },
            ),
            items: [
              _buildStatsPage(context),
              if (widget.match.going.length > 1 && widget.match.hasTeams())
                _buildTeamsPage(context),
              if (widget.ratings.potms != null && widget.ratings.potms!.isNotEmpty)
                _buildPotmPage(context),
              _buildAwardsPage(context),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Palette.greyDark),
              onPressed: _current > 0
                  ? () => _carouselController.animateToPage(_current - 1)
                  : null,
            ),
            Container(
              width: 8,
              height: 8,
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _current == 0 ? Palette.primary : Palette.greyLighter,
              ),
            ),
            if (widget.match.going.length > 1 && widget.match.hasTeams())
              Container(
                width: 8,
                height: 8,
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _current == 1 ? Palette.primary : Palette.greyLighter,
                ),
              ),
            if (widget.ratings.potms != null && widget.ratings.potms!.isNotEmpty)
              Container(
                width: 8,
                height: 8,
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _current == 2 ? Palette.primary : Palette.greyLighter,
                ),
              ),
            Container(
              width: 8,
              height: 8,
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _current == totalPages - 1 ? Palette.primary : Palette.greyLighter,
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: Palette.greyDark),
              onPressed: _current < totalPages - 1
                  ? () => _carouselController.animateToPage(_current + 1)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: IconButton(
            icon: Icon(Icons.share, color: Palette.primary),
            onPressed: () => _captureAndShare(context),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsPage(BuildContext context) {
    var userState = context.watch<UsersState>();
    var entries = widget.ratings.scores.entries.toList();
    entries.sort((a, b) => (b.value).compareTo(a.value));

    // Get top 5 players
    var topPlayers = entries.take(5).toList();

    // Format the date
    var dateFormat = DateFormat(
        "EEEE, MMM dd yyyy", getLanguageLocaleWatch(context).languageCode);
    var formattedDate = dateFormat.format(widget.match.getLocalizedTime());

    return RepaintBoundary(
      key: _statsKey,
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text(
                "$formattedDate - " +
                    (widget.match.sportCenter?.getName() ?? ''),
                style: TextPalette.h2,
              ),
            ),
            const SizedBox(height: 24),
            ...topPlayers.map((e) {
              return Stats.userRow(context, e, topPlayers.indexOf(e) + 1,
                  userState, widget.ratings);
            }).toList(),
            Spacer(),
            Image.asset(
              "assets/nutmeg_white.png",
              height: 24,
              color: Palette.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAwardsPage(BuildContext context) {
    var userState = context.watch<UsersState>();
    var dateFormat = DateFormat(
        "EEEE, MMM dd yyyy", getLanguageLocaleWatch(context).languageCode);
    var formattedDate = dateFormat.format(widget.match.getLocalizedTime());

    return RepaintBoundary(
      key: _awardsKey,
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "$formattedDate - " +
                    (widget.match.sportCenter?.getName() ?? ''),
                style: TextPalette.h2,
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      for (var i = 0; i < awards.length; i += 2)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildAwardBox(
                                  context,
                                  awards[i],
                                  userState,
                                  widget.ratings,
                                ),
                              ),
                              if (i + 1 < awards.length) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildAwardBox(
                                    context,
                                    awards[i + 1],
                                    userState,
                                    widget.ratings,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
              Spacer(),
              Center(
                child: Image.asset(
                  "assets/nutmeg_white.png",
                  height: 24,
                  color: Palette.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPotmPage(BuildContext context) {
    var userState = context.watch<UsersState>();
    var dateFormat = DateFormat(
        "EEEE, MMM dd yyyy", getLanguageLocaleWatch(context).languageCode);
    var formattedDate = dateFormat.format(widget.match.getLocalizedTime());

    return RepaintBoundary(
      key: _potmKey,
      child: Container(
        decoration: BoxDecoration(
          color: Palette.primary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "$formattedDate - " +
                    (widget.match.sportCenter?.getName() ?? ''),
                style: TextPalette.getH2(Palette.white),
              ),
              const SizedBox(height: 24),
              if (widget.ratings.potms != null && widget.ratings.potms!.isNotEmpty)
                ...widget.ratings.potms!.map((potmId) {
                  final user = userState.getUserDetail(potmId);
                  return Column(
                    children: [
                      UserAvatar(48, user),
                      const SizedBox(height: 24),
                      Text(
                        "Player of the Match",
                        textAlign: TextAlign.center,
                        style: TextPalette.h1Inverted,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Congratulations ${user?.name}!",
                        textAlign: TextAlign.center,
                        style: TextPalette.getBodyText(Palette.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "You won the Player of the Match award",
                        textAlign: TextAlign.center,
                        style: TextPalette.getBodyText(Palette.white),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/potm_badge.png',
                            height: 40,
                          ),
                          const SizedBox(width: 8),
                          Text("+1", style: TextPalette.getH2(Palette.white))
                        ],
                      ),
                    ],
                  );
                }).toList(),
              const Spacer(),
              Center(
                child: Image.asset(
                  "assets/nutmeg_white.png",
                  height: 24,
                  color: Palette.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamsPage(BuildContext context) {
    var dateFormat = DateFormat(
        "EEEE, MMM dd yyyy", getLanguageLocaleWatch(context).languageCode);
    var formattedDate = dateFormat.format(widget.match.getLocalizedTime());

    return RepaintBoundary(
      key: _teamsKey,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "$formattedDate - " +
                    (widget.match.sportCenter?.getName() ?? ''),
                style: TextPalette.h2,
              ),
              // const SizedBox(height: 12),
              ChangeNotifierProvider.value(
                value: context.read<MatchState>(),
                child: TeamsWidget(matchId: widget.match.documentId, shareableVersion: true),
              ),
              const Spacer(),
              Center(
                child: Image.asset(
                  "assets/nutmeg_white.png",
                  height: 18,
                  color: Palette.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Define awards with their names
  static final List<Map<String, dynamic>> awards = [
    {
      'id': 'best_goal',
      'name': (BuildContext context) =>
          AppLocalizations.of(context)!.bestGoalAwardName,
    },
    {
      'id': 'best_striker',
      'name': (BuildContext context) =>
          AppLocalizations.of(context)!.bestStrikerAwardName,
    },
    {
      'id': 'best_goalkeeper',
      'name': (BuildContext context) =>
          AppLocalizations.of(context)!.bestGoalkeeperAwardName,
    },
    {
      'id': 'best_defender',
      'name': (BuildContext context) =>
          AppLocalizations.of(context)!.bestDefenderAwardName,
    },
  ];

  Widget _buildAwardBox(
    BuildContext context,
    Map<String, dynamic> award,
    UsersState userState,
    Ratings ratings,
  ) {
    final awardId = award['id']!;
    final userVotes = ratings.awards[awardId] ?? {};
    final sortedVotes = userVotes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedVotes.isEmpty) return const SizedBox.shrink();

    final winnerId = sortedVotes.first.key;
    final winner = userState.getUserDetail(winnerId);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Palette.greyLighter,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            UserAvatar(28, winner),
            const SizedBox(height: 16),
            Text(
              award['name'](context),
              style: TextPalette.h3,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),            
            const SizedBox(height: 2),
            Text(
              winner?.getShortName() ?? "Unknown",
              style: TextPalette.bodyText,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
