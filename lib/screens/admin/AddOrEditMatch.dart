import 'dart:math';

import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/model/MatchRatings.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';

import '../../controller/UserController.dart';
import '../../model/Match.dart';
import '../../model/UserDetails.dart';
import '../../state/MatchesState.dart';
import '../../widgets/Avatar.dart';
import '../../widgets/Containers.dart';
import '../../widgets/ModalBottomSheet.dart';
import '../../widgets/PlayerBottomModal.dart';
import '../../widgets/Section.dart';
import '../../widgets/Skeletons.dart';

// main widget
class AdminMatchDetails extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AdminMatchDetailsState(Get.parameters["matchId"]);
  }
}

class AdminMatchDetailsState extends State<AdminMatchDetails> {
  final String matchId;

  AdminMatchDetailsState(this.matchId);

  Future<void> refreshState() async {
    // get details
    var futures = [
      MatchesController.refresh(context, matchId),
      context.read<MatchesState>().fetchRatings(matchId)
    ];

    var result = await Future.wait(futures);

    var m = result[0] as Match;

    // get users details
    Future.wait(
        m.going.keys.map((e) => UserController.getUserDetails(context, e)));
  }

  @override
  void initState() {
    super.initState();
    refreshState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          backgroundColor: Colors.transparent,
          centerTitle: false,
          automaticallyImplyLeading: false,
          leadingWidth: 0,
          elevation: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // SizedBox(width: 16,), // we cannot pad outside
              InkWell(
                  splashColor: Palette.grey_lighter,
                  child: Container(
                    width: 50,
                    height: 50,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(Icons.arrow_back,
                          color: Colors.black, size: 25.0),
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop())
            ],
          ),
        ),
        body: Container(
          color: Palette.grey_lightest,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Column(children: [
              Expanded(
                child: AddOrEditMatchForm(matchId: matchId),
              )
            ]),
          ),
        ));
  }
}

class AddOrEditMatchForm extends StatefulWidget {
  final String matchId;

  const AddOrEditMatchForm({Key key, this.matchId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => AddOrEditMatchFormState(matchId);
}

class AddOrEditMatchFormState extends State<AddOrEditMatchForm> {
  final String matchId;

  AddOrEditMatchFormState(this.matchId);

  MatchRatings ratings;

  @override
  void initState() {
    super.initState();
    loadState();
  }

  Future<void> loadState() async {
    var match = context.read<MatchesState>().getMatch(matchId);
    await Future.wait(match
        .getGoingUsersByTime()
        .map((e) => UserController.getUserDetails(context, e)));

    if (match.dateTime.isBefore(DateTime.now())) {
      var r = await context.read<MatchesState>().fetchRatings(matchId);
      setState(() {
        ratings = r;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // utility
    var matchesState = context.watch<MatchesState>();

    var match = matchesState.getMatch(matchId);

    return Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: ListView(
            scrollDirection: Axis.vertical,
            primary: false,
            shrinkWrap: true,
            children: [
              SelectableText("Match id: " + matchId, style: TextPalette.h2),
              SizedBox(height: 16.0),
              Text("Status is: " + match.status.toString().split(".").last,
                  style: TextPalette.h2),
              SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                      child: GenericButtonWithLoader("RESET RATINGS",
                          (BuildContext context) async {
                    context.read<GenericButtonWithLoaderState>().change(true);
                    try {
                      await MatchesController.resetRatings(match.documentId);
                      GenericInfoModal(
                              title:
                                  "Successfully deleted all ratings for the match")
                          .show(context);
                    } catch (e, stack) {
                      print(e);
                      print(stack);
                      GenericInfoModal(title: "Something went wrong")
                          .show(context);
                    }
                    context.read<GenericButtonWithLoaderState>().change(false);
                  }, Primary()))
                ],
              ),
              Row(
                children: [
                  Expanded(
                      child: GenericButtonWithLoader("CLOSE RATING ROUND",
                          (BuildContext context) async {
                    context.read<GenericButtonWithLoaderState>().change(true);
                    try {
                      await MatchesController.closeRatingRound(
                          match.documentId);
                      GenericInfoModal(
                              title:
                                  "Successfully closed rating round for the match")
                          .show(context);
                    } catch (e, stack) {
                      print(e);
                      print(stack);
                      GenericInfoModal(title: "Something went wrong")
                          .show(context);
                    }
                    context.read<GenericButtonWithLoaderState>().change(false);
                  }, Primary()))
                ],
              ),
              Row(
                children: [
                  Expanded(
                      child: GenericButtonWithLoader("CANCEL MATCH",
                          (BuildContext context) async {
                    context.read<GenericButtonWithLoaderState>().change(true);
                    var shouldCancel = await CoolAlert.show(
                      context: context,
                      type: CoolAlertType.confirm,
                      text: "This is going to cancel the match with id: \n" +
                          match.documentId +
                          "\nAre you sure?",
                      onConfirmBtnTap: () => Get.back(result: true),
                      onCancelBtnTap: () => Get.back(result: false),
                    );

                    if (shouldCancel) {
                      try {
                        await MatchesController.cancelMatch(match.documentId);
                        GenericInfoModal(title: "Successfully canceled match")
                            .show(context);
                      } catch (e, stack) {
                        print(e);
                        print(stack);
                        GenericInfoModal(title: "Something went wrong")
                            .show(context);
                      }
                    }
                    context.read<GenericButtonWithLoaderState>().change(false);
                  }, Destructive()))
                ],
              ),
              if (match.status == MatchStatus.rated)
                Column(
                    children: match
                        .getPotms()
                        .map((e) => Row(children: [
                              Builder(builder: (BuildContext context) {
                                var ud =
                                    context.watch<UserState>().getUserDetail(e);
                                if (ud == null) return Container();

                                return Expanded(
                                    child: GenericButtonWithLoader(
                                        "POTM SCREEN: " + ud.name ??
                                            "PLAYER".toUpperCase(),
                                        (BuildContext context) async {
                                  Get.toNamed("/potm/" + e);
                                }, Primary()));
                              })
                            ]))
                        .toList()),
              VoteStats(matchId: matchId, matchDatetime: match.dateTime)
            ],
          ),
        ));
  }
}

