import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/screens/BottomBarMatch.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/PageTemplate.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:provider/provider.dart';
import 'package:time_picker_widget/time_picker_widget.dart';

import '../../state/LoadOnceState.dart';
import '../widgets/ModalBottomSheet.dart';

// main widget
class CreateMatch extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => CreateMatchState();
}

class CreateMatchState extends State<CreateMatch> {
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
                      border: InputBorder.none),
                  onTap: () async {
                    var d = await showDatePicker(
                        initialDate: DateTime.now().add(Duration(hours: 12)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2035),
                        context: context,
                    );
                    if (d != null)
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
                      border: InputBorder.none),
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
                      focusColor: (startTimeEditingController.text.isEmpty)
                          ? Palette.grey_lightest
                          : Palette.grey_lighter,
                      fillColor: Palette.grey_lighter,
                      border: InputBorder.none),
                  readOnly: true,
                  enabled: startTimeEditingController.text.isNotEmpty,
                  onTap: () async {
                    var currentStart = toTimeOfTheDay(startTimeEditingController.text);

                    var d = await showCustomTimePicker(
                        context: context,
                        onFailValidation: (context) => print(""),
                        initialTime: toTimeOfTheDay(endTimeEditingController.text),
                        selectableTimePredicate: (time) =>
                            time == null || isAfter(time, currentStart));
                    if (d != null)
                      endTimeEditingController.text = d.format(context);
                  },
                )),
              ],
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

    return Form(
      key: _formKey,
      child: PageTemplate(
        refreshState: null,
        widgets: widgets,
        appBar: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BackButton(color: Palette.black),
          ],
        ),
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
            )),
      ),
    );
  }

  TimeOfDay toTimeOfTheDay(String v) =>
      TimeOfDay.fromDateTime(DateFormat.jm().parse(v));

  bool isAfter(TimeOfDay a, TimeOfDay b) =>
      (a.hour * 60 + a.minute) > (b.hour * 60 + b.minute);
}
