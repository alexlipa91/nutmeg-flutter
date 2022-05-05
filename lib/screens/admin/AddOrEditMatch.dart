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
import '../../state/MatchesState.dart';
import '../MatchDetails.dart';

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
                        GenericInfoModal(
                                title:
                                    "Successfully canceled match")
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
                              Expanded(
                                  child: GenericButtonWithLoader(
                                      "POTM SCREEN: " +
                                              context
                                                  .read<UserState>()
                                                  .getUserDetail(e)
                                                  .name ??
                                          "PLAYER".toUpperCase(),
                                      (BuildContext context) async {
                                Get.toNamed("/potm/" + e);
                              }, Primary()))
                            ]))
                        .toList()),
              PlayerList(match: match),
              Stats(
                matchId: matchId,
                matchDatetime: match.dateTime,
                extended: true,
              )
            ],
          ),
        ));
  }
}
