import 'package:cool_alert/cool_alert.dart';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutmeg/Exceptions.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/AppBar.dart';
import 'package:nutmeg/widgets/Buttons.dart';
import 'package:provider/provider.dart';


// main widget
class AddOrEditMatch extends StatelessWidget {
  final String matchId;

  AddOrEditMatch.update(this.matchId);

  AddOrEditMatch.add() : this.matchId = null;

  @override
  Widget build(BuildContext context) {
    var matchesState = context.read<MatchesState>();
    var match = matchesState.getMatch(matchId);

    return Scaffold(
      appBar: AdminAreaAppBarInverted(),
      body: Container(
        color: Palette.light,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            children: [
              Expanded(child: AddOrEditMatchForm(match: match)),
              if (match != null && match.cancelledAt == null)
                Row(children: [
                  // Expanded(
                    // child: ButtonWithLoader("CANCEL", () async {
                    //   var shouldCancel = await CoolAlert.show(
                    //     context: context,
                    //     type: CoolAlertType.confirm,
                    //     text: "This is going to cancel the match with id: \n" +
                    //         match.documentId +
                    //         "\nA push notification will be sent to all the going users and a refund should be issued (implmenet this)"
                    //             "\nAre you sure?",
                    //     onConfirmBtnTap: () => Navigator.pop(context, true),
                    //     onCancelBtnTap: () => Navigator.pop(context, false),
                    //   );
                    //
                    //   if (shouldCancel) {
                    //     try {
                    //       await MatchesController.cancelMatch(matchesState, matchId);
                    //       HttpsCallable callable = FirebaseFunctions.instance
                    //           .httpsCallable('sendCancellationNotification');
                    //       await callable.call({"matchId": matchId});
                    //     } catch (e, s) {
                    //       print("exception occurred");
                    //       print(e);
                    //       print(s);
                    //     }
                    //     Navigator.pop(context);
                    //   }
                    // }),
                  // )
                ])
            ],
          ),
        ),
      ),
    );
  }
}

class AddOrEditMatchForm extends StatefulWidget {
  final Match match;

  const AddOrEditMatchForm({Key key, this.match}) : super(key: key);

  @override
  State<StatefulWidget> createState() => AddOrEditMatchFormState(match);
}

class AddOrEditMatchFormState extends State<AddOrEditMatchForm> {
  final Match match;

  AddOrEditMatchFormState(this.match);

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
    // set initial values
    sportCenterId = (match == null) ? null : match.sportCenterId;
    sportCenterSubLocation = (match == null) ? null : match.sportCenterSubLocation;
    sport = (match == null) ? null : match.sport;
    priceController = TextEditingController(
        text: (match == null)
            ? null
            : NumberFormat.decimalPattern().format(match.getPrice()));
    maxPlayers = (match == null) ? 10 : match.maxPlayers;
    dateTime = (match == null) ? null : match.dateTime;
    durationController = TextEditingController(
        text: (match == null) ? "60" : match.duration.inMinutes.toString());
    testMatch = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // utility
    var matchesState = context.read<MatchesState>();
    var loadOnceState = context.read<LoadOnceState>();

    Set<int> maxPlayersDropdownItemsSet = Set();
    maxPlayersDropdownItemsSet.addAll([8, 10, 12, 14]);
    if (maxPlayers != null) {
      maxPlayersDropdownItemsSet.add(maxPlayers);
    }

    return Scaffold(
        backgroundColor: Colors.transparent,
        body: ListView(
          // mainAxisAlignment: MainAxisAlignment.center,
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              value: context
                  .read<LoadOnceState>()
                  .getSportCenter(sportCenterId),
              style: TextStyle(color: Colors.white),
              iconEnabledColor: Colors.black,
              items: loadOnceState.getSportCenters()
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
            Text("SportCenter location additional info (e.g. hall)", style: TextPalette.linkStyle),
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
              items: loadOnceState.getSports().map<DropdownMenuItem<Sport>>((Sport value) {
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
                  child:
                      RoundedButton((match == null) ? "ADD" : "EDIT", () async {
                    try {
                      if (match == null) {
                        var shouldAdd = await CoolAlert.show(
                          context: context,
                          type: CoolAlertType.confirm,
                          text:
                              "This is going to add a new match. Are you sure?",
                          onConfirmBtnTap: () => Navigator.pop(context, true),
                          onCancelBtnTap: () => Navigator.pop(context, false),
                        );
                        if (shouldAdd) {
                            var newMatchId = await MatchesController.addMatch(
                                Match(
                                  dateTime,
                                  sportCenterId,
                                  sportCenterSubLocation,
                                  sport,
                                  maxPlayers,
                                  (double.parse(priceController.value.text) * 100).toInt(),
                                  Duration(minutes: int.parse(durationController.value.text)),
                                  testMatch
                                )
                              );
                            await MatchesController.refresh(matchesState, newMatchId);
                            await GenericInfoModal(title: "Success",
                            body: "Added match with id:\n" + newMatchId).show(context);
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
                          onConfirmBtnTap: () => Navigator.pop(context, true),
                          onCancelBtnTap: () => Navigator.pop(context, false),
                        );
                        if (!shouldUpdate) {
                          return;
                        }

                        await MatchesController.editMatch(matchesState, match);
                        await GenericInfoModal(title: "Success!",
                            body: "Match with id " + match.documentId + " successfully modified").show(context);
                        Navigator.pop(context);
                      }
                    } catch (e, stackTrace) {
                      ErrorHandlingUtils.handleError(e, stackTrace, context);
                    }
                  }),
                )
              ],
            )
          ],
        )
      );
  }
}
