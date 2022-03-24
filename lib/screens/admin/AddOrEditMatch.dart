import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';

import '../../controller/UserController.dart';
import '../../state/MatchesState.dart';

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
    var m = await MatchesController.refresh(context, matchId);

    // get users details
    Future.wait(
        m.going.keys.map((e) => UserController.getUserDetails(context, e)));

    // get sta±tus
    await MatchesController.refreshMatchStatus(context, m);
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
                    child:
                        Icon(Icons.arrow_back, color: Colors.black, size: 25.0),
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
          child: Column(
            children: [
              Expanded(child: AddOrEditMatchForm(matchId: matchId)),
            ],
          ),
        ),
      ),
    );
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

  Map<String, dynamic> ratings;

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
      var r = await CloudFunctionsClient()
          .callFunction("get_ratings_by_match", {"match_id": matchId});
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
    var status = matchesState.getMatchStatus(matchId);

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
              Text("Status is: " + status.toString().split(".").last,
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
                    await MatchesController.refreshMatchStatus(context, match);
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
                    await MatchesController.refreshMatchStatus(context, match);
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
                      await MatchesController.refreshMatchStatus(
                          context, match);
                    }
                    context.read<GenericButtonWithLoaderState>().change(false);
                  }, Destructive()))
                ],
              ),
              if (status == MatchStatusForUser.rated)
                Row(
                  children: [
                    Expanded(
                        child:
                            GenericButtonWithLoader("PlAYER OF THE MATCH SCREEN",
                                (BuildContext context) async {
                      Get.toNamed("/potm/" + match.manOfTheMatch);
                    }, Primary()))
                  ],
                ),
              SizedBox(height: 16),
              Container(
                child: Column(
                  children: [
                    Text(
                      "Players",
                      style: TextPalette.h2,
                    ),
                    Column(
                        children: match.going.keys
                            .map((u) => Row(children: [
                                  Builder(builder: (context) {
                                    var ud = context
                                        .read<UserState>()
                                        .getUserDetail(u);
                                    if (ud == null) return Container();
                                    return Text(ud.name ?? "Player",
                                        style: TextPalette.h3);
                                  })
                                ]))
                            .toList())
                  ],
                ),
              ),
              SizedBox(height: 16),
              if (ratings != null && ratings.isNotEmpty)
                Container(
                  child: Column(
                    children: [
                      Text(
                        "Ratings Received",
                        style: TextPalette.h2,
                      ),
                      Column(
                          children: ratings.entries
                              .map((e) => Builder(builder: (context) {
                                    var ud = context
                                        .read<UserState>()
                                        .getUserDetail(e.key);
                                    if (ud == null) return Container();
                                    var skips = e.value.where((v) => v == -1);
                                    var votes = e.value.where((v) => v != -1);
                                    double avg = (votes.length > 0)
                                        ? (votes.reduce((a, b) => (a + b)) /
                                            votes.length)
                                        : -1;

                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(ud.name ?? "Player",
                                            style: TextPalette.getH3(
                                                (ud.documentId ==
                                                        matchesState
                                                            .getMatch(matchId)
                                                            .manOfTheMatch)
                                                    ? Palette.accent
                                                    : Palette.black)),
                                        Text(
                                            avg.toStringAsFixed(1) +
                                                "\t\t" +
                                                votes.length.toString() +
                                                " votes\t\t" +
                                                skips.length.toString() +
                                                " skip",
                                            style: TextPalette.h3),
                                      ],
                                    );
                                  }))
                              .toList())
                    ],
                  ),
                )
            ],
          ),
        ));
  }
}