class VoteStats extends StatefulWidget {
  final String matchId;
  final DateTime matchDatetime;

  const VoteStats({Key key, this.matchId, this.matchDatetime})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => VoteStatsState();
}

class VoteStatsState extends State<VoteStats> {
  String selected = "SCORE";

  @override
  Widget build(BuildContext context) {
    var child;

    // in extended mode, we show also partial results
    var ratings = context.watch<MatchesState>().getRatings(widget.matchId);
    var userState = context.watch<UserState>();

    var loadSkeleton = (ratings == null || userState == null);
    child = (loadSkeleton)
        ? StatsSkeleton()
        : Builder(
            builder: (context) {
              var match =
                  context.watch<MatchesState>().getMatch(widget.matchId);
              List<RatingEntry> finalRatings = ratings
                  .getFinalRatings(match.getGoingUsersByTime(), match.getPotms());

              List<VotesEntry> votesEntry =
                ratings.getVotesEntry(match.getGoingUsersByTime(), match.getPotms(), selected);

              return Container(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (selected == "SCORE") ?
                  ratingsWidgets(context, finalRatings) :
                  votesWidgets(context, votesEntry)
              ));
            },
          );

    return Container(
      child: Section(
        title: "PLAYERS STATS",
        body: Column(children: [
          SingleChildScrollView(
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                GenericButtonWithLoader("SCORE", (_) {
                  setState(() {
                    selected = "SCORE";
                  });
                }, (selected == "SCORE") ? Primary() : Secondary()),
                SizedBox(width: 4),
                GenericButtonWithLoader("RECEIVED", (_) {
                  setState(() {
                    selected = "RECEIVED";
                  });
                }, (selected == "RECEIVED") ? Primary() : Secondary()),
                SizedBox(width: 4),
                GenericButtonWithLoader("GIVEN", (_) {
                  setState(() {
                    selected = "GIVEN";
                  });
                }, (selected == "GIVEN") ? Primary() : Secondary()),
              ])),
          SizedBox(height: 16),
          InfoContainer(child: child)
        ]),
      ),
    );
  }

  List<Widget> ratingsWidgets(BuildContext context, List<RatingEntry> finalRatings) {
    var userState = context.watch<UserState>();
    int index = 1;

    return finalRatings.map((r) {
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
                Builder(builder: (context) {
                  // fixme text overflow
                  if (userDetails == null) return Skeletons.mText;

                  var name =
                      UserDetails.getDisplayName(userDetails)
                          .split(" ")
                          .first;
                  var n = name.substring(0, min(name.length, 11));
                  return Text(n,
                      overflow: TextOverflow.ellipsis,
                      style:
                      TextPalette.getBodyText(Palette.black));
                }),
                SizedBox(width: 8),
                if (userDetails != null && r.isPotm && r.vote > 0)
                  Image.asset(
                    "assets/potm_badge.png",
                    width: 20,
                  )
              ],
            ),
          ),
          Spacer(),
          if (selected == "SCORE")
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
                onTap: () =>
                    ModalBottomSheet.showNutmegModalBottomSheet(
                        context,
                        JoinedPlayerBottomModal(userDetails)),
                child: Row(children: widgets)));
      }).toList();
  }

  List<Widget> votesWidgets(BuildContext context, List<VotesEntry> votesEntries) {
    var userState = context.watch<UserState>();
    int index = 1;

    return votesEntries.map((r) {
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
                Builder(builder: (context) {
                  // fixme text overflow
                  if (userDetails == null) return Skeletons.mText;

                  var name =
                      UserDetails.getDisplayName(userDetails)
                          .split(" ")
                          .first;
                  var n = name.substring(0, min(name.length, 11));
                  return Text(n,
                      overflow: TextOverflow.ellipsis,
                      style:
                      TextPalette.getBodyText(Palette.black));
                }),
                SizedBox(width: 8),
                if (userDetails != null && r.isPotm)
                  Image.asset(
                    "assets/potm_badge.png",
                    width: 20,
                  )
              ],
            ),
          ),
          Spacer(),
          Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.star, color: Palette.accent),
                  SizedBox(width: 4),
                  Container(
                      width: 16,
                      child: Text(
                          r.numberOfVotes
                              .toString(),
                          style: TextPalette.bodyText)),
                  SizedBox(width: 16),
                  Icon(Icons.skip_next, color: Palette.grey_dark),
                  SizedBox(width: 4),
                  Container(
                      width: 16,
                      child: Text(
                          r.numberOfSkips.toString(),
                          style: TextPalette.bodyText)),
                ],
              ),
            ),
          SizedBox(width: 16),
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
      }).toList();
  }
}
