import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/Exceptions.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/controller/SportCentersController.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/model/SportCenter.dart';
import 'package:nutmeg/screens/BottomBarMatch.dart';
import 'package:nutmeg/screens/CreateCourt.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/PageTemplate.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:nutmeg/widgets/Skeletons.dart';
import 'package:provider/provider.dart';
import 'package:time_picker_widget/time_picker_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../state/LoadOnceState.dart';
import '../widgets/GenericAvailableMatches.dart';
import '../widgets/ModalBottomSheet.dart';

// main widget
class CreateMatch extends StatefulWidget {
  
  final Match? existingMatch;

  CreateMatch() : existingMatch = null;
  
  CreateMatch.edit(this.existingMatch);
  
  @override
  State<StatefulWidget> createState() => CreateMatchState();
}

class CreateMatchState extends State<CreateMatch> {
  static const String NO_REPEAT = "Does not repeat";

  static InputDecoration getTextFormDecoration(String? label,
      {bool isDropdown = false, bool fill = true, focusColor, prefixText}) {
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
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
      filled: true,
      focusColor: (focusColor == null) ? Palette.grey_lighter : focusColor,
      fillColor: fill ? Palette.grey_lighter : Palette.grey_light,
      disabledBorder: border,
      focusedBorder: border,
      enabledBorder: border,
      border: border,
    );
  }

  late SportCenter sportCenter;

  final _formKey = GlobalKey<FormState>();

  late TextEditingController dateEditingController;
  late TextEditingController startTimeEditingController;
  late TextEditingController endTimeEditingController;
  late TextEditingController sportCenterEditingController;
  late TextEditingController repeatWeeklyEditingController;
  late TextEditingController courtNumberEditingController;
  late TextEditingController priceController;
  late RangeValues numberOfPeopleRangeValues;
  late bool isTest;
  late bool withAutomaticCancellation;
  late int repeatsForWeeks;
  late TextEditingController cancelTimeEditingController;

  final dateFormat = DateFormat("dd-MM-yyyy");
  final regexPrice = new RegExp("\\d+(\\.\\d{1,2})?");

  late FocusNode sportCenterfocusNode;
  late FocusNode datefocusNode;
  late FocusNode startTimefocusNode;

  Future<void> refreshState() async {
    await context.read<LoadOnceState>().fetchSportCenters();
    context.read<UserState>().fetchSportCenters();
  }

  void unfocusIfNoValue(FocusNode focusNode, TextEditingController controller) {
    if (controller.text.isEmpty && focusNode.hasFocus) focusNode.unfocus();
  }

  @override
  void initState() {
    super.initState();
    
    if (widget.existingMatch == null) {
      dateEditingController = TextEditingController();
      startTimeEditingController = TextEditingController();
      endTimeEditingController = TextEditingController();
      sportCenterEditingController = TextEditingController();
      repeatWeeklyEditingController = TextEditingController(text: NO_REPEAT);
      courtNumberEditingController = TextEditingController();
      priceController = TextEditingController();
      numberOfPeopleRangeValues = RangeValues(8, 10);
      isTest = false;
      withAutomaticCancellation = false;
      repeatsForWeeks = 1;
      cancelTimeEditingController = TextEditingController(text: "24");
    } else {
      dateEditingController = TextEditingController(text: dateFormat
          .format(widget.existingMatch!.dateTime));
      startTimeEditingController = TextEditingController(
          text: getFormattedTime(TimeOfDay.fromDateTime(widget.existingMatch!.dateTime)));
      endTimeEditingController = TextEditingController(
          text: getFormattedTime(TimeOfDay.fromDateTime(
              widget.existingMatch!.dateTime.add(widget.existingMatch!.duration)))
      );
      sportCenterEditingController = TextEditingController(
        text: SportCentersController.getSportCenter(context, widget.existingMatch)!.name
      );
      repeatWeeklyEditingController = TextEditingController(text: NO_REPEAT);
      courtNumberEditingController = TextEditingController(
          text: widget.existingMatch!.sportCenterSubLocation);
      priceController = TextEditingController(
          text: (widget.existingMatch!.pricePerPersonInCents / 100).toString());
      numberOfPeopleRangeValues = RangeValues(widget.existingMatch!.minPlayers.toDouble(), 
          widget.existingMatch!.maxPlayers.toDouble());
      isTest = widget.existingMatch!.isTest;
      withAutomaticCancellation = widget.existingMatch!.cancelBefore != null;
      repeatsForWeeks = 1;
      cancelTimeEditingController = TextEditingController(
          text: widget.existingMatch!.cancelBefore?.inHours.toString());

      sportCenter = SportCentersController.getSportCenter(context,
          widget.existingMatch!)!;
    }


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
      Text("${widget.existingMatch != null ? "Edit": "New"} Match",
          style: TextPalette.h1Default),
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
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Required";
                          return null;
                        },
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
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Required";
                    return null;
                  },
                  readOnly: true,
                  decoration: getTextFormDecoration("Start time"),
                  onTap: () async {
                    var d = await showCustomTimePicker(
                      builder: (BuildContext context, Widget? child) {
                        return MediaQuery(
                          data: MediaQuery.of(context)
                              .copyWith(alwaysUse24HourFormat: false),
                          child: child!,
                        );
                      },
                      context: context,
                      // It is a must if you provide selectableTimePredicate
                      onFailValidation: (context) => print(""),
                      initialTime: TimeOfDay(hour: 18, minute: 0),
                      selectableTimePredicate: (time) =>
                          (time?.minute)! % 5 == 0,
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
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Required";
                          return null;
                        },
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
                              builder: (BuildContext context, Widget? child) {
                                return MediaQuery(
                                  data: MediaQuery.of(context)
                                      .copyWith(alwaysUse24HourFormat: false),
                                  child: child!,
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
            if (widget.existingMatch == null)
              Row(
              children: [
                Expanded(
                    child: TextFormField(
                        enabled: widget.existingMatch == null,
                        readOnly: true,
                        controller: repeatWeeklyEditingController,
                        decoration:
                            getTextFormDecoration("Repeat", isDropdown: true),
                        onTap: () async {
                          var weeks = [1, 2, 4, 6, 8, 10];
                          var choices = weeks.map((e) {
                            if (e == 1)
                              return NO_REPEAT;
                            else
                              return "Weekly for " + e.toString() + " weeks";
                          }).toList();

                          int? i = await showMultipleChoiceSheetWithText(
                            context, "Repeat", choices);

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
            if (repeatsForWeeks != 1 && dateEditingController.text.isNotEmpty)
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
                  enabled: widget.existingMatch == null,
                  focusNode: sportCenterfocusNode,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Required";
                    return null;
                  },
                  readOnly: true,
                  decoration:
                      getTextFormDecoration("Location", isDropdown: true,
                          fill: widget.existingMatch == null),
                  onTap: () async {
                    SportCenter? sp =
                        await ModalBottomSheet.showNutmegModalBottomSheet(
                            context,
                            LocationsBottomSheet());

                    if (sp != null) {
                      sportCenterEditingController.text = sp.getName();
                      setState(() {
                        sportCenter = sp;
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
                  inputFormatters: [LengthLimitingTextInputFormatter(5)],
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
                      divisions: 22 - 6,
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
          Row(
            children: [
              Expanded(
                  child: TextFormField(
                      enabled: widget.existingMatch == null,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Required";
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
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*$')),
                      ],
                      decoration: getTextFormDecoration("Price per player",
                          prefixText: "€ ",
                          fill: widget.existingMatch == null))),
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
      if (widget.existingMatch == null)
        Section(
          title: "Policies",
          titleType: "big",
          body: Column(children: [
            Row(
            children: [
              Checkbox(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
                  value: withAutomaticCancellation,
                  activeColor: Palette.primary,
                  onChanged: (v) {
                    setState(() {
                      withAutomaticCancellation = v!;
                    });
                  }),
              Flexible(
                  child: Text(
                      "Automatically cancel the match if minimum amount of players is not reached",
                      style: TextPalette.bodyText,
                      overflow: TextOverflow.visible)),
            ],
          ),
            if (withAutomaticCancellation)
              Padding(
              padding: EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                        validator: (v) {
                          var durationSize = int.tryParse(v!);
                          if (durationSize == null) return "Invalid duration";
                          Duration duration = Duration(hours: durationSize);

                          var d = getDateTime();
                          if (d != null &&
                              getDateTime()!
                                  .subtract(duration)
                                  .isBefore(DateTime.now())) {
                            return "The interval is in the past";
                          }

                          return null;
                        },
                        controller: cancelTimeEditingController,
                        onChanged: (v) {
                          setState(() {});
                        },
                        decoration: getTextFormDecoration(null),
                        keyboardType: TextInputType.numberWithOptions(
                            signed: false, decimal: false)),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: "Hours",
                      readOnly: true,
                      decoration: getTextFormDecoration(null),
                    ),
                  ),
                ],
              ),
            ),
            if (withAutomaticCancellation)
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                    "We will cancel the match if at least "
                    "${numberOfPeopleRangeValues.start.toInt()} "
                    "players haven't joined by "
                    "${cancelTimeEditingController.text} hours",
                    style: TextPalette.bodyText,
                    overflow: TextOverflow.visible))
          ]),
        ),
      if (widget.existingMatch == null
          && context.read<UserState>().getLoggedUserDetails()!.isAdmin!)
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
                          isTest = v!;
                        });
                      })
                ],
              ),
              SizedBox(height: 16),
              Text(
                  "A test match will be visible only to Admin users and it will use Stripe test environment (both for organizer account and for users' payments)",
                  style: TextPalette.bodyText),
            ]))
    ];

    return WillPopScope(
      onWillPop: () async {
        return await GenericInfoModal(
            title: "Are you sure you want to leave?",
            description: "If you leave, all your unsaved changes will be lost.",
            action: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GenericButtonWithLoader("CANCEL", (_) async {
                  Navigator.pop(context, false);
                }, Secondary()),
                SizedBox(width: 8),
                GenericButtonWithLoader("YES", (_) async {
                  Navigator.pop(context, true);
                }, Primary()),
              ],
            )).show(context);
      },
      child: Form(
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
                child: GenericButtonWithLoader(
                    widget.existingMatch == null ? "CREATE": "EDIT",
                    (BuildContext context) async {
                  context.read<GenericButtonWithLoaderState>().change(true);

                  bool? v = _formKey.currentState?.validate();
                  if (v != null && v) {
                    try {
                      var etod = toTimeOfTheDay(endTimeEditingController.text);
                      var day = dateFormat.parse(dateEditingController.text);
                      var dateTime = getDateTime();
                      var endTime = DateTime(day.year, day.month, day.day,
                              etod.hour, etod.minute)
                          .toUtc();
                      var duration = endTime.difference(dateTime!);
                      var cancelBefore = withAutomaticCancellation
                          ? Duration(
                              hours:
                                  int.parse(cancelTimeEditingController.text))
                          : null;

                      var forWeeks = repeatsForWeeks;

                      Iterable<Future<String>> idsFuture =
                          Iterable<int>.generate(forWeeks).map((w) async {
                        var match = Match(
                            dateTime.add(Duration(days: 7 * w)),
                            (sportCenter is SavedSportCenter) ? sportCenter.placeId : null,
                            (sportCenter is SavedSportCenter) ? null : sportCenter,
                            courtNumberEditingController.text,
                            numberOfPeopleRangeValues.end.toInt(),
                            (double.parse(priceController.text) * 100).toInt(),
                            duration,
                            isTest,
                            numberOfPeopleRangeValues.start.toInt(),
                            context
                                .read<UserState>()
                                .getLoggedUserDetails()!
                                .documentId,
                            cancelBefore);

                        var id;
                        if (widget.existingMatch == null) {
                          id = await MatchesController.addMatch(match);
                        } else {
                          await MatchesController.editMatch(match,
                              widget.existingMatch!.documentId);
                          id = widget.existingMatch!.documentId;
                        }
                        await MatchesController.refresh(context, id);
                        print("added match with id " + id);
                        return id;
                      });

                      var ids = await Future.wait(idsFuture);

                      context.go("/match/${ids.first}");
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
                }, Primary()),
              )
            ]),
          )),
        ),
      ),
    );
  }

  DateTime? getDateTime() {
    if (dateEditingController.text.isEmpty ||
        startTimeEditingController.text.isEmpty) return null;
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

  static Future<int?> showMultipleChoiceSheetWithText(BuildContext context,
      String title, List<String> choices) async {
    int? i = await ModalBottomSheet.showNutmegModalBottomSheet(
        context,
        Column(
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
        ));
    return i;
  }
}

