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
import 'package:nutmeg/screens/BottomBarMatch.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:provider/provider.dart';
import 'package:time_picker_widget/time_picker_widget.dart';

import '../../controller/UserController.dart';
import '../../model/Sport.dart';
import '../../model/SportCenter.dart';
import '../../state/LoadOnceState.dart';
import '../../state/MatchesState.dart';
import '../widgets/ModalBottomSheet.dart';

// main widget
class CreateMatch extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => CreateMatchState();
}

class CreateMatchState extends State<CreateMatch> {
  DateTime date;
  TimeOfDay startTimeOfDay;
  TimeOfDay endTimeOfDay;
  String sportCenterId;
  String sportId;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController dateEditingController =
      TextEditingController(text: "");
  final TextEditingController startTimeEditingController =
      TextEditingController(text: "");
  final TextEditingController endTimeEditingController =
      TextEditingController(text: "");
  final TextEditingController sportCenterEditingController =
      TextEditingController(text: "");
  final TextEditingController sportEditingController =
      TextEditingController(text: "");
  final TextEditingController priceController = TextEditingController();
  RangeValues numberOfPeopleRangeValues = RangeValues(8, 10);
  bool isTest = false;

  final dateFormat = DateFormat("yyyy-MM-dd");
  final regexPrice = new RegExp("\\d+(\\.\\d{1,2})?");

  Future<void> refreshState() async {}

  @override
  void initState() {
    super.initState();

    // set default sport
    sportId = context.read<LoadOnceState>().getSports().first.documentId;
    sportEditingController.text =
        context.read<LoadOnceState>().getSports().first.displayTitle;

    refreshState();
  }

