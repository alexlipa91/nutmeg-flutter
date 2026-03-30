import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/config/app_config.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/PageTemplate.dart';
import 'package:readmore/readmore.dart';
import 'package:nutmeg/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/MatchesState.dart';
import '../state/UserState.dart';
import '../state/UserRatings.dart';
import '../utils/InfoModals.dart';
import '../utils/share_utils.dart';
import '../widgets/Buttons.dart' as buttons;
import '../widgets/ButtonsWithLoader.dart';
import '../widgets/ModalBottomSheet.dart';
import '../widgets/PlayerBottomModal.dart';
import '../widgets/Skeletons.dart';

import '../utils/web_url.dart';
import '../widgets/TeamsWidget.dart';
import 'BottomBarMatch.dart';
import 'PaymentDetailsDescription.dart';
import 'package:nutmeg/widgets/ModalPaymentDescriptionArea.dart';

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
    _handlePaymentOutcome();
    myInitState();
  }

  @override
  void didUpdateWidget(MatchDetailsImpl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paymentOutcome != oldWidget.paymentOutcome) {
      _handlePaymentOutcome();
    }
  }

  void _handlePaymentOutcome() {
    if (widget.paymentOutcome == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (ModalBottomSheet.isOpen) Navigator.of(context).pop();
      if (widget.paymentOutcome == "success") {
        await PaymentDetailsDescription.communicateSuccessToUser(
            context, widget.matchId);
      } else {
        GenericInfoModal(
                title: AppLocalizations.of(context)!.paymentFailedTitle,
                description:
                    AppLocalizations.of(context)!.paymentFailedSubtitle)
            .show(context);
      }
    });
  }

  Future<void> myInitState() async {
    var state = context.read<MatchState>();

    await refreshState();
    // we need to wait to load all logged user info before building the UI

    var match = state.match!;
    var usersState = context.read<UsersState>();
    match.going.forEach((key, value) {
      usersState.fetchUserDetails(key);
    });
    match.waitList.forEach((key, value) {
      usersState.fetchUserDetails(key);
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
          children: [
            Expanded(
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 1100),
                  child: Row(
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
                                      AppLocalizations.of(context)!
                                          .linkCopiedToClipboard,
                                      style: TextStyle(color: Palette.greyDark),
                                    ),
                                    backgroundColor:
                                        Palette.white.withOpacity(0.92),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } else {
                              await DynamicLinks.shareMatchFunction(
                                  context, match);
                            }
                          }, Palette.black, 25.0),
                        ),
                    ],
                  ),
                ),
              ),
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

  var matchInfo = MatchInfo(match!, sportCenter);

  var teamsWidget = match.going.length > 1 && match.hasTeams()
      ? TeamsWidget(matchId: match.documentId)
      : null;

  // Organizers always see the player list (except when rated/frozen).
  // Regular users see it when the match isn't finished and teams aren't shown.
  var showPlayerList = organizerView
      ? match.status != MatchStatus.rated
      : !match.isMatchFinished() && teamsWidget == null;
  var infoPlayersList =
      showPlayerList ? PlayerList(match: match, withJoinButton: false) : null;

  var waitListWidget =
      (!match.isMatchFinished() && match.numPlayersInWaitList() > 0)
          ? WaitListWidget(match: match)
          : null;

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
    // Payment policy only applies when payment is handled by Nutmeg
    if (match.isManualPayment) return null;

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
      rules.add(AppLocalizations.of(context)!.freeCancellationPolicy("24"));
    }

    if (rules.length == 0) {
      return null;
    }

    return RuleCard(AppLocalizations.of(context)!.paymentPolicyHeader,
        rules.join("\n"), large);
  };

  var loggedUser = context.read<UserState>().getLoggedUserDetails();
  var isUserGoing = match.isUserGoing(loggedUser);

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
  final primaryColumnWidgets = <Widget>[
    if (infoPlayersList != null) infoPlayersList,
    if (organizerView) ...[
      if (waitListWidget != null) waitListWidget,
      if (teamsWidget != null) teamsWidget,
    ] else ...[
      if (teamsWidget != null) teamsWidget,
      if (waitListWidget != null) waitListWidget,
    ],
    if (stats != null) stats,
    if (awards != null) awards,
  ];

  if (constraints.maxWidth < 800) {
    widgets = interleave([
      // title
      // info box
      matchInfo,
      // stats
      ...primaryColumnWidgets,
      // horizontal players list or teams
      sportCenterDetails,
      if (rules(false) != null) rules(false)!,
      if (organiserBadge != null) organiserBadge
    ], SizedBox(height: 16));
  } else {
    widgets = [
      // match info full width at the top
      Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 1100),
          child: matchInfo,
        ),
      ),
      SizedBox(height: 16),
      // two balanced columns below
      Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 1100),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      interleave(primaryColumnWidgets, SizedBox(height: 16)),
                ),
              ),
              SizedBox(width: 20),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: interleave([
                    sportCenterDetails,
                    if (organiserBadge != null) organiserBadge,
                    if (rules(true) != null) rules(true)!,
                  ], SizedBox(height: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
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

    var isOrganizer = context.watch<MatchState>().isLoggedUserOrganizer();
    var isNotFrozen = match.status != MatchStatus.rated &&
        match.status != MatchStatus.cancelled;
    var canRemovePlayers = isOrganizer && isNotFrozen;
    var hasSpotsLeft = match.numPlayersGoing() < match.maxPlayers;

    List<Widget> cards = [];
    if (withJoinButton) {
      cards.add(EmptyPlayerCard(matchId: match.documentId));
    }
    if (isOrganizer && hasSpotsLeft && isNotFrozen) {
      cards.add(_AddPlayerCard(matchId: match.documentId));
    }
    match.getGoingUsersByTime().forEach((s) => cards.add(PlayerCard(
          s,
          matchId: match.documentId,
          showRemove: canRemovePlayers,
          avatarRadius: 26,
        )));

    widgets.add(SizedBox(width: 16));
    widgets.addAll(interleave(cards, SizedBox(width: 4)));
    widgets.add(SizedBox(width: 16));

    return InfoContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(getTitle(context, match), style: TextPalette.h2)),
          SizedBox(height: 16),
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

class WaitListWidget extends StatelessWidget {
  final Match match;

  const WaitListWidget({Key? key, required this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var waitListUsers = match.getWaitListUsersByTime();

    if (waitListUsers.isEmpty) return Container();

    var isOrganizer = context.watch<MatchState>().isLoggedUserOrganizer();
    var isFull = match.isFull();

    List<Widget> cards = waitListUsers
        .map((userId) => PlayerCard(
              userId,
              matchId: match.documentId,
              showPromote: isOrganizer,
              isPromoteEnabled: isOrganizer && !isFull,
              avatarRadius: 26,
            ))
        .toList();

    List<Widget> widgets = [];
    widgets.add(SizedBox(width: 16));
    widgets.addAll(interleave(cards, SizedBox(width: 4)));
    widgets.add(SizedBox(width: 16));

    return InfoContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text("Waitlist (${match.numPlayersInWaitList()})",
                  style: TextPalette.h2)),
          SizedBox(height: 16),
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
            SizedBox(height: 16),
            IconList.fromIcon({
              Icons.calendar_month_outlined:
                  formatDay(match.getLocalizedTime(), context),
              Icons.access_time_outlined:
                  "${DateFormat('HH:mm').format(match.getLocalizedTime())}"
                      " (${gmtSuffix(sportCenter.timezoneId)})"
                      " - ${match.duration.inMinutes} min",
              if (match.isPrivate)
                Icons.lock_outline:
                    AppLocalizations.of(context)!.privateMatchDesc,
            }),
            if (match.price != null) ...[
              SizedBox(height: 12),
              Row(children: [
                Icon(Icons.local_offer_outlined,
                    color: Palette.black, size: 18),
                SizedBox(width: 16),
                Text(formatCurrency(match.price!.basePrice),
                    style: TextPalette.listItem),
                Spacer(),
                if (!match.isManualPayment)
                  _NutmegPayBadge(
                      match: match, isOrganizerView: isOrganizerView),
                if (match.isManualPayment)
                  _ManualPayBadge(
                      match: match, isOrganizerView: isOrganizerView),
              ]),
            ],
            if (matchWidget != null)
              Column(children: [
                SizedBox(height: 16),
                NutmegDivider(horizontal: true),
                SizedBox(height: 8),
                matchWidget
              ]),
            if (isOrganizerView &&
                match.dateTime.isAfter(DateTime.now()) &&
                match.status != MatchStatus.cancelled)
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Row(children: [
                  GenericButtonWithLoaderAndErrorHandling(
                    AppLocalizations.of(context)!
                        .cancelMatchAction
                        .toUpperCase(),
                    (_) async {
                      await GenericInfoModal(
                        title: AppLocalizations.of(context)!.cancelMatchTitle,
                        description:
                            AppLocalizations.of(context)!.cancelMatchSubtitle,
                        action: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: GenericButtonWithLoaderAndErrorHandling(
                                AppLocalizations.of(context)!.confirmButtonText,
                                (_) async {
                                  await MatchesController.cancelMatch(
                                      match.documentId);
                                  await context
                                      .read<MatchesState>()
                                      .getMatch(match.documentId)
                                      .fetchMatch();
                                  Navigator.pop(context);
                                },
                                Primary(),
                              ),
                            ),
                          ],
                        ),
                      ).show(context);
                    },
                    Destructive(),
                  ),
                ]),
              ),
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
    } else if (match.status == MatchStatus.rated) {
      icon = Icons.check_circle_outline;
      color = Palette.greyDark;
      text = AppLocalizations.of(context)!.matchSavedStatus;
    } else if (match.status == MatchStatus.cancelled) {
      icon = Icons.do_disturb_alt_outlined;
      color = Palette.destructive;
      text = AppLocalizations.of(context)!.cancelledStatus;
    } else if (match.status == MatchStatus.open &&
        match.getMissingPlayers() > 0) {
      icon = Icons.hourglass_empty_outlined;
      color = Palette.primary;
      text = AppLocalizations.of(context)!
          .waitingForPlayersStatus(match.getMissingPlayers());
    } else if (match.status == MatchStatus.open &&
            match.getMissingPlayers() == 0 ||
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
  static var width = 88.0;

  final String userId;
  final String? matchId;
  final bool showRemove;
  final bool showPromote;
  final bool isPromoteEnabled;
  final double avatarRadius;

  PlayerCard(this.userId,
      {this.matchId,
      this.showRemove = false,
      this.showPromote = false,
      this.isPromoteEnabled = false,
      this.avatarRadius = 30});

  @override
  Widget build(BuildContext context) {
    var userData = context.watch<UsersState>().getUserDetail(userId);
    if (userData == null) {
      context.read<UsersState>().fetchUserDetails(userId);
    }
    var hasOverlay = showRemove || showPromote;

    return SizedBox(
        width: width,
        child: Column(children: [
          Padding(
            padding: EdgeInsets.only(top: 6, right: 6),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatarWithBottomModal(
                    userData: userData, radius: avatarRadius),
                if (showRemove)
                  Positioned(
                    right: -5.5,
                    top: -3,
                    child: InkWell(
                      onTap: () async {
                        if (matchId == null) return;

                        var name = (userData?.name ?? "Player")
                            .split(" ")
                            .first
                            .trim();
                        if (name.isEmpty) name = "Player";

                        var match = context.read<MatchState>().match!;
                        var hasPayment = match.hasPaymentIntent(userId);

                        var descriptionText = AppLocalizations.of(context)!
                            .removePlayerSubtitle(name);
                        if (hasPayment) {
                          descriptionText += "\n" +
                              AppLocalizations.of(context)!
                                  .removePlayerRefundMessage(name);
                        }

                        await GenericInfoModal(
                          title:
                              AppLocalizations.of(context)!.removePlayerTitle,
                          description: descriptionText,
                          content: hasPayment
                              ? ModalPaymentDescriptionArea(
                                  rows: [],
                                  finalRow: Row(
                                    children: [
                                      Text(
                                          AppLocalizations.of(context)!
                                              .leaveMatchRefundTitle,
                                          style: TextPalette.h3),
                                      Expanded(
                                          child: Text(
                                        formatCurrency(match.price!.basePrice) +
                                            " euro",
                                        style: TextPalette.h3,
                                        textAlign: TextAlign.end,
                                      ))
                                    ],
                                  ),
                                )
                              : null,
                          action: Row(
                            children: [
                              Expanded(
                                child: GenericButtonWithLoaderAndErrorHandling(
                                  AppLocalizations.of(context)!
                                      .removePlayerTitle
                                      .toUpperCase(),
                                  (_) async {
                                    await context
                                        .read<MatchState>()
                                        .removeUserFromMatch(userId);
                                    Navigator.of(context).pop(true);

                                    if (hasPayment) {
                                      GenericInfoModal(
                                        title:
                                            "A refund of ${formatCurrency(match.price!.basePrice)} "
                                            "was issued for $name",
                                        description:
                                            "They will receive the money in 3 to 5 business days.",
                                        action: null,
                                      ).show(context);
                                    }
                                  },
                                  Primary(),
                                ),
                              )
                            ],
                          ),
                        ).show(context);
                      },
                      child: Container(
                        padding: EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Palette.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.12),
                              offset: Offset(0, 1),
                            )
                          ],
                        ),
                        child: Icon(
                          Icons.remove_circle,
                          color: Palette.destructive,
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                if (showPromote)
                  Positioned(
                    right: -5.5,
                    top: -3,
                    child: InkWell(
                      onTap: isPromoteEnabled
                          ? () async {
                              if (matchId == null) return;

                              var matchState = context.read<MatchState>();
                              var name = (userData?.name ?? "Player")
                                  .split(" ")
                                  .first
                                  .trim();
                              if (name.isEmpty) name = "Player";

                              await GenericInfoModal(
                                title: "Add to match",
                                description:
                                    "Are you sure you want to move $name from the waitlist to the match?",
                                action: Row(
                                  children: [
                                    Expanded(
                                      child:
                                          GenericButtonWithLoaderAndErrorHandling(
                                        AppLocalizations.of(context)!
                                            .confirmButtonText,
                                        (_) async {
                                          await matchState
                                              .promoteUserFromWaitList(userId);
                                          Navigator.of(context).pop(true);
                                        },
                                        Primary(),
                                      ),
                                    )
                                  ],
                                ),
                              ).show(context);
                            }
                          : null,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isPromoteEnabled
                              ? Palette.primary
                              : Palette.greyLighter,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.12),
                              offset: Offset(0, 1),
                            )
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_upward,
                          color: Palette.white,
                          size: 14,
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
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextPalette.getBodyText(Palette.black))
        ]));
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

    return SizedBox(
        width: PlayerCard.width,
        child: InkWell(
          onTap: () => JoinModal.onJoinGameAction(
              context, userState, matchState, matchesState),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
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
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextPalette.getBodyText(Palette.primary))
          ]),
        ));
  }
}