class SportCenterRow extends StatelessWidget {

  final SportCenter sportCenter;

  const SportCenterRow({Key? key, required this.sportCenter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context, sportCenter),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MatchThumbnail(image: sportCenter.getThumbnail(), height: 60),
          SizedBox(width: 16),
          Expanded(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sportCenter.getName(), style: TextPalette.h3),
                  SizedBox(
                    height: 8,
                  ),
                  Text(sportCenter.address,
                      style: TextPalette.getBodyText(
                          Palette.grey_dark)),
                ]),
          ),
        ],
      ),
    );
  }
}

class LocationsBottomSheet extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    var userState = context.watch<UserState>();

    if (userState.getSportCenters() == null)
      return ListOfMatchesSkeleton(repeatFor: 2);

    var popularCourts = Section(
        title: "Popular courts",
        topSpace: 0,
        titleType: "big",
        belowTitleSpace: 16,
        body: Column(children: interleave(context
            .read<LoadOnceState>()
            .getSportCenters()
            .map((e) => SportCenterRow(sportCenter: e)).toList(),
            SizedBox(height: 16)).toList()));
    var yourCourts = Section(
        title: "Your Courts",
        titleType: "big",
        topSpace: 32,
        belowTitleSpace: 16,
        body: Builder(
          builder: (context) {
            List<Widget> yourCourtsWidgets = [];
            yourCourtsWidgets.addAll(interleave(userState
                .getSportCenters()!
                .map((e) => SportCenterRow(sportCenter: e))
                .toList(),
              SizedBox(height: 16),
            ));

            if (userState.getSportCenters()!.isNotEmpty) {
              yourCourtsWidgets.add(SizedBox(height: 16,));
            }

            yourCourtsWidgets.addAll([
              InkWell(
                onTap: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (context) =>
                          CreateCourt()));
                },
                child: Row(children: [
                  Container(
                    height: 60,
                    width: 60,
                    child: DottedBorder(
                      padding: EdgeInsets.zero,
                      borderType: BorderType.RRect,
                      radius: Radius.circular(10),
                      color: Palette.grey_dark,
                      strokeWidth: 1,
                      dashPattern: [4],
                      child: CircleAvatar(
                        radius: 29,
                        child: Icon(Icons.add, color: Palette.grey_dark, size: 24),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Text("CREATE NEW COURT", style: TextPalette.linkStyle),
                ],),
              )
            ]);

            return Column(children: yourCourtsWidgets);
          },
        ));

    return Column(children: [popularCourts, yourCourts]);
  }
}