  @override
  Widget build(BuildContext context) {
    var appBar = SliverAppBar(
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: 0,
      title: Container(
        color: Colors.green,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BackButton(color: Palette.black),
          ],
        ),
      ),
    );

    var widgets = [
      Text("New Match", style: TextPalette.h1Default),
      Section(
        title: "GENERAL",
        body: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: TextFormField(
                  readOnly: true,
                  controller: dateEditingController,
                  validator: (v) => (v.isEmpty) ? "Required" : null,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                      labelText: "Date",
                      labelStyle: TextPalette.bodyText,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                      filled: true,
                      focusColor: Palette.grey_lighter,
                      fillColor: Palette.grey_lighter,
                      border: InputBorder.none,
                      helperText: " "),
                  onTap: () async {
                    var d = await showDatePicker(
                        initialDate: DateTime.now().add(Duration(hours: 12)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2035),
                        context: context,
                    );
                    dateEditingController.text = dateFormat.format(d);
                  },
                )),
              ],
            ),
            SizedBox(
              height: 16.0,
            ),
            Row(
              children: [
                Expanded(
                    child: TextFormField(
                  readOnly: true,
                  controller: startTimeEditingController,
                  validator: (v) => (v.isEmpty) ? "Required" : null,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                      labelText: "Start Time",
                      labelStyle: TextPalette.bodyText,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                      filled: true,
                      focusColor: Palette.grey_lighter,
                      fillColor: Palette.grey_lighter,
                      border: InputBorder.none,
                      helperText: " "),
                  onTap: () async {
                    var d = await showCustomTimePicker(
                      context: context,
                      // It is a must if you provide selectableTimePredicate
                      onFailValidation: (context) => print(""),
                      initialTime: TimeOfDay(hour: 18, minute: 0),
                      selectableTimePredicate: (time) => time.minute % 5 == 0,
                    );
                    startTimeEditingController.text = d.format(context);
                    endTimeEditingController.text =
                        TimeOfDay(hour: d.hour + 1, minute: d.minute)
                            .format(context);
                    setState(() {});
                  },
                )),
                SizedBox(width: 16),
                Expanded(
                    child: TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: endTimeEditingController,
                  validator: (v) => (v.isEmpty) ? "Required" : null,
                  decoration: InputDecoration(
                      labelText: "End Time",
                      labelStyle: TextPalette.bodyText,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                      filled: true,
                      focusColor: (startTimeOfDay == null)
                          ? Palette.grey_lightest
                          : Palette.grey_lighter,
                      fillColor: Palette.grey_lighter,
                      border: InputBorder.none,
                      enabled: startTimeOfDay != null,
                      helperText: " "),
                  readOnly: true,
                  enabled: startTimeOfDay != null,
                  onTap: () async {
                    var d = await showCustomTimePicker(
                        context: context,
                        onFailValidation: (context) => print(""),
                        initialTime: endTimeOfDay,
                        selectableTimePredicate: (time) =>
                            time == null || isAfter(time, startTimeOfDay));
                    endTimeEditingController.text = d.format(context);
                    // setState(() {
                    //   endTimeOfDay = d;
                    // });
                  },
                )),
              ],
            ),
            SizedBox(
              height: 16.0,
            )
          ],
        ),
      ),
      Section(
        title: "COURT",
        body: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: TextFormField(
                  readOnly: true,
                  validator: (v) => (v.isEmpty) ? "Required" : null,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: sportCenterEditingController,
                  decoration: InputDecoration(
                    suffixIcon: Icon(Icons.arrow_drop_down),
                    labelText: "Location",
                    labelStyle: TextPalette.bodyText,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                    filled: true,
                    focusColor: Palette.grey_lighter,
                    fillColor: Palette.grey_lighter,
                    border: InputBorder.none,
                  ),
                  onTap: () async {
                    var sportCenters =
                        context.read<LoadOnceState>().getSportCenters();

                    var i = await ModalBottomSheet.showNutmegModalBottomSheet(
                        context,
                        Padding(
                          padding:
                              EdgeInsets.only(left: 16, right: 16, top: 16),
                          child: ListView.builder(
                              shrinkWrap: true,
                              scrollDirection: Axis.vertical,
                              itemCount: sportCenters.length,
                              itemBuilder: (context, i) => InkWell(
                                    onTap: () => Navigator.of(context).pop(i),
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                          top: (i == 0) ? 0 : 16.0),
                                      child: InfoContainer(
                                          backgroundColor:
                                              Palette.grey_lightest,
                                          child: Text(sportCenters[i].name,
                                              style: TextPalette.bodyText)),
                                    ),
                                  )),
                        ));
                    if (i != null) {
                      sportCenterEditingController.text = sportCenters[i].name;
                      setState(() {
                        sportCenterId = sportCenters[i].placeId;
                      });
                    }
                  },
                )),
              ],
            ),
            SizedBox(
              height: 16.0,
            ),
            Row(
              children: [
                Expanded(
                    child: TextFormField(
                  readOnly: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) => (v.isEmpty) ? "Required" : null,
                  controller: sportEditingController,
                  decoration: InputDecoration(
                    labelText: "Sport",
                    suffixIcon: Icon(Icons.arrow_drop_down),
                    labelStyle: TextPalette.bodyText,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                    filled: true,
                    focusColor: Palette.grey_lighter,
                    fillColor: Palette.grey_lighter,
                    border: InputBorder.none,
                  ),
                  onTap: () async {
                    var sports = context.read<LoadOnceState>().getSports();

                    var i = await ModalBottomSheet.showNutmegModalBottomSheet(
                        context,
                        Padding(
                          padding:
                              EdgeInsets.only(left: 16, right: 16, top: 16),
                          child: ListView.builder(
                              shrinkWrap: true,
                              scrollDirection: Axis.vertical,
                              itemCount: sports.length,
                              itemBuilder: (context, i) => InkWell(
                                    onTap: () => Navigator.of(context).pop(i),
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                          top: (i == 0) ? 0 : 16.0),
                                      child: InfoContainer(
                                          backgroundColor:
                                              Palette.grey_lightest,
                                          child: Text(sports[i].displayTitle,
                                              style: TextPalette.bodyText)),
                                    ),
                                  )),
                        ));
                    if (i != null) {
                      sportEditingController.text = sports[i].displayTitle;
                      setState(() {
                        sportId = sports[i].documentId;
                      });
                    }
                  },
                )),
              ],
            ),
          ],
        ),
      ),
      Section(
        title: "PRICE",
        body: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: TextFormField(
                  validator: (v) {
                    if (v.isEmpty) return "Required";
                    var f = regexPrice.firstMatch(v);
                    if (f == null || f.end - f.start != v.length)
                      return "Invalid amount";
                    if (double.parse(v) < 0.50)
                      return "Minimum amount is € 0.50";
                    return null;
                  },
                  onChanged: (v) {
                    setState(() {});
                  },
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    prefixText: "€ ",
                    labelText: "Price per player",
                    labelStyle: TextPalette.bodyText,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                    filled: true,
                    focusColor: Palette.grey_lighter,
                    fillColor: Palette.grey_lighter,
                    border: InputBorder.none,
                  ),
                )),
              ],
            ),
          ],
        ),
      ),
      Section(
        title: "NUMBER OF PLAYERS",
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(numberOfPeopleRangeValues.start.toStringAsFixed(0),
                    style: TextPalette.bodyText),
                Expanded(
                    child: SliderTheme(
                  data: SliderThemeData(
                    thumbColor: Palette.primary,
                    activeTrackColor: Palette.primary,
                    showValueIndicator: ShowValueIndicator.always,
                  ),
                  child: RangeSlider(
                    values: numberOfPeopleRangeValues,
                    max: 22,
                    min: 6,
                    divisions: 8,
                    labels: RangeLabels(
                      numberOfPeopleRangeValues.start.toString(),
                      numberOfPeopleRangeValues.end.toString(),
                    ),
                    onChanged: (RangeValues values) {
                      setState(() {
                        numberOfPeopleRangeValues = values;
                      });
                    },
                  ),
                )),
                Text(numberOfPeopleRangeValues.end.toStringAsFixed(0),
                    style: TextPalette.bodyText),
              ],
            ),
            SizedBox(
              height: 16.0,
            ),
            Text(
                "This is the minimum (and maximum) amount of player that can join the match. "
                "If the minimum number is not reached, the match will be canceled. ",
                style: TextPalette.bodyText),
            SizedBox(
              height: 8.0,
            ),
            Builder(builder: (BuildContext context) {
              if (priceController.text.isEmpty) {
                return Container();
              }
              var price = double.parse(priceController.text);

              return Row(children: [
                Text("You will earn between", style: TextPalette.bodyText),
                Spacer(),
                Text(
                    "€ " +
                        (price * numberOfPeopleRangeValues.start)
                            .toStringAsFixed(2) +
                        " - " +
                        "€ " +
                        (price * numberOfPeopleRangeValues.end)
                            .toStringAsFixed(2),
                    style: TextPalette.h3)
              ]);
            })
          ],
        ),
      ),
      if (context.read<UserState>().getLoggedUserDetails().isAdmin)
        Section(
          title: "ADMIN",
          body: Row(
            children: [
              Text("Is a test match?", style: TextPalette.bodyText),
              Spacer(),
              Checkbox(
                  value: isTest,
                  activeColor: Palette.primary,
                  onChanged: (v) {
                    setState(() {
                      isTest = v;
                    });
                  })
            ],
          ),
        )
    ];

    return Scaffold(
        body: Container(
            child: CustomScrollView(
          slivers: [
            appBar,
            SliverPadding(
              padding: EdgeInsets.all(16.0),
              sliver: Form(
                key: _formKey,
                child: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return widgets[index];
                    },
                    childCount: widgets.length,
                  ),
                ),
              ),
            )
          ],
        )),
        bottomNavigationBar: GenericBottomBar(
            child: Padding(
          padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
          child: Row(children: [
            UserAvatar(20, context.watch<UserState>().getLoggedUserDetails()),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Organized by", style: TextPalette.bodyText),
                  SizedBox(height: 4),
                  Text(
                      context
                          .watch<UserState>()
                          .getLoggedUserDetails()
                          .name
                          .split(" ")
                          .first,
                      style: TextPalette.h2),
                ],
              ),
            ),
            GenericButtonWithLoader("CREATE", (BuildContext context) async {
              context.read<GenericButtonWithLoaderState>().change(true);

              if (_formKey.currentState.validate()) {
                var stod = toTimeOfTheDay(startTimeEditingController.text);
                var etod = toTimeOfTheDay(endTimeEditingController.text);
                var day = DateTime.parse(dateEditingController.text);
                var dateTime = DateTime(
                    day.year, day.month, day.day, stod.hour, stod.minute);
                var endTime = DateTime(
                    day.year, day.month, day.day, etod.hour, etod.minute);

                var match = Match(
                    dateTime,
                    sportCenterId,
                    null,
                    sportId,
                    numberOfPeopleRangeValues.end.toInt(),
                    (double.parse(priceController.text) * 100).toInt(),
                    endTime.difference(dateTime),
                    isTest,
                    numberOfPeopleRangeValues.start.toInt(),
                    context
                        .read<UserState>()
                        .getLoggedUserDetails()
                        .documentId);

                var id = await MatchesController.addMatch(match);
                print("added match with id " + id);
                Get.offNamed("/match/" + id);
                // await MatchesController.refresh(context, id);
              } else {
                print("validation error");
                setState(() {});
              }

              context.read<GenericButtonWithLoaderState>().change(false);
            }, Primary())
          ]),
        )));
  }

  TimeOfDay toTimeOfTheDay(String v) =>
      TimeOfDay.fromDateTime(DateFormat.jm().parse(v));

  bool isAfter(TimeOfDay a, TimeOfDay b) =>
      (a.hour * 60 + a.minute) > (b.hour * 60 + b.minute);
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
              Text("New Match", style: TextPalette.h1Default),
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
                                    Text(
                                        context
                                            .read<UserState>()
                                            .getUserDetail(u)
                                            .name,
                                        style: TextPalette.h3)
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
