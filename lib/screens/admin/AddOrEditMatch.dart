import 'package:cool_alert/cool_alert.dart';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutmeg/db/MatchesFirestore.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/AppBar.dart';
import 'package:nutmeg/widgets/Buttons.dart';
import 'package:provider/provider.dart';

import 'SubscriptionsMatchDetails.dart';

// main widget
class AddOrEditMatch extends StatelessWidget {
  final Match match;

  const AddOrEditMatch({Key key, this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAreaAppBarInverted(),
      body: Container(
        color: Palette.light,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            children: [
              Expanded(child: AddOrEditMatchForm(match: match)),
              if (match != null)
                Row(children: [
                  Expanded(
                    child: RoundedButton("CANCEL MATCH", () {
                      CoolAlert.show(
                          context: context,
                          type: CoolAlertType.confirm,
                          text:
                              "This is going to mark the match as CANCELED, send a push notification to all users currently joining and issue a credit refund (IMPLEMENT THIS).");
                    }),
                  )
                ]),
              if (match != null)
                Row(children: [
                  Expanded(
                    child: RoundedButton("VIEW SUBSCRIPTIONS", () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SubscriptionsMatchDetails(
                                  context
                                      .watch<MatchesChangeNotifier>()
                                      .getMatch(match.documentId))));
                      await context.read<MatchesChangeNotifier>().refresh();
                    }),
                  )
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
  Sport sport;
  TextEditingController priceController;
  int maxPlayers;
  DateTime dateTime;

  @override
  void initState() {
    // set initial values
    sportCenterId = (match == null) ? null : match.sportCenter;
    sport = (match == null) ? null : match.sport;
    priceController = new TextEditingController(
        text: (match == null)
            ? null
            : NumberFormat.decimalPattern().format(match.getPrice()));
    maxPlayers = (match == null) ? null : match.maxPlayers;
    dateTime = (match == null) ? null : match.dateTime;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // utility
    var sportCenters =
        context.read<SportCentersChangeNotifier>().getSportCenters().toList();

    return Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              SizedBox(height: 30.0),
              Text("SportCenter", style: TextPalette.linkStyle),
              DropdownButton<SportCenter>(
                focusColor: Colors.white,
                value: context
                    .read<SportCentersChangeNotifier>()
                    .getSportCenter(sportCenterId),
                style: TextStyle(color: Colors.white),
                iconEnabledColor: Colors.black,
                items: sportCenters
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
              SizedBox(height: 30.0),
              Text("Sport", style: TextPalette.linkStyle),
              DropdownButton<Sport>(
                focusColor: Colors.white,
                value: sport,
                //elevation: 5,
                style: TextStyle(color: Colors.white),
                iconEnabledColor: Colors.black,
                items: Sport.values.map<DropdownMenuItem<Sport>>((Sport value) {
                  return DropdownMenuItem<Sport>(
                      value: value,
                      child: Text(value.toString().split(".").last,
                          style: TextPalette.linkStyle));
                }).toList(),
                onChanged: (Sport value) {
                  setState(() {
                    sport = value;
                  });
                },
              ),
              SizedBox(height: 30.0),
              Text("Price per person (in euro)", style: TextPalette.linkStyle),
              TextFormField(
                controller: priceController,
                decoration: InputDecoration(prefixText: "Euro "),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                ],
              ),
              SizedBox(height: 30.0),
              Text("Max players", style: TextPalette.linkStyle),
              DropdownButton<int>(
                focusColor: Colors.white,
                value: maxPlayers,
                style: TextStyle(color: Colors.white),
                iconEnabledColor: Colors.black,
                items: [8, 10, 12, 14].map<DropdownMenuItem<int>>((int value) {
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
                  Expanded(
                    child: RoundedButton((match == null) ? "ADD" : "EDIT",
                        () async {
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
                            assert(dateTime != null, "specify date and time");
                            assert(
                                sportCenterId != null, "specify sport center");
                            assert(sport != null, "specify sport");
                            assert(maxPlayers != null, "specify max players");
                            assert(priceController.value.text != null,
                                "specify price");

                            var newMatchId = await MatchesFirestore.addMatch(
                                new Match(
                                    dateTime,
                                    sportCenterId,
                                    sport,
                                    maxPlayers,
                                    (double.parse(priceController.value.text) *
                                            100)
                                        .toInt(),
                                    MatchStatus.open));
                            CoolAlert.show(
                                context: context,
                                type: CoolAlertType.info,
                                text: "Success! Added match with id " +
                                    newMatchId);
                          }
                        } else {
                          match.dateTime = dateTime;
                          match.sportCenter = sportCenterId;
                          match.sport = sport;
                          match.maxPlayers = maxPlayers;
                          match.pricePerPersonInCents =
                              (double.parse(priceController.value.text) * 100)
                                  .toInt();
                          var shouldUpdate = await CoolAlert.show(
                            context: context,
                            type: CoolAlertType.confirm,
                            text: "This is going to update the match with id: \n" +
                                match.documentId +
                                "\nAre you sure?",
                            onConfirmBtnTap: () => Navigator.pop(context, true),
                            onCancelBtnTap: () => Navigator.pop(context, false),
                          );
                          if (shouldUpdate != null && shouldUpdate) {
                            await MatchesFirestore.editMatch(match);
                            CoolAlert.show(
                                context: context,
                                type: CoolAlertType.info,
                                text: "Success!");
                          }
                        }
                      } catch (e, stackTrace) {
                        print(stackTrace.toString());
                        CoolAlert.show(
                            context: context,
                            type: CoolAlertType.error,
                            text: "Error: " + e.toString());
                      }
                    }),
                  )
                ],
              )
            ],
          ),
        ));
  }
}