class _AddPlayerCard extends StatelessWidget {
  final String matchId;

  const _AddPlayerCard({required this.matchId});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: PlayerCard.width,
        child: InkWell(
          onTap: () {
            var organizerId = context.read<UserState>().getLoggedUserId()!;
            var matchState = context.read<MatchState>();
            var match = matchState.match!;
            var alreadyGoingIds = match.going.keys.toSet();

            ModalBottomSheet.showNutmegModalBottomSheet(
              context,
              _PlayerPickerSheet(
                organizerId: organizerId,
                alreadyGoingIds: alreadyGoingIds,
                onPlayerSelected: (String playerId) async {
                  await matchState.addUserToMatch(playerId);
                },
              ),
            ).then((result) async {
              if (result != "open_add_guest") return;

              final guestName =
                  await ModalBottomSheet.showNutmegModalBottomSheet<String>(
                context,
                _AddGuestNameSheet(),
              );
              if (guestName == null || guestName.trim().isEmpty) return;

              try {
                await matchState.addGuestToMatch(guestName.trim());
              } catch (e) {
                if (!context.mounted) return;
                final rawMessage = e.toString();
                final errorMessage = rawMessage
                    .replaceFirst(RegExp(r'^Exception:\s*'), '')
                    .trim();
                await GenericInfoModal(
                  title: AppLocalizations.of(context)!.genericErrorMessage,
                  description: errorMessage.isNotEmpty
                      ? errorMessage
                      : AppLocalizations.of(context)!.genericErrorDesc,
                ).show(context);
              }
            });
          },
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Padding(
              padding: EdgeInsets.only(top: 6, right: 6),
              child: DottedBorder(
                padding: EdgeInsets.zero,
                borderType: BorderType.Circle,
                color: Palette.green,
                strokeWidth: 1.5,
                dashPattern: [4],
                child: CircleAvatar(
                  radius: 24,
                  child: Icon(Icons.person_add, color: Palette.green, size: 18),
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(AppLocalizations.of(context)!.addPlayerLabel,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextPalette.getBodyText(Palette.green))
          ]),
        ));
  }
}

