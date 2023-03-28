import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nutmeg/controller/SportCentersController.dart';
import 'package:nutmeg/state/LoadOnceState.dart';
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

import '../state/MatchesState.dart';
import '../state/UserState.dart';
import '../utils/InfoModals.dart';
import '../widgets/Buttons.dart' as buttons;
import '../widgets/ButtonsWithLoader.dart';
import '../widgets/ModalBottomSheet.dart';
import '../widgets/PlayerBottomModal.dart';
import '../widgets/Skeletons.dart';
import '../widgets/Texts.dart';
import 'BottomBarMatch.dart';
import 'CreateMatch.dart';
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
  static var dayDateFormat = DateFormat("EEEE, MMM dd");

  Future<void> myInitState() async {
    print("init state");
    await refreshState();

    Match match = context.read<MatchesState>().getMatch(widget.matchId)!;

    print(widget.paymentOutcome);
    // check if payment outcome
    if (widget.paymentOutcome != null) {
      if (ModalBottomSheet.isOpen) Navigator.of(context).pop();
      if (widget.paymentOutcome! == "success") {
        PaymentDetailsDescription.communicateSuccessToUser(context, match);
      } else
        GenericInfoModal(
                title: "Payment Failed!", description: "Please try again")
            .show(context);
    }

    // show rating modal
    var loggedUser = context.read<UserState>().getLoggedUserDetails();

    if (match.status == MatchStatus.to_rate && match.isUserGoing(loggedUser)) {
      var stillToVote =
          context.read<MatchesState>().stillToVote(widget.matchId, loggedUser!);

      if (stillToVote != null && stillToVote.isNotEmpty) {
        await RatePlayerBottomModal.rateAction(context, widget.matchId);
        setState(() {});
      }
    }

    // show enter score modal
    if (match.hasTeams() &&
        match.score == null &&
        match.organizerId != null &&
        match.organizerId! == loggedUser?.documentId) {
      ScoreMatchBottomModal.scoreAction(context, widget.matchId);
    }

    if (loggedUser != null &&
        match.getPotms().contains(loggedUser.documentId)) {
      UserController.showPotmIfNotSeen(
          context, widget.matchId, loggedUser.documentId);
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
    SportCenter? sportCenter =
        SportCentersController.getSportCenter(context, match);

    var status = match?.status;

    var isTest = match != null && match.isTest;
    var organizerView = userState.isLoggedIn() &&
        match != null &&
        match.organizerId == userState.getLoggedUserDetails()!.documentId;

    var bottomBar =
        BottomBarMatch.getBottomBar(context, widget.matchId, status);

    // add padding individually since because of shadow clipping some components need margin
    if (match == null || sportCenter == null) {
      var widgets = [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: SkeletonMatchDetails.imageSkeleton())
          ]),
          SkeletonMatchDetails.skeletonRepeatedElement(),
          SkeletonMatchDetails.skeletonRepeatedElement(),
          SkeletonMatchDetails.skeletonRepeatedElement(),
          SkeletonMatchDetails.skeletonRepeatedElement(),
          SkeletonMatchDetails.skeletonRepeatedElement(),
        ])
      ];

      return PageTemplate(
        initState: () => myInitState(),
        refreshState: () => refreshState(),
        widgets: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                    width: 900,
                    child: Column(
                        children:
                            interleave(widgets, SizedBox(height: 16)).toList())),
              )
            ],
          )
        ],
        appBar: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BackButton(color: Palette.black),
            if (!DeviceInfo().name.contains("ipad") && !kIsWeb)
              Align(
                  alignment: Alignment.centerRight,
                  child: buttons.ShareButton(() async {
                    await DynamicLinks.shareMatchFunction(match!, sportCenter!);
                  }, Palette.black, 25.0)),
          ],
        ),
        bottomNavigationBar: bottomBar,
      );
    }

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

    var matchInfo = MatchInfo(match, sportCenter);

    var infoPlayersList = match.hasTeams()
        ? TeamsWidget(matchId: widget.matchId)
        : PlayerList(
            match: match,
            withJoinButton: bottomBar is JoinMatchBottomBar && !match.isFull());

    var stats = status == MatchStatus.rated || status == MatchStatus.to_rate
        ? Stats(match: match, sportCenter: sportCenter)
        : null;

    var sportCenterDetails =
        SportCenterDetails(match: match, sportCenter: sportCenter);

    var rules = (bool large) => Builder(builder: (context) {
          var cancellationText = "";

          if (match.cancelBefore != null) {
            var cancellationDate = match.dateTime.subtract(match.cancelBefore!);

            if (cancellationDate.isAfter(DateTime.now())) {
              cancellationText = AppLocalizations.of(context)!.cancellationInfo(
                  dayDateFormat
                      .format(match.getLocalizedTime(sportCenter.timezoneId)),
                  match.minPlayers);
            }
          }
          var refundString = (match.userFee == 0)
              ? AppLocalizations.of(context)!.fullRefund
              : AppLocalizations.of(context)!.refundWithoutFee;

          return RuleCard(
              AppLocalizations.of(context)!.paymentPolicyHeader,
              AppLocalizations.of(context)!.refundInfo(refundString) +
                  cancellationText,
              large);
        });

    var organiserBadge = match.organizerId != null
        ? Builder(builder: (context) {
            var ud =
                context.watch<UserState>().getUserDetail(match.organizerId!);

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

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 800) {
        return PageTemplate(
          refreshState: () => refreshState(),
          widgets: interleave([
            // title
            if (completeOrganiserWidget != null) completeOrganiserWidget,
            if (testInfo != null) testInfo,
            // info box
            matchInfo,
            // stats
            infoPlayersList,
            if (stats != null) stats,
            // horizontal players list or teams
            sportCenterDetails,
            rules(false),
            if (organiserBadge != null) organiserBadge
          ], SizedBox(height: 16)),
          appBar: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BackButton(color: Palette.black),
              if (!DeviceInfo().name.contains("ipad") && !kIsWeb)
                Align(
                    alignment: Alignment.centerRight,
                    child: buttons.ShareButton(() async {
                      await DynamicLinks.shareMatchFunction(match, sportCenter);
                    }, Palette.black, 25.0)),
            ],
          ),
          bottomNavigationBar: bottomBar,
        );
      }
      return PageTemplate(
        refreshState: () => refreshState(),
        widgets: [
          if (testInfo != null) testInfo,
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
                            infoPlayersList,
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
                      rules(true),
                      if (organiserBadge != null) organiserBadge
                    ], SizedBox(height: 16)),
                  ),
                ),
              )
            ],
          )
        ],
        appBar: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BackButton(color: Palette.black),
            if (!DeviceInfo().name.contains("ipad") && !kIsWeb)
              Align(
                  alignment: Alignment.centerRight,
                  child: buttons.ShareButton(() async {
                    await DynamicLinks.shareMatchFunction(match, sportCenter);
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

class TeamsWidget extends StatelessWidget {
  final String matchId;
  final String? title;
  final bool withScoreInput;

  TeamsWidget(
      {Key? key,
      required this.matchId,
      String? title,
      this.withScoreInput = false})
      : title = title,
        super(key: key);

  final _formKey = GlobalKey<FormState>();

  Widget inputScore(TextEditingController controller) => Container(
      width: 50,
      child: Center(
        child: TextFormField(
          keyboardType: TextInputType.number,
          controller: controller,
          validator: (v) {
            if (int.tryParse(v ?? "") == null)
              return "Invalid";
            return null;
          },
          decoration:
          CreateMatchState.getTextFormDecoration(
              null),
        ),
      ));

  @override
  Widget build(BuildContext context) {
    var match = context.watch<MatchesState>().getMatch(matchId);

    var teamA = match!.teams.entries.first;
    var teamB = match.teams.entries.last;

    var teamAController;
    var teamBController;
    if (withScoreInput) {
      teamAController = TextEditingController();
      teamBController = TextEditingController();
    }

    var content = Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Center(
          child: IntrinsicHeight(
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                        flex: 3,
                        child: Text(
                          "Team A",
                          style: TextPalette.h2,
                        )),
                    if (withScoreInput)
                      Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              inputScore(teamAController),
                              Spacer(),
                              inputScore(teamBController)
                            ],
                          )),
                    if (match.score != null)
                      Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text(match.score![0].toString(),
                                      textAlign: TextAlign.end,
                                      style:
                                      TextPalette.getStats(Palette.black))),
                              Text("  vs  ", style: TextPalette.bodyText),
                              Expanded(
                                  child: Text(match.score![1].toString(),
                                      style: TextPalette.getStats(Palette.black)))
                            ],
                          )),
                    Flexible(
                        flex: 3,
                        child: Text(
                          "Team B",
                          style: TextPalette.h2,
                        ))
                  ],
                ),
                SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                          flex: 3,
                          child: getTeamColumn(context, MainAxisAlignment.start,
                              teamA.value)),
                      Flexible(
                          flex: 2,
                          child: VerticalDivider(
                              thickness: 1, color: Palette.grey_light)),
                      Flexible(
                          flex: 3,
                          child: getTeamColumn(context, MainAxisAlignment.end,
                              teamB.value)),
                    ],
                  ),
                ),
                if (withScoreInput)
                  Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("ABCD",
                            style: TextPalette.getLinkStyle(Palette.white)),
                        GenericButtonWithLoader(
                            AppLocalizations.of(context)!.submitScoreButton,
                                (BuildContext context) {
                              if (_formKey.currentState!.validate()) {
                                Navigator.of(context).pop(
                                    [teamAController.text, teamBController.text]);
                              }
                            }, Primary()),
                        TappableLinkText(
                            text: AppLocalizations.of(context)!.skipText,
                            onTap: (BuildContext context) async {
                              Navigator.of(context).pop("skipped");
                            }),
                      ],
                    ),
                  )
              ],
            ),
          )

        // Column(children: [
        //   Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: [
        //     Text("Team A",
        //         style: TextPalette.h3),
        //     Text("Team B",
        //         style: TextPalette.h3)
        //   ],),
        //   IntrinsicHeight(
        //     child: Row(children: [
        //       getTeamColumn(context, teamA.key, teamA.value, teamAController),
        //       VerticalDivider(
        //         thickness: 1,
        //         color: Palette.grey_light,
        //       ),
        //       getTeamColumn(context, teamB.key, teamB.value, teamBController,
        //         withScoreOutput),
        //     ]),
        //   ),
        //   if (withScoreInput)
        //     Padding(
        //       padding: EdgeInsets.only(top: 32),
        //       child: Row(
        //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //         children: [
        //           Text("ABCD", style: TextPalette.getLinkStyle(Palette.white)),
        //           GenericButtonWithLoader(
        //             AppLocalizations.of(context)!.submitScoreButton,
        //                 (BuildContext context) {
        //           if (_formKey.currentState!.validate()) {
        //             Navigator.of(context).pop([
        //               teamAController.text,
        //               teamBController.text
        //             ]);
        //           }
        //         }, Primary()),
        //           TappableLinkText(
        //               text: AppLocalizations.of(context)!.skipText,
        //               onTap: (BuildContext context) async {
        //                 Navigator.of(context).pop("skipped");
        //               }),
        //         ],
        //       ),
        //     )
        // ]),
      ),
    );

    return Form(
      key: _formKey,
      child: this.title == null ? InfoContainer(child: content)
          : InfoContainerWithTitle(title: this.title!, body: content)
    );
  }

  getTeamColumn(BuildContext context, MainAxisAlignment alignment,
      List<String> players) {
    var playersWidgets = interleave(
        players.map((e) {
          var ud = context.watch<UserState>().getUserDetail(e);

          var avatar = UserAvatar(16, ud);
          var name = UserNameWidget(userDetails: ud);

          return InkWell(
              onTap: ud == null
                  ? null
                  : () => ModalBottomSheet.showNutmegModalBottomSheet(
                      context, JoinedPlayerBottomModal(ud)),
              child: SizedBox(
                height: 32,
                child: Row(mainAxisAlignment: alignment, children: [
                  alignment == MainAxisAlignment.start ? avatar : name,
                  SizedBox(width: 16),
                  alignment == MainAxisAlignment.start ? name : avatar,
                ]),
              ));
        }).toList(),
        SizedBox(height: 16));

    List<Widget> childrenWidgets = [];
    childrenWidgets.addAll(playersWidgets);

    return Column(
      children: childrenWidgets,
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

  @override
  Widget build(BuildContext context) {
    var dayDateFormat = DateFormat(
        "EEEE, MMM dd", context.watch<LoadOnceState>().locale.languageCode);
    var hourDateFormat =
        DateFormat("HH:mm", context.watch<LoadOnceState>().locale.languageCode);

    var child;

    var matchWidget = getStatusWidget(context, match);
    var loggedUser = context.watch<UserState>().getLoggedUserDetails();

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
            if (match.organizerId != null &&
                loggedUser != null &&
                match.organizerId == loggedUser.documentId)
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Row(children: [
                  Expanded(
                      child: GenericButtonWithLoader("MANAGE", (_) {
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
                                        match, sportCenter);
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                      AppLocalizations.of(context)!.shareAction,
                                      style: TextPalette.listItem)),
                            ),
                            if (match.dateTime.isAfter(DateTime.now()))
                              Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: InkWell(
                                  onTap: () async {
                                    await GenericInfoModal(
                                        title:
                                            "Are you sure you want to cancel the match?",
                                        description:
                                            "The players that joined will get a full refund.",
                                        action: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child:
                                                  GenericButtonWithLoaderAndErrorHandling(
                                                      "CONFIRM", (_) async {
                                                await MatchesController
                                                    .cancelMatch(
                                                        match.documentId);
                                                await MatchesController.refresh(
                                                    context, match.documentId);
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
              Icons.calendar_month_outlined: dayDateFormat
                  .format(match.getLocalizedTime(sportCenter.timezoneId)),
              Icons.access_time_outlined:
                  "${hourDateFormat.format(match.getLocalizedTime(sportCenter.timezoneId))} - "
                          "${hourDateFormat.format(match.getLocalizedTime(sportCenter.timezoneId).add(match.duration))}" +
                      " (" +
                      gmtSuffix(sportCenter.timezoneId) +
                      ")",
              if (match.managePayments)
                Icons.local_offer_outlined:
                    formatCurrency(match.pricePerPersonInCents)
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

  Row? getStatusWidget(BuildContext context, Match? match) {
    var color;
    var icon;
    var text;

    if (match == null) return null;

    if (match.status == MatchStatus.playing) {
      icon = Icons.history_toggle_off_outlined;
      color = Palette.grey_dark;
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

// single line with icon and texts in the info card
class InfoWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final String subTitle;

  final Widget? rightWidget;

  InfoWidget({required this.title, required this.icon, required this.subTitle})
      : rightWidget = null;

  InfoWidget.withRightWidget(
      {required this.title,
      required this.icon,
      required this.subTitle,
      required Widget rightWidget})
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
            Text(title, style: TextPalette.h2),
            SizedBox(
              height: 4,
            ),
            Padding(
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
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
        "EEEE, MMM dd", context.watch<LoadOnceState>().locale.languageCode);

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
                AppLocalizations.of(context)!.statsWaiting,
                style: TextPalette.h2,
              ),
              SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.statsAvailableAt(
                    dayDateFormat.format(
                            match.getLocalizedTime(sportCenter.timezoneId)) +
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
