import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/Exceptions.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/screens/BottomBarMatch.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/PageTemplate.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:provider/provider.dart';
import 'package:time_picker_widget/time_picker_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../state/LoadOnceState.dart';
import '../model/Sport.dart';
import '../widgets/ModalBottomSheet.dart';

// main widget
class CreateMatch extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => CreateMatchState();
}

class CreateMatchState extends State<CreateMatch> {
  static const String NO_REPEAT = "Does not repeat";

  static InputDecoration getTextFormDecoration(String label,
      {bool isDropdown = false, focusColor = null, prefixText = null}) {
    var border = UnderlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(8),
    );

    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      floatingLabelStyle: TextPalette.bodyText,
      prefixText: prefixText,
      // fixme why we need this?
      suffixIconConstraints: BoxConstraints.expand(width: 50.0, height: 30.0),
      suffixIcon: isDropdown ? Icon(Icons.arrow_drop_down) : null,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
      filled: true,
      focusColor: (focusColor == null) ? Palette.grey_lighter : focusColor,
      fillColor: Palette.grey_lighter,
      disabledBorder: border,
      focusedBorder: border,
      enabledBorder: border,
      border: border,
    );
  }

  String sportCenterId;
  Sport sport;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController dateEditingController =
      TextEditingController(text: "");
  final TextEditingController startTimeEditingController =
      TextEditingController(text: "");
  final TextEditingController endTimeEditingController =
      TextEditingController(text: "");
  final TextEditingController repeatWeeklyEditingController =
      TextEditingController(text: NO_REPEAT);
  final TextEditingController sportCenterEditingController =
      TextEditingController(text: "");
  final TextEditingController sportEditingController =
      TextEditingController(text: "");
  final TextEditingController courtNumberEditingController =
      TextEditingController(text: "");
  final TextEditingController priceController = TextEditingController();
  RangeValues numberOfPeopleRangeValues = RangeValues(8, 10);
  bool isTest = false;
  int repeatsForWeeks = 0;

  final dateFormat = DateFormat("dd-MM-yyyy");
  final regexPrice = new RegExp("\\d+(\\.\\d{1,2})?");

  FocusNode sportCenterfocusNode;
  FocusNode datefocusNode;
  FocusNode startTimefocusNode;

  Future<void> refreshState() async {
    await context.read<LoadOnceState>().fetchSportCenters();
  }

  void unfocusIfNoValue(FocusNode focusNode, TextEditingController controller) {
    if (controller.text.isEmpty && focusNode.hasFocus) focusNode.unfocus();
  }

  @override
  void initState() {
    super.initState();

    // set default sport
    sport = context.read<LoadOnceState>().getSports().first;
    sportEditingController.text =
        context.read<LoadOnceState>().getSports().first.displayTitle;

    sportCenterfocusNode = FocusNode();
    datefocusNode = FocusNode();
    startTimefocusNode = FocusNode();

    // avoid focus when no data
    sportCenterfocusNode.addListener(() =>
        unfocusIfNoValue(sportCenterfocusNode, sportCenterEditingController));
    datefocusNode.addListener(
        () => unfocusIfNoValue(datefocusNode, dateEditingController));
    startTimefocusNode.addListener(
        () => unfocusIfNoValue(startTimefocusNode, startTimeEditingController));

    refreshState();
  }

  @override
  Widget build(BuildContext context) {
    var widgets = [
      Text("New Match", style: TextPalette.h1Default),
      Section(
        titleType: "big",
        title: "General",
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: TextFormField(
                        controller: dateEditingController,
                        focusNode: datefocusNode,
                        readOnly: true,
                        decoration: getTextFormDecoration("Date"),
                        onTap: () async {
                          var d = await showDatePicker(
                              initialDate:
                                  DateTime.now().add(Duration(hours: 12)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2035),
                              context: context);
                          if (d != null) {
                            dateEditingController.text = dateFormat.format(d);
                            setState(() {});
                          }
                        }))
              ],
            ),
            SizedBox(
              height: 16.0,
            ),
            Row(
              children: [
                Expanded(
                    child: TextFormField(
                  controller: startTimeEditingController,
                  focusNode: startTimefocusNode,
                  readOnly: true,
                  decoration: getTextFormDecoration("Start time"),
                  onTap: () async {
                    var d = await showCustomTimePicker(
                      builder: (BuildContext context, Widget child) {
                        return MediaQuery(
                          data: MediaQuery.of(context)
                              .copyWith(alwaysUse24HourFormat: false),
                          child: child,
                        );
                      },
                      context: context,
                      // It is a must if you provide selectableTimePredicate
                      onFailValidation: (context) => print(""),
                      initialTime: TimeOfDay(hour: 18, minute: 0),
                      selectableTimePredicate: (time) => time.minute % 5 == 0,
                    );
                    if (d != null) {
                      startTimeEditingController.text = getFormattedTime(d);
                      endTimeEditingController.text = getFormattedTime(
                          TimeOfDay(hour: d.hour + 1, minute: d.minute));
                      setState(() {});
                    }
                  },
                )),
                SizedBox(width: 16),
                Expanded(
                    child: TextFormField(
                        enabled: startTimeEditingController.text.isNotEmpty,
                        controller: endTimeEditingController,
                        readOnly: true,
                        decoration: getTextFormDecoration("End Time",
                            focusColor:
                                (startTimeEditingController.text.isEmpty)
                                    ? Palette.grey_lightest
                                    : Palette.grey_lighter),
                        onTap: () async {
                          var currentStart =
                              toTimeOfTheDay(startTimeEditingController.text);

                          var d = await showCustomTimePicker(
                              builder: (BuildContext context, Widget child) {
                                return MediaQuery(
                                  data: MediaQuery.of(context)
                                      .copyWith(alwaysUse24HourFormat: false),
                                  child: child,
                                );
                              },
                              context: context,
                              onFailValidation: (context) => print(""),
                              initialTime:
                                  toTimeOfTheDay(endTimeEditingController.text),
                              selectableTimePredicate: (time) =>
                                  time == null || isAfter(time, currentStart));
                          if (d != null)
                            endTimeEditingController.text = getFormattedTime(d);
                        })),
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
                        controller: repeatWeeklyEditingController,
                        decoration:
                            getTextFormDecoration("Repeat", isDropdown: true),
                        onTap: () async {
                          var weeks = [0, 2, 4, 6, 8, 10];
                          var choices = weeks.map((e) {
                            if (e == 0)
                              return NO_REPEAT;
                            else
                              return "Weekly for " + e.toString() + " weeks";
                          }).toList();

                          int i =
                              await showMultipleChoiceSheet("Repeat", choices);

                          if (i != null) {
                            repeatWeeklyEditingController.text =
                                choices[i].toString();
                            setState(() {
                              repeatsForWeeks = weeks[i];
                            });
                          }
                        })),
              ],
            ),
            if (repeatsForWeeks != 0 && dateEditingController.text.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  "Last match on " +
                      dateFormat.format(dateFormat
                          .parse(dateEditingController.text)
                          .add(Duration(days: 7 * repeatsForWeeks))),
                  style: TextPalette.bodyText,
                  textAlign: TextAlign.left,
                ),
              )
          ],
        ),
      ),
      Section(
        titleType: "big",
        title: "Court",
        body: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: TextFormField(
                  controller: sportCenterEditingController,
                  enabled:
                      context.watch<LoadOnceState>().getSportCenters() != null,
                  focusNode: sportCenterfocusNode,
                  readOnly: true,
                  decoration:
                      getTextFormDecoration("Location", isDropdown: true),
                  onTap: () async {
                    var sportCenters =
                        context.read<LoadOnceState>().getSportCenters();

                    var i = await showMultipleChoiceSheet(
                        "Location", sportCenters.map((e) => e.name).toList());

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
                  controller: sportEditingController,
                  readOnly: true,
                  decoration: getTextFormDecoration("Sport", isDropdown: true),
                  onTap: () async {
                    var sports = context.read<LoadOnceState>().getSports();

                    var i = await showMultipleChoiceSheet(
                        "Sport", sports.map((e) => e.displayTitle).toList());

                    if (i != null) {
                      sportEditingController.text = sports[i].displayTitle;
                      setState(() {
                        sport = sports[i];
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
                  controller: courtNumberEditingController,
                  readOnly: false,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(5)
                  ],
                  decoration: getTextFormDecoration("Court number (optional)"),
                )),
              ],
            ),
          ],
        ),
      ),
      Section(
        title: "Number of Players",
        titleType: "big",
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
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      showValueIndicator: ShowValueIndicator.never,
                      inactiveTrackColor: Palette.grey_lighter,
                    ),
                    child: RangeSlider(
                      values: numberOfPeopleRangeValues,
                      max: 22,
                      min: 6,
                      divisions: 22-6,
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
                "This is the minimum and maximum amount of player that can join the match.",
                style: TextPalette.bodyText),
            SizedBox(
              height: 8.0,
            )
          ],
        ),
      ),
      Section(
        title: "Payment",
        titleType: "big",
        body: Column(children: [
          // SizedBox(height: 8),
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
                      keyboardType: TextInputType.numberWithOptions(
                          signed: true, decimal: true),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                      ],
                      decoration: getTextFormDecoration("Price per player", prefixText: "€ ")
                  )),
            ],
          ),
          SizedBox(height: 16),
          Row(children: [
            Text("You will get", style: TextPalette.h3),
            Spacer(),
            Builder(builder: (BuildContext buildContext) {
              var price = double.tryParse(priceController.text);
              return Text(
                  (price == null)
                      ? "€ --"
                      : "€ " +
                          (price * numberOfPeopleRangeValues.start)
                              .toStringAsFixed(2) +
                          " - " +
                          "€ " +
                          (price * numberOfPeopleRangeValues.end)
                              .toStringAsFixed(2),
                  style: TextPalette.h3);
            }),
          ]),
          SizedBox(height: 16),
          Divider(),
          SizedBox(height: 16),
          RichText(
              text: TextSpan(
            children: [
              TextSpan(
                  text: "Nutmeg releases the money 24h after the match end time. " +
                      "You will get paid 3 to 5 business days after that with ",
                  style: TextPalette.bodyText),
              TextSpan(
                  text: "Stripe",
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      final url = 'https://stripe.com';
                      if (await canLaunch(url)) {
                        await launch(
                          url,
                          forceSafariVC: false,
                        );
                      }
                    },
                  style: TextPalette.bodyText.copyWith(
                      color: Palette.primary,
                      decoration: TextDecoration.underline))
            ],
          ))
        ]),
      ),
      if (context.read<UserState>().getLoggedUserDetails().isAdmin)
        Section(
          title: "Admin",
          titleType: "big",
          body: Column(children: [
            Row(
              children: [
                Text("Select for test match", style: TextPalette.bodyText),
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
            SizedBox(height: 16),
            Text("A test match will be visible only to Admin users and it will use Stripe test environment (both for organizer account and for users' payments)", style: TextPalette.bodyText),
          ])
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      getDateTime() == null ? "" :
                      getFormattedDate(getDateTime()),
                      style: TextPalette.bodyText),
                  SizedBox(height: 4),
                  Text(
                      sportCenterEditingController.text,
                      style: TextPalette.h2),
                ],
              ),
            ),
            GenericButtonWithLoader("CREATE", (BuildContext context) async {
              context.read<GenericButtonWithLoaderState>().change(true);

              if (_formKey.currentState.validate()) {
                try {
                  var etod = toTimeOfTheDay(endTimeEditingController.text);
                  var day = dateFormat.parse(dateEditingController.text);
                  var dateTime = getDateTime();
                  var endTime = DateTime(
                          day.year, day.month, day.day, etod.hour, etod.minute)
                      .toUtc();
                  var duration = endTime.difference(dateTime);

                  var forWeeks =
                      int.tryParse(repeatWeeklyEditingController.text);
                  if (forWeeks == null) forWeeks = 1;

                  Iterable<Future<String>> idsFuture =
                      Iterable<int>.generate(forWeeks).map((w) async {
                    var match = Match(
                        dateTime.add(Duration(days: 7 * w)),
                        sportCenterId,
                        courtNumberEditingController.text,
                        sport.displayTitle,
                        numberOfPeopleRangeValues.end.toInt(),
                        (double.parse(priceController.text) * 100).toInt(),
                        duration,
                        isTest,
                        numberOfPeopleRangeValues.start.toInt(),
                        context
                            .read<UserState>()
                            .getLoggedUserDetails()
                            .documentId);

                    var id = await MatchesController.addMatch(match);
                    await MatchesController.refresh(context, id);
                    await UserController.refreshLoggedUser(context);
                    print("added match with id " + id);
                    return id;
                  });

                  var ids = await Future.wait(idsFuture);

                  Get.offNamed("/match/" + ids.first);
                } on Exception catch (e, s) {
                  print(e);
                  print(s);
                  ErrorHandlingUtils.handleError(e, s, context);
                }
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

  DateTime getDateTime() {
    if (dateEditingController.text.isEmpty || startTimeEditingController.text.isEmpty)
      return null;
    var day = dateFormat.parse(dateEditingController.text);
    var stod = toTimeOfTheDay(startTimeEditingController.text);
    return DateTime(day.year, day.month, day.day, stod.hour, stod.minute);
  }

  TimeOfDay toTimeOfTheDay(String v) {
    var dateTime = DateFormat.jm().parse(v);
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  getFormattedTime(TimeOfDay time) =>
      '${time.hourOfPeriod}:${time.minute.toString().padLeft(2, "0")} ${time.period.toString().split('.')[1].toUpperCase()}';

  bool isAfter(TimeOfDay a, TimeOfDay b) =>
      (a.hour * 60 + a.minute) > (b.hour * 60 + b.minute);

  Future<int> showMultipleChoiceSheet(
      String title, List<String> choices) async {
    int i = await ModalBottomSheet.showNutmegModalBottomSheet(
        context,
        Padding(
            padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextPalette.h2,
                ),
                SizedBox(height: 8.0),
                ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.vertical,
                    itemCount: choices.length,
                    itemBuilder: (context, i) => InkWell(
                          onTap: () => Navigator.of(context).pop(i),
                          child: Padding(
                            padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                            child: Text(choices[i].toString(),
                                style: GoogleFonts.roboto(
                                    color: Palette.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    height: 1.6)),
                          ),
                        ))
              ],
            )));
    return i;
  }
}