class _PlayerPickerSheet extends StatefulWidget {
  final String organizerId;
  final Set<String> alreadyGoingIds;
  final Future<void> Function(String playerId) onPlayerSelected;

  const _PlayerPickerSheet({
    required this.organizerId,
    required this.alreadyGoingIds,
    required this.onPlayerSelected,
  });

  @override
  State<_PlayerPickerSheet> createState() => _PlayerPickerSheetState();
}

class _PlayerPickerSheetState extends State<_PlayerPickerSheet> {
  Map<String, int>? _playerCounts;
  String? _addingPlayerId;
  bool _openingGuestModal = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  void _loadPlayers() {
    var userDetails = context.read<UserState>().getLoggedUserDetails();
    var counts = Map<String, int>.from(userDetails?.organizerPlayers ?? {});
    // remove players already in the match
    counts.removeWhere((k, _) => widget.alreadyGoingIds.contains(k));
    setState(() => _playerCounts = counts);
    // fetch user details for display
    var usersState = context.read<UsersState>();
    for (var id in counts.keys) {
      usersState.fetchUserDetails(id);
    }
  }

  Widget _buildPlayerRow(MapEntry<String, int> entry, UserDetails? ud) {
    var isLoading = ud == null;
    var isAddingThis = _addingPlayerId == entry.key;
    var isAddingAny = _addingPlayerId != null;

    return InkWell(
      onTap: (isAddingAny || isLoading)
          ? null
          : () async {
              setState(() => _addingPlayerId = entry.key);
              try {
                await widget.onPlayerSelected(entry.key);
                if (mounted) Navigator.of(context).pop();
              } catch (e) {
                if (!mounted) return;
                final rawMessage = e.toString();
                final errorMessage = rawMessage
                    .replaceFirst(RegExp(r'^Exception:\s*'), '')
                    .trim();
                await GenericInfoModal(
                  title: AppLocalizations.of(context)!.genericErrorMessage,
                  description: errorMessage.isNotEmpty
                      ? errorMessage
                      : AppLocalizations.of(context)!.genericErrorDesc,
                ).show(context);
              } finally {
                if (mounted) {
                  setState(() => _addingPlayerId = null);
                }
              }
            },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            UserAvatar(20, ud),
            SizedBox(width: 12),
            Expanded(
              child: isLoading
                  ? Container(
                      height: 12,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Palette.greyLighter,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    )
                  : Text(
                      UserDetails.getDisplayName(ud),
                      style: TextPalette.getBodyText(Palette.black),
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            if (isAddingThis)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Palette.primary,
                ),
              )
            else
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Palette.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  size: 18,
                  color: Palette.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _onAddGuestPressed() async {
    if (_addingPlayerId != null || _openingGuestModal) return;
    setState(() => _openingGuestModal = true);
    Navigator.of(context).pop("open_add_guest");
  }

  @override
  Widget build(BuildContext context) {
    var usersState = context.watch<UsersState>();
    var maxHeight = MediaQuery.of(context).size.height * 0.55;

    if (_playerCounts == null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    var sorted = _playerCounts!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var filtered = _searchQuery.isEmpty
        ? sorted
        : sorted.where((entry) {
            var ud = usersState.getUserDetail(entry.key);
            if (ud == null) return true; // keep loading ones visible
            var name = UserDetails.getDisplayName(ud).toLowerCase();
            return name.contains(_searchQuery.toLowerCase());
          }).toList();
    final hasPlayers = sorted.isNotEmpty;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context)!.addPlayerLabel,
              style: TextPalette.h4),
          SizedBox(height: 4),
          Text(AppLocalizations.of(context)!.pickFromPlayersSubtitle,
              style: TextPalette.bodyText),
          if (hasPlayers) ...[
            SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchByNameHint,
                hintStyle: TextPalette.getBodyText(Palette.greyDark),
                prefixIcon:
                    Icon(Icons.search, color: Palette.greyDark, size: 20),
                filled: true,
                fillColor: Palette.greyLighter,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
              style: TextPalette.getBodyText(Palette.black),
            ),
            SizedBox(height: 12),
          ] else
            SizedBox(height: 10),
          Flexible(
            child: (!hasPlayers || filtered.isEmpty)
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                          !hasPlayers
                              ? AppLocalizations.of(context)!.noPlayersAvailable
                              : AppLocalizations.of(context)!.noResults,
                          style: TextPalette.getBodyText(Palette.greyDark)),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      var entry = filtered[index];
                      var ud = usersState.getUserDetail(entry.key);
                      return _buildPlayerRow(entry, ud);
                    },
                  ),
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: GenericButtonWithLoader(
              AppLocalizations.of(context)!.addGuestLabel.toUpperCase(),
              (_addingPlayerId != null || _openingGuestModal)
                  ? null
                  : (BuildContext context) async => _onAddGuestPressed(),
              Primary(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddGuestNameSheet extends StatefulWidget {
  @override
  State<_AddGuestNameSheet> createState() => _AddGuestNameSheetState();
}

class _AddGuestNameSheetState extends State<_AddGuestNameSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isValid = true;

  @override
  Widget build(BuildContext context) {
    return InfoContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.addGuestTitle,
              style: TextPalette.h2),
          SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.addGuestSubtitle,
              style: TextPalette.bodyText),
          SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: AppLocalizations.of(context)!.guestNameHint,
              errorText:
                  _isValid ? null : AppLocalizations.of(context)!.requiredError,
            ),
            textInputAction: TextInputAction.done,
            onChanged: (v) {
              if (!_isValid && v.trim().isNotEmpty) {
                setState(() => _isValid = true);
              }
            },
            onSubmitted: (_) => _submit(),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: GenericButtonWithLoader(
              AppLocalizations.of(context)!.confirmButtonText,
              (BuildContext context) async => _submit(),
              Primary(),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _isValid = false);
      return;
    }
    Navigator.of(context).pop(name);
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
    if (userDetails == null) {
      userState.fetchUserDetails(e.key);
    }
    double? rate = e.value;
    bool isPotm = (ratings.potms ?? []).contains(e.key);

    return Padding(
        padding: (index >= 2) ? EdgeInsets.only(top: 16) : EdgeInsets.zero,
        child: InkWell(
            onTap: userDetails == null
                ? null
                : () => ModalBottomSheet.showNutmegModalBottomSheet(
                    context, JoinedPlayerBottomModal(userDetails)),
            child: Row(
              children: [
                SizedBox(
                    width: 18,
                    child: Text(index.toString(), style: TextPalette.bodyText)),
                const SizedBox(width: 8),
                UserAvatar(16, userDetails),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Row(
                      children: [
                        Flexible(
                          child: UserNameWidget(userDetails: userDetails),
                        ),
                        if (userDetails != null && isPotm && rate != null) ...[
                          const SizedBox(width: 8),
                          Image.asset(
                            "assets/potm_badge.png",
                            width: 20,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 8,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      child: LinearProgressIndicator(
                        value: (rate ?? 0) / 5.0,
                        color: Palette.primary,
                        backgroundColor: Palette.greyLighter,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 28,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      (rate == null) ? "—" : rate.toStringAsFixed(1),
                      style: TextPalette.getBodyText(Palette.black),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
              ],
            )));
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
    } else if (ratings != null &&
        ratings.ratingsNotComputedReason != null &&
        ratings.ratingsNotComputedReason!.isNotEmpty) {
      final loc = AppLocalizations.of(context)!;
      final isNotEnough = ratings.ratingsNotComputedReason ==
          Ratings.notEnoughRatingsReason;
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
                isNotEnough
                    ? loc.statsNotEnoughRatingsTitle
                    : loc.statsRatingsUnavailableTitle,
                style: TextPalette.h2,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                isNotEnough
                    ? loc.statsNotEnoughRatingsSubtitle
                    : loc.statsRatingsUnavailableSubtitle,
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
                int index = 0;

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
      subtitle: match.status == MatchStatus.rated
          ? AppLocalizations.of(context)!
              .matchStatsSubTitle(ratings?.numDistinctScoreVoters ?? 0)
          : null,
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
  final TextAlign textAlign;

  const UserNameWidget({
    Key? key,
    this.userDetails,
    this.textAlign = TextAlign.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // fixme text overflow
    if (userDetails == null) {
      if (textAlign == TextAlign.end || textAlign == TextAlign.right) {
        return Align(
          alignment: Alignment.centerRight,
          child: Skeletons.sText,
        );
      }
      return Skeletons.sText;
    }

    var name = UserDetails.getDisplayName(userDetails).split(" ").first;

    final text = Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: TextPalette.getBodyText(Palette.black),
    );

    // Fill horizontal space so [textAlign] applies (e.g. right team in TeamsWidget).
    if (textAlign != TextAlign.start) {
      return SizedBox(width: double.infinity, child: text);
    }
    return text;
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

class _ManualPayBadge extends StatelessWidget {
  final Match match;
  final bool isOrganizerView;

  const _ManualPayBadge({required this.match, required this.isOrganizerView});

  void _showManualPaymentBreakdown(BuildContext context) {
    final usersState = context.read<UsersState>();
    final matchState = context.read<MatchState>();
    final l10n = AppLocalizations.of(context)!;

    final playerIds =
        match.going.keys.where((id) => id != match.organizerId).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: matchState,
        child: Builder(builder: (context) {
          final currentMatch = context.watch<MatchState>().match ?? match;
          final paidCount =
              playerIds.where((id) => currentMatch.hasUserPaid(id)).length;

          return Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.payOutsideNutmeg, style: TextPalette.h2),
                SizedBox(height: 8),
                Text("$paidCount/${playerIds.length} ${l10n.paid}",
                    style: TextPalette.bodyText),
                SizedBox(height: 16),
                ...playerIds.map((userId) {
                  final ud = usersState.getUserDetail(userId);
                  if (ud == null) {
                    usersState.fetchUserDetails(userId);
                  }
                  final playerPaid = currentMatch.hasUserPaid(userId);

                  return InkWell(
                    onTap: isOrganizerView
                        ? () async {
                            final newStatus =
                                playerPaid ? "not_yet_paid" : "paid";
                            await matchState.setManualPaymentStatus(
                                userId, newStatus);
                          }
                        : null,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        UserAvatar(14, ud),
                        SizedBox(width: 10),
                        Expanded(
                          child: ud == null
                              ? Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                    width: 110,
                                    child: Skeletons.sText,
                                  ),
                                )
                              : Text(
                                  ud.name ?? "Player",
                                  style: TextPalette.bodyText
                                      .copyWith(color: Palette.black),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: playerPaid
                                ? Palette.green.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: playerPaid
                                  ? Palette.green
                                  : Palette.greyLight,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (playerPaid)
                                Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(Icons.check,
                                      color: Palette.green, size: 12),
                                ),
                              Text(
                                playerPaid ? l10n.paid : l10n.notYet,
                                style: TextPalette.getBodyText(playerPaid
                                        ? Palette.green
                                        : Palette.greyDark)
                                    .copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  );
                }),
                SizedBox(height: 16),
                Row(children: [
                  Icon(Icons.info_outline, color: Palette.greyLight, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(l10n.manualPaymentDisclaimer,
                        style: TextPalette.getBodyText(Palette.greyDark)
                            .copyWith(fontSize: 12)),
                  ),
                ]),
              ],
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isOrganizerView) {
      return GestureDetector(
        onTap: () => _showManualPaymentBreakdown(context),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Palette.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(AppLocalizations.of(context)!.payOutsideNutmeg.toUpperCase(),
                style: TextPalette.getBodyText(Palette.white)
                    .copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
            SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Palette.white, size: 14),
          ]),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Palette.greyLight, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(AppLocalizations.of(context)!.payOutsideNutmeg,
          style: TextPalette.getBodyText(Palette.black)
              .copyWith(fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}

class PaymentInfoCard extends StatefulWidget {
  final Match match;
  final UserDetails organizerDetails;

  const PaymentInfoCard({
    Key? key,
    required this.match,
    required this.organizerDetails,
  }) : super(key: key);

  @override
  State<PaymentInfoCard> createState() => _PaymentInfoCardState();
}

class _PaymentInfoCardState extends State<PaymentInfoCard> {
  bool? _hasPaid;

  @override
  void initState() {
    super.initState();
    _loadPaymentStatus();
  }

  Future<void> _loadPaymentStatus() async {
    var prefs = await SharedPreferences.getInstance();
    var key = "${widget.match.documentId}-user-paid";
    setState(() {
      _hasPaid = prefs.getBool(key);
    });
  }

  Future<void> _setPaymentStatus(bool paid) async {
    var prefs = await SharedPreferences.getInstance();
    var key = "${widget.match.documentId}-user-paid";
    await prefs.setBool(key, paid);
    setState(() {
      _hasPaid = paid;
    });
  }

  @override
  Widget build(BuildContext context) {
    var organizerName =
        widget.organizerDetails.name?.split(" ").first ?? "Organizer";
    var paymentInfo = widget.organizerDetails.paymentInfo!;

    return InfoContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment_outlined, color: Palette.primary, size: 20),
              SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.paymentInfoHeader,
                  style: TextPalette.h2),
            ],
          ),
          SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.sharedPaymentDetails(organizerName),
            style: TextPalette.bodyText,
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Palette.greyLightest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              paymentInfo,
              style: TextPalette.getBodyText(Palette.black),
            ),
          ),
          SizedBox(height: 16),
          if (_hasPaid == true)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Palette.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Palette.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Palette.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(AppLocalizations.of(context)!.markedAsPaid,
                        style: TextPalette.getBodyText(Palette.green)),
                  ),
                  InkWell(
                    onTap: () => _setPaymentStatus(false),
                    child: Text(AppLocalizations.of(context)!.undo,
                        style: TextPalette.getBodyText(Palette.greyDark)
                            .copyWith(decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _setPaymentStatus(true),
                    icon: Icon(Icons.check, color: Palette.green),
                    label: Text(AppLocalizations.of(context)!.iPaid,
                        style: TextPalette.getBodyText(Palette.green)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Palette.green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _setPaymentStatus(false),
                    icon: Icon(Icons.schedule, color: Palette.greyDark),
                    label: Text(AppLocalizations.of(context)!.notYet,
                        style: TextPalette.getBodyText(Palette.greyDark)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Palette.greyLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
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
      final key = _current == 0
          ? _statsKey
          : (_current == 1
              ? _teamsKey
              : (_current == 2 ? _potmKey : _awardsKey));
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

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

      final result = await shareWithOrigin(
        context,
        text: AppLocalizations.of(context)!.shareMatchStatsText,
        files: [
          XFile.fromData(byteData.buffer.asUint8List(), name: 'match_stats.png')
        ],
      );

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
    if (widget.ratings.potms != null && widget.ratings.potms!.isNotEmpty)
      totalPages++;
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
              if (widget.ratings.potms != null &&
                  widget.ratings.potms!.isNotEmpty)
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
            if (widget.ratings.potms != null &&
                widget.ratings.potms!.isNotEmpty)
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
                color: _current == totalPages - 1
                    ? Palette.primary
                    : Palette.greyLighter,
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
              if (widget.ratings.potms != null &&
                  widget.ratings.potms!.isNotEmpty)
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
                child: TeamsWidget(
                    matchId: widget.match.documentId, shareableVersion: true),
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

class _NutmegPayBadge extends StatefulWidget {
  final Match match;
  final bool isOrganizerView;

  const _NutmegPayBadge({required this.match, required this.isOrganizerView});

  @override
  State<_NutmegPayBadge> createState() => _NutmegPayBadgeState();
}

class _NutmegPayBadgeState extends State<_NutmegPayBadge> {
  Map<String, dynamic>? _data;
  int _lastGoingCount = 0;

  @override
  void initState() {
    super.initState();
    _lastGoingCount = widget.match.going.length;
    if (widget.isOrganizerView) _fetch();
  }

  @override
  void didUpdateWidget(covariant _NutmegPayBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOrganizerView &&
        widget.match.going.length != _lastGoingCount) {
      _lastGoingCount = widget.match.going.length;
      _fetch();
    }
  }

  Future<void> _fetch() async {
    try {
      var result = await CloudFunctionsClient()
          .getFullResponse("matches/${widget.match.documentId}/collected");
      if (mounted)
        setState(() {
          _data = result;
        });
    } catch (_) {}
  }

  void _showPaymentBreakdown(BuildContext context) {
    final match = widget.match;
    final usersState = context.read<UsersState>();
    final goingIds = match.going.keys.toList();
    final l10n = AppLocalizations.of(context)!;

    final playersPaid = _data?["players_paid"] as int? ?? 0;
    final basePrice = match.price?.basePrice ?? 0;
    final feePerPlayer = match.isManualPayment ? 0 : AppConfig.nutmegFeeCents;
    final grossCollected = playersPaid * basePrice;
    final nutmegFees = playersPaid * feePerPlayer;
    final netCollected = grossCollected - nutmegFees;
    final releaseAmount = _data?["release_amount"] as int?;
    final releaseAt = _data?["release_at"] as String?;
    final releasedAt = _data?["released_at"] as String?;

    Widget? releaseRow;
    if (releaseAmount != null && releaseAmount > 0) {
      final releasedDate = releasedAt != null
          ? DateFormat.yMMMd().format(DateTime.parse(releasedAt).toLocal())
          : null;
      releaseRow = Row(children: [
        Icon(Icons.check_circle_outline, color: Palette.green, size: 14),
        SizedBox(width: 6),
        Expanded(
            child: Text(
          l10n.releaseCompletedText(formatCurrency(releaseAmount)) +
              (releasedDate != null ? " · $releasedDate" : ""),
          style: TextPalette.getBodyText(Palette.green).copyWith(fontSize: 12),
        )),
      ]);
    } else if (releaseAt != null && grossCollected > 0) {
      final releaseDate = DateTime.parse(releaseAt).toLocal();
      final formattedDate = DateFormat.yMMMd().add_Hm().format(releaseDate);
      releaseRow = Row(children: [
        Icon(Icons.schedule, color: Palette.greyDark, size: 14),
        SizedBox(width: 6),
        Expanded(
            child: Text(
          l10n.releaseScheduledText(formattedDate),
          style:
              TextPalette.getBodyText(Palette.greyDark).copyWith(fontSize: 12),
        )),
      ]);
    }

    GenericInfoModal(
      title: l10n.payThroughNutmeg,
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.nutmegPayCollectedSoFarSubtitle,
                textAlign: TextAlign.left,
                style: TextPalette.getBodyText(Palette.greyDark)
                    .copyWith(fontSize: 12),
              ),
            ),
          ),
          if (goingIds.isNotEmpty) const SizedBox(height: 8),
          ...goingIds.map((userId) {
            final ud = usersState.getUserDetail(userId);
            if (ud == null) {
              usersState.fetchUserDetails(userId);
            }
            final hasPaid = match.hasPaymentIntent(userId);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                UserAvatar(14, ud),
                SizedBox(width: 8),
                Expanded(
                  child: ud == null
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(width: 110, child: Skeletons.sText),
                        )
                      : Text(
                          ud.name ?? "Player",
                          style: TextPalette.bodyText
                              .copyWith(color: Palette.black),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                if (hasPaid)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle, color: Palette.green, size: 14),
                    SizedBox(width: 4),
                    Text(
                      formatCurrency(match.price?.basePrice ?? 0),
                      style: TextPalette.getBodyText(Palette.green),
                    ),
                  ])
                else
                  Text("—", style: TextPalette.getBodyText(Palette.greyDark)),
              ]),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: NutmegDivider(horizontal: true),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Text("Total",
                  style: TextPalette.bodyText.copyWith(color: Palette.black)),
              Spacer(),
              Text(formatCurrency(grossCollected),
                  style: TextPalette.getBodyText(Palette.black)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Text(l10n.stripeNutmegFeeLabel,
                  style: TextPalette.bodyText.copyWith(color: Palette.black)),
              Spacer(),
              Text("- ${formatCurrency(nutmegFees)}",
                  style: TextPalette.getBodyText(Palette.black)),
            ]),
          ),
          NutmegDivider(horizontal: true),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Text(l10n.youWillGetLabel,
                  style: TextPalette.bodyText.copyWith(
                      color: Palette.black, fontWeight: FontWeight.w600)),
              Spacer(),
              Text(formatCurrency(netCollected),
                  style: TextPalette.getBodyText(Palette.black)
                      .copyWith(fontWeight: FontWeight.w600)),
            ]),
          ),
          if (releaseRow != null) ...[
            NutmegDivider(horizontal: true),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: releaseRow,
            ),
          ],
        ],
      ),
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOrganizerView) {
      final canTap = _data != null;
      return GestureDetector(
        onTap: canTap ? () => _showPaymentBreakdown(context) : null,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Palette.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(AppLocalizations.of(context)!.payThroughNutmeg.toUpperCase(),
                style: TextPalette.getBodyText(Palette.white)
                    .copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
            SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Palette.white, size: 14),
          ]),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Palette.greyLight, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(AppLocalizations.of(context)!.payThroughNutmeg,
          style: TextPalette.getBodyText(Palette.black)
              .copyWith(fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}
