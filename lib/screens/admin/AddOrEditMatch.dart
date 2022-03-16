import 'package:cool_alert/cool_alert.dart';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/Exceptions.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';

import '../../controller/UserController.dart';
import '../../model/Sport.dart';
import '../../model/SportCenter.dart';
import '../../state/LoadOnceState.dart';
import '../../state/MatchesState.dart';

// main widget
class AddOrEditMatch extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AddOrEditMatchState(Get.parameters["matchId"]);
  }
}

class AddOrEditMatchState extends State<AddOrEditMatch> {
  final String matchId;

  AddOrEditMatchState(this.matchId);

  Future<void> refreshState() async {
    if (matchId != null) {
      // get details
      var m = await MatchesController.refresh(context, matchId);

      // get users details
      Future.wait(
          m.going.keys.map((e) => UserController.getUserDetails(context, e)));

      // get status
      await MatchesController.refreshMatchStatus(context, m);
    }
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

  String sportCenterId;
  String sportCenterSubLocation;
  String sport;
  TextEditingController priceController;
  int maxPlayers;
  DateTime dateTime;
  TextEditingController durationController;
  bool testMatch;

  @override
  void initState() {
    var matchesState = context.read<MatchesState>();
    var match = (matchId == null) ? null : matchesState.getMatch(matchId);

    if (match != null) {
      match.going.keys.forEach((u) {
        if (context.read<UserState>().getUserDetail(u) == null) {
          UserController.getUserDetails(context, u);
        }
      });
    }

    // set initial values
    sportCenterId = (match == null) ? null : match.sportCenterId;
    sportCenterSubLocation =
        (match == null) ? null : match.sportCenterSubLocation;
    sport = (match == null) ? null : match.sport;
    priceController = TextEditingController(
        text: (match == null)
            ? null
            : NumberFormat.decimalPattern().format(match.getPrice()));
    maxPlayers = (match == null) ? 10 : match.maxPlayers;
    dateTime = (match == null) ? null : match.dateTime;
    durationController = TextEditingController(
        text: (match == null) ? "60" : match.duration.inMinutes.toString());
    testMatch = (match == null) ? false : match.isTest;
    super.initState();
  }

  Future<void> loadState() async {
    var match = (matchId == null)
        ? null
        : context.read<MatchesState>().getMatch(matchId);
    if (match != null)
      await Future.wait(match
          .getGoingUsersByTime()
          .map((e) => UserController.getUserDetails(context, e)));
  }

  @override
  Widget build(BuildContext context) {
    // utility
    var matchesState = context.watch<MatchesState>();
    var loadOnceState = context.watch<LoadOnceState>();

    var match = matchesState.getMatch(matchId);
    var status = matchesState.getMatchStatus(matchId);

    Set<int> maxPlayersDropdownItemsSet = Set();
    maxPlayersDropdownItemsSet.addAll([8, 10, 12, 14]);
    if (maxPlayers != null) {
      maxPlayersDropdownItemsSet.add(maxPlayers);
    }

    return Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: ListView(
            scrollDirection: Axis.vertical,
            primary: false,
            shrinkWrap: true,
            children: [
              if (matchId != null)
                SelectableText("Match id: " + matchId, style: TextPalette.h2),
              SizedBox(height: 20.0),
              if (matchId != null)
                Text("Status is: " + status.toString().split(".").last,
                    style: TextPalette.h2),
              SizedBox(height: 20.0),
              Text("Date and Time", style: TextPalette.linkStyle),
              DateTimePicker(
                type: DateTimePickerType.dateTimeSeparate,
                dateMask: 'd MMM, yyyy',
                initialDate: dateTime,
                initialValue: (dateTime != null) ? dateTime.toString() : null,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                icon: Icon(Icons.event),
                dateLabelText: 'Date',
                timeLabelText: "Hour",
                onChanged: (val) {
                  dateTime = DateTime.parse(val);
                },
              ),
              SizedBox(height: 20.0),
              Text("SportCenter", style: TextPalette.linkStyle),
              DropdownButton<SportCenter>(
                focusColor: Colors.white,
                value:
                    context.read<LoadOnceState>().getSportCenter(sportCenterId),
                style: TextStyle(color: Colors.white),
                iconEnabledColor: Colors.black,
                items: loadOnceState
                    .getSportCenters()
                    .map<DropdownMenuItem<SportCenter>>((SportCenter value) {
                  return DropdownMenuItem<SportCenter>(
                      value: value,
                      child: Text(
                          value.getName() == null ? "null" : value.getName(),
                          style: TextStyle(color: Colors.black)));
                }).toList(),
                onChanged: (SportCenter value) {
                  setState(() {
                    sportCenterId = value.placeId;
                  });
                },
              ),
              SizedBox(height: 20.0),
              Text("SportCenter location additional info (e.g. hall)",
                  style: TextPalette.linkStyle),
              TextFormField(
                initialValue: sportCenterSubLocation,
                onChanged: (v) => sportCenterSubLocation = v,
              ),
              SizedBox(height: 20.0),
              Text("Sport", style: TextPalette.linkStyle),
              DropdownButton<Sport>(
                focusColor: Colors.white,
                value: loadOnceState.getSport(sport),
                //elevation: 5,
                style: TextStyle(color: Colors.white),
                iconEnabledColor: Colors.black,
                items: loadOnceState
                    .getSports()
                    .map<DropdownMenuItem<Sport>>((Sport value) {
                  return DropdownMenuItem<Sport>(
                      value: value,
                      child: Text(value.displayTitle,
                          style: TextPalette.linkStyle));
                }).toList(),
                onChanged: (Sport value) {
                  setState(() {
                    sport = value.documentId;
                  });
                },
              ),
              SizedBox(height: 20.0),
              Text("Price per person (in euro)", style: TextPalette.linkStyle),
              TextFormField(
                controller: priceController,
                decoration: InputDecoration(prefixText: "Euro "),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                ],
              ),
              SizedBox(height: 20.0),
              Text("Duration (in minutes)", style: TextPalette.linkStyle),
              TextFormField(
                controller: durationController,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'\d+')),
                ],
              ),
              SizedBox(height: 20.0),
              Text("Max players", style: TextPalette.linkStyle),
              DropdownButton<int>(
                focusColor: Colors.white,
                value: maxPlayers,
                style: TextStyle(color: Colors.white),
                iconEnabledColor: Colors.black,
                items: maxPlayersDropdownItemsSet
                    .toList()
                    .map<DropdownMenuItem<int>>((int value) {
                  return DropdownMenuItem<int>(
                      value: value,
                      child:
                          Text(value.toString(), style: TextPalette.linkStyle));
                }).toList(),
                onChanged: (int value) {
                  setState(() {
                    maxPlayers = value;
                  });
                },
              ),
              Row(
                children: [
                  Text("Test Match"),
                  SizedBox(width: 10),
                  Switch(
                    value: testMatch,
                    onChanged: (value) {
                      setState(() {
                        testMatch = value;
                      });
                    },
                    activeTrackColor: Colors.red,
                    activeColor: Colors.red,
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: GenericButtonWithLoader(
                        (match == null) ? "ADD" : "EDIT",
                        (BuildContext context) async {
                      context.read<GenericButtonWithLoaderState>().change(true);
                      try {
                        if (match == null) {
                          var shouldAdd = await CoolAlert.show(
                            context: context,
                            type: CoolAlertType.confirm,
                            text:
                                "This is going to add a new match. Are you sure?",
                            onConfirmBtnTap: () => Get.back(result: true),
                            onCancelBtnTap: () => Get.back(result: false),
                          );
                          if (shouldAdd) {
                            var newMatchId = await MatchesController.addMatch(
                                Match(
                                    dateTime,
                                    sportCenterId,
                                    sportCenterSubLocation,
                                    sport,
                                    maxPlayers,
                                    (double.parse(priceController.value.text) *
                                            100)
                                        .toInt(),
                                    Duration(
                                        minutes: int.parse(
                                            durationController.value.text)),
                                    testMatch));
                            await MatchesController.refresh(
                                context, newMatchId);
                            await GenericInfoModal(
                                    title: "Success",
                                    description:
                                        "Added match with id:\n" + newMatchId)
                                .show(context);
                          }
                        } else {
                          match.dateTime = dateTime;
                          match.sportCenterId = sportCenterId;
                          match.sportCenterSubLocation = sportCenterSubLocation;
                          match.sport = sport;
                          match.maxPlayers = maxPlayers;
                          match.pricePerPersonInCents =
                              (double.parse(priceController.value.text) * 100)
                                  .toInt();

                          var shouldUpdate = await CoolAlert.show(
                            context: context,
                            type: CoolAlertType.confirm,
                            text:
                                "This is going to update the match with id: \n" +
                                    match.documentId +
                                    "\nAre you sure?",
                            onConfirmBtnTap: () => Get.back(result: true),
                            onCancelBtnTap: () => Get.back(result: false),
                          );
                          if (!shouldUpdate) {
                            return;
                          }

                          await MatchesController.editMatch(match);
                          await GenericInfoModal(
                                  title: "Success!",
                                  description: "Match with id " +
                                      match.documentId +
                                      " successfully modified")
                              .show(context);
                          Get.back();
                        }
                      } catch (e, stackTrace) {
                        ErrorHandlingUtils.handleError(e, stackTrace, context);
                      }
                      context
                          .read<GenericButtonWithLoaderState>()
                          .change(false);
                    }, Primary()),
                  )
                ],
              ),
              if (matchId != null)
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
                      await MatchesController.refreshMatchStatus(
                          context, match);
                      context
                          .read<GenericButtonWithLoaderState>()
                          .change(false);
                    }, Primary()))
                  ],
                ),
              if (matchId != null)
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
                      await MatchesController.refreshMatchStatus(
                          context, match);
                      context
                          .read<GenericButtonWithLoaderState>()
                          .change(false);
                    }, Primary()))
                  ],
                ),
              if (matchId != null)
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
                      context
                          .read<GenericButtonWithLoaderState>()
                          .change(false);
                    }, Destructive()))
                  ],
                ),
              SizedBox(height: 16),
              if (matchId != null)
                Container(
                  child: Column(
                    children: [
                      Text(
                        "Users",
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
                )
            ],
          ),
        ));
  }
}
