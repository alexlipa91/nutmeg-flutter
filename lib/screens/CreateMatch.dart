import 'package:decimal/decimal.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/Exceptions.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/model/SportCenter.dart';
import 'package:nutmeg/screens/BottomBarMatch.dart';
import 'package:nutmeg/screens/CreateCourt.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/LocationUtils.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/PageTemplate.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:nutmeg/widgets/Skeletons.dart';
import 'package:provider/provider.dart';
import 'package:time_picker_widget/time_picker_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../state/LoadOnceState.dart';
import '../state/MatchesState.dart';
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
  static InputDecoration getTextFormDecoration(String? label,
      {bool isDropdown = false,
      bool fill = true,
      focusColor,
      prefixText,
      hintStyle,
      hintText}) {
    var border = UnderlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(8),
    );

    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      floatingLabelStyle: TextPalette.bodyText,
      prefixText: prefixText,
      hintStyle: hintStyle,
      hintText: hintText,
      // fixme why we need this?
      suffixIconConstraints: BoxConstraints.expand(width: 50.0, height: 30.0),
      suffixIcon: isDropdown ? Icon(Icons.arrow_drop_down) : null,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
      filled: true,
      focusColor: (focusColor == null) ? Palette.greyLighter : focusColor,
      fillColor: fill ? Palette.greyLighter : Palette.greyLight,
      disabledBorder: border,
      focusedBorder: border,
      enabledBorder: border,
      border: border,
    );
  }

  // current match state
  DateTime? start;
  TimeOfDay? startTime, endTime;
  SportCenter? sportCenter;
  bool isSavedSportCenter = false;
  bool isTest = false;
  bool paymentsPossible = true;
  bool managePayments = true;
  bool withAutomaticCancellation = false;
  bool privateMatch = false;
  Duration cancelBefore = Duration(hours: 24);
  int repeatsForWeeks = 1;
  bool organiserWithFee = false;
  String? courtNumber;
  RangeValues numberOfPeopleRangeValues = RangeValues(8, 10);
  String? price;

  final _formKey = GlobalKey<FormState>();
  final regexPrice = new RegExp("\\d+(\\.\\d{1,2})?");

  TextEditingController dateEditingController = TextEditingController();
  TextEditingController startTimeEditingController = TextEditingController();
  TextEditingController endTimeEditingController = TextEditingController();
  TextEditingController sportCenterEditingController = TextEditingController();
  TextEditingController repeatWeeklyEditingController = TextEditingController();
  TextEditingController courtNumberEditingController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController cancelTimeEditingController = TextEditingController();
  FocusNode sportCenterfocusNode = FocusNode();
  FocusNode datefocusNode = FocusNode();
  FocusNode startTimefocusNode = FocusNode();

  Future<void> refreshState() async {
    print("refresh state");
    var res = await Future.wait([
      context.read<LoadOnceState>().fetchSavedSportCenters(),
      context.read<UserState>().fetchLoggedUserSportCenters(),
      CloudFunctionsClient().get("users/organisers_with_fee")
    ]);
    if (res[2] != null)
      organiserWithFee = ((res[2]! as Map)["users"] as List)
          .contains(context.read<UserState>().currentUserId!);
  }

  void unfocusIfNoValue(FocusNode focusNode, TextEditingController controller) {
    if (controller.text.isEmpty && focusNode.hasFocus) focusNode.unfocus();
  }

  @override
  void initState() {
    super.initState();

    // avoid focus when no data
    sportCenterfocusNode.addListener(() =>
        unfocusIfNoValue(sportCenterfocusNode, sportCenterEditingController));
    datefocusNode.addListener(
        () => unfocusIfNoValue(datefocusNode, dateEditingController));
    startTimefocusNode.addListener(
        () => unfocusIfNoValue(startTimefocusNode, startTimeEditingController));

    // nothing that context.watch should be here
    if (widget.existingMatch != null) {
      sportCenter = widget.existingMatch!.sportCenter;
      isTest = widget.existingMatch!.isTest;
      withAutomaticCancellation = widget.existingMatch!.cancelBefore != null;
      cancelTimeEditingController.text =
          widget.existingMatch!.cancelBefore?.inHours.toString() ?? "";
      managePayments = widget.existingMatch!.price != null;
      paymentsPossible =
          !blacklistedCountriesForPayments.contains(sportCenter!.country);
      start = widget.existingMatch!.dateTime;
      startTime = widget.existingMatch!.getStart();
      endTime = widget.existingMatch!.getEnd();
      courtNumber = widget.existingMatch!.sportCenterSubLocation;
      price = widget.existingMatch!.price!.basePrice.toString();
      numberOfPeopleRangeValues = RangeValues(
          widget.existingMatch!.minPlayers.toDouble(),
          widget.existingMatch!.maxPlayers.toDouble());
    }

    refreshState();
  }

  void initControllers() {
    var dateFormat = DateFormat("dd-MM-yyyy",
        getLanguageLocaleRead(context).countryCode);

    if (start != null) {
      dateEditingController.text = dateFormat.format(start!);
    }
    if (startTime != null) {
      startTimeEditingController.text = getFormattedTime(startTime!);
    }
    if (endTime != null) {
      endTimeEditingController.text = getFormattedTime(endTime!);
    }
    if (sportCenter != null) {
      sportCenterEditingController.text = sportCenter!.name;
    }
    repeatWeeklyEditingController.text = (repeatsForWeeks == 1) ? AppLocalizations.of(context)!.doesNotRepeatLabel : AppLocalizations.of(context)!
        .repeatForWeeks(repeatsForWeeks);
    if(courtNumber != null) {
      courtNumberEditingController.text = courtNumber!;
      courtNumberEditingController.selection = TextSelection
          .fromPosition(TextPosition(offset: courtNumber!.length));
    }
    if (price != null) {
      var priceString = price?.toString() ?? "";
      priceController.text = priceString;
      priceController.selection = TextSelection
          .fromPosition(TextPosition(offset: priceString.length));
    }
    if (withAutomaticCancellation) {
      var hoursString = cancelBefore.inHours.toString();
      cancelTimeEditingController.text = hoursString;
      cancelTimeEditingController.selection = TextSelection
          .fromPosition(TextPosition(offset: hoursString.length));
    }
  }

  @override
  Widget build(BuildContext context) {
    initControllers();

    var requiredError = AppLocalizations.of(context)!.requiredError;
    var organiserId =
        context.read<UserState>().getLoggedUserDetails()!.documentId;
    var dateFormat =
        DateFormat("dd-MM-yyyy", getLanguageLocaleWatch(context).countryCode);

    var noRepeat = AppLocalizations.of(context)!.doesNotRepeatLabel;

    var widgets = [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
            widget.existingMatch != null
                ? AppLocalizations.of(context)!.editMatchTitle
                : AppLocalizations.of(context)!.newMatchTitle,
            style: TextPalette.h1Default),
      ),
      Section(
        titleType: "big",
        title: AppLocalizations.of(context)!.crudMatchGeneralTitle,
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
                        decoration: getTextFormDecoration(
                            AppLocalizations.of(context)!.dateInputLabel),
                        validator: (v) {
                          if (v == null || v.isEmpty) return requiredError;
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
                            setState(() {
                              start = d;
                            });
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
                    if (v == null || v.isEmpty) return requiredError;
                    return null;
                  },
                  readOnly: true,
                  decoration: getTextFormDecoration(
                      AppLocalizations.of(context)!.startTimeInputLabel),
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
                      setState(() {
                        startTime = TimeOfDay(hour: d.hour, minute: d.minute);
                        endTime = TimeOfDay(hour: d.hour + 1, minute: d.minute);
                      });
                    }
                  },
                )),
                SizedBox(width: 16),
                Expanded(
                    child: TextFormField(
                        enabled: startTimeEditingController.text.isNotEmpty,
                        controller: endTimeEditingController,
                        validator: (v) {
                          if (v == null || v.isEmpty) return requiredError;
                          return null;
                        },
                        readOnly: true,
                        decoration: getTextFormDecoration(
                            AppLocalizations.of(context)!.endTimeInputLabel,
                            focusColor:
                                (startTimeEditingController.text.isEmpty)
                                    ? Palette.greyLightest
                                    : Palette.greyLighter),
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
                          if (d != null) {
                            setState(() {
                              endTime = TimeOfDay(hour: d.hour, minute: d.minute);
                            });
                          }
                        }
                    )
                ),
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
                          decoration: getTextFormDecoration(
                              AppLocalizations.of(context)!.repeatInputLabel,
                              isDropdown: true),
                          onTap: () async {
                            var weeks = [1, 2, 4, 6, 8, 10];
                            var choices = weeks.map((e) {
                              if (e == 1)
                                return noRepeat;
                              else
                                return AppLocalizations.of(context)!
                                    .repeatForWeeks(e);
                            }).toList();

                            int? i = await showMultipleChoiceSheetWithText(
                                context,
                                AppLocalizations.of(context)!.repeatInputLabel,
                                choices);

                            if (i != null) {
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
                  AppLocalizations.of(context)!.lastMatchOn(dateFormat.format(
                      dateFormat
                          .parse(dateEditingController.text)
                          .add(Duration(days: 7 * repeatsForWeeks)))),
                  style: TextPalette.bodyText,
                  textAlign: TextAlign.left,
                ),
              )
          ],
        ),
      ),
      Section(
        titleType: "big",
        title: AppLocalizations.of(context)!.courtSectionTitle,
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
                    if (v == null || v.isEmpty) return requiredError;
                    return null;
                  },
                  readOnly: true,
                  decoration: getTextFormDecoration(
                      AppLocalizations.of(context)!.locationSectionTitle,
                      isDropdown: true,
                      fill: widget.existingMatch == null),
                  onTap: () async {
                    SportCenter? sp =
                        await ModalBottomSheet.showNutmegModalBottomSheet(
                            context, LocationsBottomSheet());

                    if (sp != null) {
                      setState(() {
                        sportCenter = sp;
                        paymentsPossible = !blacklistedCountriesForPayments
                            .contains(sp.country.toUpperCase());
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
                  decoration: getTextFormDecoration(
                      AppLocalizations.of(context)!.courtNumberLabel),
                  onChanged: (v) => setState(() {
                    this.courtNumber = v;
                  })
                )),
              ],
            ),
          ],
        ),
      ),
      Section(
        title: AppLocalizations.of(context)!.numberOfPlayersSectionTitle,
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
                      inactiveTrackColor: Palette.greyLighter,
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
            Text(AppLocalizations.of(context)!.numberOfPlayersInfo,
                style: TextPalette.bodyText),
            SizedBox(
              height: 8.0,
            )
          ],
        ),
      ),
      Section(
        title: AppLocalizations.of(context)!.paymentSectionTitle,
        titleType: "big",
        body: Column(children: [
          Row(
            children: [
              if (paymentsPossible)
                Checkbox(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                    value: managePayments,
                    activeColor: Palette.primary,
                    onChanged: widget.existingMatch != null
                        ? null
                        : (v) {
                            setState(() {
                              managePayments = v!;
                            });
                          }),
              if (paymentsPossible)
                Flexible(
                    child: Text(AppLocalizations.of(context)!.paymentEnableInfo,
                        style: TextPalette.bodyText,
                        overflow: TextOverflow.visible)),
              if (!paymentsPossible)
                Flexible(
                    child: Text(
                        AppLocalizations.of(context)!.paymentNotPossibleInfo,
                        style: TextPalette.bodyText,
                        overflow: TextOverflow.visible)),
            ],
          ),
          SizedBox(
            height: 16,
          ),
          if (paymentsPossible && managePayments)
            Container(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: TextFormField(
                              enabled: widget.existingMatch == null,
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return requiredError;
                                var f = regexPrice.firstMatch(v);
                                if (f == null || f.end - f.start != v.length)
                                  return AppLocalizations.of(context)!
                                      .invalidAmountError;
                                if (double.parse(v) < 0.50)
                                  return AppLocalizations.of(context)!
                                      .minimumAmountError;
                                return null;
                              },
                              onChanged: (v) {
                                setState(() {
                                  price = v;
                                });
                              },
                              controller: priceController,
                              keyboardType: TextInputType.numberWithOptions(
                                  signed: true, decimal: true),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*$')),
                              ],
                              decoration: getTextFormDecoration(
                                  AppLocalizations.of(context)!
                                      .pricePerPlayerLabel,
                                  prefixText: "€ ",
                                  fill: widget.existingMatch == null))),
                    ],
                  ),
                  if (ConfigsUtils.feesOnOrganiser(organiserId))
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Row(children: [
                        Text(
                            AppLocalizations.of(context)!
                                .nutmegFeeInfo(formatCurrency(50)),
                            style: TextPalette.bodyText),
                      ]),
                    ),
                  SizedBox(height: 16),
                  Row(children: [
                    Text(AppLocalizations.of(context)!.youWillGetLabel,
                        style: TextPalette.h3),
                    Spacer(),
                    Builder(builder: (BuildContext buildContext) {
                      var price = Decimal.tryParse(priceController.text);
                      if (price != null &&
                          ConfigsUtils.feesOnOrganiser(organiserId))
                        price = price - Decimal.parse("0.5");
                      return Text(
                          (price == null)
                              ? "€ --"
                              : "€ " +
                                  (price.toDouble() *
                                          numberOfPeopleRangeValues.start)
                                      .toStringAsFixed(2) +
                                  " - " +
                                  "€ " +
                                  (price.toDouble() *
                                          numberOfPeopleRangeValues.end)
                                      .toStringAsFixed(2),
                          style: TextPalette.h3);
                    }),
                  ]),
                  SizedBox(height: 8),
                  Row(children: [
                    Text(AppLocalizations.of(context)!.usersWillPayLabel,
                        style: TextPalette.bodyText),
                    Spacer(),
                    Builder(builder: (BuildContext buildContext) {
                      var price = Decimal.tryParse(priceController.text);
                      if (price != null && organiserWithFee)
                        price = price + Decimal.parse("0.5");
                      return Text(
                          (price == null)
                              ? "€ --"
                              : "€ ${price.toDouble().toStringAsFixed(2)}",
                          style: TextPalette.bodyText);
                    }),
                  ]),
                  if (organiserWithFee)
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text(AppLocalizations.of(context)!.usersWillPayText,
                          style: GoogleFonts.roboto(
                              color: Palette.greyDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 1.6)),
                    ]),
                  SizedBox(height: 16),
                  NutmegDivider(horizontal: true),
                  RichText(
                      textAlign: TextAlign.start,
                      text: TextSpan(
                        children: [
                          TextSpan(
                              text: AppLocalizations.of(context)!
                                  .paymentExplanationText,
                              style: TextPalette.bodyText),
                          TextSpan(
                              text: " Stripe.",
                              recognizer: TapGestureRecognizer()
                                ..onTap = () async {
                                  final url = 'https://stripe.com';
                                  if (await canLaunchUrl(Uri.parse(url))) {
                                    await launchUrl(
                                      Uri.parse(url),
                                    );
                                  }
                                },
                              style: TextPalette.bodyText.copyWith(
                                  color: Palette.primary,
                                  decoration: TextDecoration.underline))
                        ],
                      ))
                ],
              ),
            )
        ]),
      ),
      if (widget.existingMatch == null)
        Section(
          title: AppLocalizations.of(context)!.policiesSectionTitle,
          titleType: "big",
          body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                SizedBox(width: 8,),
                Flexible(
                    child: Text(
                        AppLocalizations.of(context)!.automaticCancellationInfo,
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

                            if (sportCenter == null) return "Select Location";

                            DateTime? d = getDateTime(
                                dateFormat,
                                startTimeEditingController,
                                sportCenter!.timezoneId);
                            if (d != null &&
                                d.subtract(duration).isBefore(DateTime.now())) {
                              return "The interval is in the past";
                            }

                            return null;
                          },
                          controller: cancelTimeEditingController,
                          onChanged: (v) {
                            setState(() {
                              cancelBefore = Duration(hours: int.parse(v));
                            });
                          },
                          decoration: getTextFormDecoration(null),
                          keyboardType: TextInputType.numberWithOptions(
                              signed: false, decimal: false)),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: AppLocalizations.of(context)!.hoursLabel,
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
                      AppLocalizations.of(context)!
                          .automaticCancellationExplanation(
                              numberOfPeopleRangeValues.start.toInt(),
                              cancelTimeEditingController.text),
                      style: TextPalette.bodyText,
                      overflow: TextOverflow.visible)),
            SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                    value: privateMatch,
                    activeColor: Palette.primary,
                    onChanged: (v) {
                      setState(() {
                        privateMatch = v!;
                      });
                    }),
                SizedBox(width: 8,),
                Flexible(
                    child: Text(
                        AppLocalizations.of(context)!.privateMatchInfo,
                        style: TextPalette.bodyText,
                        overflow: TextOverflow.visible)),
              ],
            ),
          ]),
        ),
      if (widget.existingMatch == null &&
          context.read<UserState>().getLoggedUserDetails()!.isAdmin!)
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
            title: AppLocalizations.of(context)!.youWantToLeaveTitle,
            description: AppLocalizations.of(context)!.youWantToLeaveSubtitle,
            action: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GenericButtonWithLoader(AppLocalizations.of(context)!.cancel,
                    (_) async {
                  Navigator.pop(context, false);
                }, Secondary()),
                SizedBox(width: 8),
                GenericButtonWithLoader(AppLocalizations.of(context)!.yes,
                    (_) async {
                  Navigator.pop(context, true);
                }, Primary()),
              ],
            )).show(context);
      },
      child: Form(
        key: _formKey,
        child: PageTemplate(
          refreshState: null,
          widgets: [
            Center(
              child: Container(width: 700, child: Column(children: widgets)),
            )
          ],
          appBar: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BackButton(color: Palette.black),
            ],
          ),
          bottomNavigationBar: GenericBottomBar(
              child: Padding(
            padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Expanded(
                child: Container(
                  width: 700,
                  child: GenericButtonWithLoader(
                      widget.existingMatch == null
                          ? AppLocalizations.of(context)!.createButtonText
                          : AppLocalizations.of(context)!.confirmButtonText,
                      (BuildContext context) async {
                    context.read<GenericButtonWithLoaderState>().change(true);
                    bool? v = _formKey.currentState?.validate();
                    if (v != null && v) {
                      try {
                        var dateTime = DateTime(
                            start!.year, start!.month, start!.day,
                            startTime!.hour, startTime!.minute);
                        var endDateTime = DateTime(
                            start!.year, start!.month, start!.day,
                            endTime!.hour, endTime!.minute);
                        var forWeeks = repeatsForWeeks;

                        Iterable<Future<String>> idsFuture =
                            Iterable<int>.generate(forWeeks).map((w) async {
                          var match = Match(
                              dateTime,
                              (isSavedSportCenter)
                                  ? sportCenter!.placeId
                                  : null,
                              sportCenter!,
                              courtNumber,
                              numberOfPeopleRangeValues.end.toInt(),
                              (paymentsPossible && managePayments)
                                  ? Price(
                                      (Decimal.parse(price!) *
                                              Decimal.parse("100"))
                                          .toDouble()
                                          .toInt(),
                                      organiserWithFee ? 50 : 0)
                                  : null,
                              endDateTime.difference(dateTime),
                              isTest,
                              numberOfPeopleRangeValues.start.toInt(),
                              widget.existingMatch != null
                                  ? widget.existingMatch!.organizerId
                                  : context
                                      .read<UserState>()
                                      .getLoggedUserDetails()!
                                      .documentId,
                              widget.existingMatch != null
                                  ? widget.existingMatch!.going
                                  : Map(),
                              widget.existingMatch != null
                                  ? widget.existingMatch!.computedTeams
                                  : [],
                              widget.existingMatch != null
                                  ? widget.existingMatch!.manualTeams
                                  : [],
                              widget.existingMatch != null
                                  ? widget.existingMatch!.isPrivate
                                  : privateMatch,
                              withAutomaticCancellation ? cancelBefore : null,
                              widget.existingMatch != null
                                  ? widget.existingMatch!.score
                                  : null);

                          var id;
                          if (widget.existingMatch == null) {
                            id = await context
                                .read<MatchesState>()
                                .createMatch(match);
                            print("added match with id " + id);
                          } else {
                            match.documentId = widget.existingMatch!.documentId;
                            await context
                                .read<MatchesState>()
                                .editMatch(match.documentId, match.toJson());

                            id = widget.existingMatch!.documentId;
                          }
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
                ),
              )
            ]),
          )),
        ),
      ),
    );
  }

  DateTime? getDateTime(DateFormat dateFormat, TextEditingController controller,
      String timezoneId) {
    if (dateEditingController.text.isEmpty || controller.text.isEmpty)
      return null;
    var day = dateFormat.parse(dateEditingController.text);
    var stod = toTimeOfTheDay(controller.text);
    return tz.TZDateTime(tz.getLocation(timezoneId), day.year, day.month,
        day.day, stod.hour, stod.minute);
  }

  TimeOfDay toTimeOfTheDay(String v) {
    var dateTime = DateFormat.jm().parse(v);
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  getFormattedTime(TimeOfDay time) =>
      '${time.hourOfPeriod}:${time.minute.toString().padLeft(2, "0")} ${time.period.toString().split('.')[1].toUpperCase()}';

  bool isAfter(TimeOfDay a, TimeOfDay b) =>
      (a.hour * 60 + a.minute) > (b.hour * 60 + b.minute);

  static Future<int?> showMultipleChoiceSheetWithText(
      BuildContext context, String title, List<String> choices) async {
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
                      style: TextPalette.getBodyText(Palette.greyDark)),
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
      return ListOfMatchesSkeleton.withoutContainer(repeatFor: 2);

    var popularCourtsSection = Section(
        title: AppLocalizations.of(context)!.popularCourtsTitle,
        topSpace: 0,
        titleType: "big",
        belowTitleSpace: 16,
        body: Column(
            children: interleave(
                    (context.watch<LoadOnceState>().savedSportCenters ?? [])
                        .map((e) => SportCenterRow(sportCenter: e))
                        .toList(),
                    SizedBox(height: 16))
                .toList()));
    var yourCourts = Section(
        title: AppLocalizations.of(context)!.yourCourtsTitle,
        titleType: "big",
        topSpace: 32,
        belowTitleSpace: 16,
        body: Builder(
          builder: (context) {
            List<Widget> yourCourtsWidgets = [];
            yourCourtsWidgets.addAll(interleave(
              (context.watch<UserState>().getSportCenters() ?? [])
                  .map((e) => SportCenterRow(sportCenter: e))
                  .toList(),
              SizedBox(height: 16),
            ));

            if (userState.getSportCenters()!.isNotEmpty) {
              yourCourtsWidgets.add(SizedBox(
                height: 16,
              ));
            }

            yourCourtsWidgets.addAll([
              InkWell(
                onTap: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (context) => CreateCourt()));
                },
                child: Row(
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      child: DottedBorder(
                        padding: EdgeInsets.zero,
                        borderType: BorderType.RRect,
                        radius: Radius.circular(10),
                        color: Palette.greyDark,
                        strokeWidth: 1,
                        dashPattern: [4],
                        child: CircleAvatar(
                          radius: 29,
                          child: Icon(Icons.add,
                              color: Palette.greyDark, size: 24),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(AppLocalizations.of(context)!.createNewCourtText.toString().toUpperCase(),
                        style: TextPalette.linkStyle),
                  ],
                ),
              )
            ]);

            return Column(children: yourCourtsWidgets);
          },
        ));

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [popularCourtsSection, yourCourts]);
  }
}
