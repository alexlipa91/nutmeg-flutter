import 'package:decimal/decimal.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nutmeg/model/Match.dart';
import 'package:nutmeg/model/SportCenter.dart';
import 'package:nutmeg/screens/BottomBarMatch.dart';
import 'package:nutmeg/screens/CreateCourt.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/LocationUtils.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/PageTemplate.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:nutmeg/widgets/Skeletons.dart';
import 'package:nutmeg/widgets/StripeSetupWidget.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:nutmeg/config/app_config.dart';
import 'package:nutmeg/l10n/app_localizations.dart';
import 'package:nutmeg/utils/navigate_url.dart';
import 'package:nutmeg/widgets/PayOutsideNutmegRow.dart';
import 'package:nutmeg/widgets/PayThroughNutmegRow.dart';

import '../../state/LoadOnceState.dart';
import '../state/MatchesState.dart';
import '../widgets/GenericAvailableMatches.dart';
import '../widgets/ModalBottomSheet.dart';

// main widget
class CreateMatch extends StatefulWidget {
  final String? existingMatch;

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
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
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
  bool isTest = AppConfig.testMode;
  bool paymentsPossible = true;
  bool hasPrice = false;
  bool showPaymentInfo = true;
  bool withAutomaticCancellation = false;
  bool privateMatch = false;
  Duration cancelBefore = Duration(hours: 24);
  int repeatsForWeeks = 1;
  bool organiserWithFee = false;
  String? courtNumber;
  int playersPerSide = 5;
  bool customPlayersPerSide = false;
  RangeValues numberOfPeopleRangeValues = RangeValues(10, 10);
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
  TextEditingController playersPerSideController = TextEditingController();
  TextEditingController cancelTimeEditingController = TextEditingController();
  FocusNode sportCenterfocusNode = FocusNode();
  FocusNode datefocusNode = FocusNode();
  FocusNode startTimefocusNode = FocusNode();

  final logger = CrashlyticsLogger('CreateMatch');

  Future<void> refreshState() async {
    logger.info("refreshing state");
    await Future.wait([
      context.read<LoadOnceState>().fetchSavedSportCenters(),
      context.read<UserState>().fetchLoggedUserSportCenters(),
      // CloudFunctionsClient().get("users/organisers_with_fee")
    ]);
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

    // Refresh user details when returning from Stripe onboarding (web)
    listenForStripeReturn(() {
      if (mounted) {
        context.read<UserState>().fetchLoggedUserDetails();
      }
    });

    initAsync();
  }

  Future<void> initAsync() async {
    if (widget.existingMatch != null) {
      var state = context.read<MatchesState>().getMatch(widget.existingMatch!)!;
      var match = state.match!;

      sportCenter = match.sportCenter;
      isTest = match.isTest;
      withAutomaticCancellation = match.cancelBefore != null;
      cancelTimeEditingController.text =
          match.cancelBefore?.inHours.toString() ?? "";
      hasPrice = match.price != null;
      showPaymentInfo = match.isManualPayment;
      start = match.getLocalizedTime();
      startTime = match.getLocalizedStart();
      endTime = match.getLocalizedEnd();
      courtNumber = match.sportCenterSubLocation;
      price =
          match.price == null ? null : formatCurrency(match.price!.basePrice);
      numberOfPeopleRangeValues =
          RangeValues(match.minPlayers.toDouble(), match.maxPlayers.toDouble());
      var perSide = match.maxPlayers ~/ 2;
      if ([5, 7, 8, 11].contains(perSide)) {
        playersPerSide = perSide;
        customPlayersPerSide = false;
      } else {
        playersPerSide = perSide;
        customPlayersPerSide = true;
        playersPerSideController.text = perSide.toString();
      }
    }

    refreshState();
  }

  void initControllers() {
    var dateFormat =
        DateFormat("dd-MM-yyyy", getLanguageLocaleRead(context).countryCode);

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
    repeatWeeklyEditingController.text = (repeatsForWeeks == 1)
        ? AppLocalizations.of(context)!.doesNotRepeatLabel
        : AppLocalizations.of(context)!.repeatForWeeks(repeatsForWeeks);
    if (courtNumber != null) {
      courtNumberEditingController.text = courtNumber!;
      courtNumberEditingController.selection =
          TextSelection.fromPosition(TextPosition(offset: courtNumber!.length));
    }
    if (price != null) {
      var priceString = price?.toString() ?? "";
      priceController.text = priceString;
      priceController.selection =
          TextSelection.fromPosition(TextPosition(offset: priceString.length));
    }
    if (withAutomaticCancellation) {
      var hoursString = cancelBefore.inHours.toString();
      cancelTimeEditingController.text = hoursString;
      cancelTimeEditingController.selection =
          TextSelection.fromPosition(TextPosition(offset: hoursString.length));
    }
  }

  @override
  Widget build(BuildContext context) {
    var existingMatch = widget.existingMatch != null
        ? context.watch<MatchesState>().getMatch(widget.existingMatch!).match
        : null;

    if (widget.existingMatch != null && existingMatch == null) {
      return Container();
    }

    initControllers();

    var requiredError = AppLocalizations.of(context)!.requiredError;
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
                              lastDate:
                                  DateTime.now().add(Duration(days: 28)),
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
                    var d = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: 18, minute: 0),
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
                          TimeOfDay? d = await showTimePicker(
                            context: context,
                            initialTime:
                                toTimeOfTheDay(endTimeEditingController.text),
                          );

                          if (d != null &&
                              (d.minute > currentStart.minute ||
                                  d.hour > currentStart.hour)) {
                            setState(() {
                              endTime =
                                  TimeOfDay(hour: d.hour, minute: d.minute);
                            });
                          }
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
                          decoration: getTextFormDecoration(
                              AppLocalizations.of(context)!.repeatInputLabel,
                              isDropdown: true),
                          onTap: () async {
                            var weeks = [1, 2, 3, 4];
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
                            }))),
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
            TextFormField(
              readOnly: true,
              controller: TextEditingController(
                  text: customPlayersPerSide
                      ? AppLocalizations.of(context)!.customOption
                      : "$playersPerSide"),
              decoration: getTextFormDecoration(
                  AppLocalizations.of(context)!.playersPerSideLabel,
                  isDropdown: true),
              onTap: () async {
                var options = [5, 7, 8, 11];
                var labels = [
                  ...options.map((n) => "$n"),
                  AppLocalizations.of(context)!.customOption,
                ];

                int? i = await showMultipleChoiceSheetWithText(context,
                    AppLocalizations.of(context)!.playersPerSideLabel, labels);

                if (i != null) {
                  setState(() {
                    if (i < options.length) {
                      playersPerSide = options[i];
                      customPlayersPerSide = false;
                      var total = playersPerSide * 2;
                      numberOfPeopleRangeValues =
                          RangeValues(total.toDouble(), total.toDouble());
                    } else {
                      customPlayersPerSide = true;
                      playersPerSideController.text = playersPerSide.toString();
                    }
                  });
                }
              },
              validator: (v) {
                if (v == null || v.isEmpty)
                  return AppLocalizations.of(context)!.requiredError;
                return null;
              },
            ),
            if (customPlayersPerSide) ...[
              SizedBox(height: 16),
              TextFormField(
                controller: playersPerSideController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: getTextFormDecoration(
                    AppLocalizations.of(context)!.customPlayersPerSideHint),
                onChanged: (v) {
                  var n = int.tryParse(v);
                  if (n != null && n >= 1) {
                    setState(() {
                      playersPerSide = n;
                      var total = n * 2;
                      numberOfPeopleRangeValues =
                          RangeValues(total.toDouble(), total.toDouble());
                    });
                  }
                },
                validator: (v) {
                  var n = int.tryParse(v ?? "");
                  if (n == null || n < 1)
                    return AppLocalizations.of(context)!.requiredError;
                  return null;
                },
              ),
            ],
            SizedBox(height: 16),
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
                    child: Builder(builder: (context) {
                      var total = playersPerSide * 2;
                      var sliderMin = (total - 2).toDouble();
                      var sliderMax = (total + 2).toDouble();
                      // Clamp current values to the new range
                      var clamped = RangeValues(
                        numberOfPeopleRangeValues.start
                            .clamp(sliderMin, sliderMax),
                        numberOfPeopleRangeValues.end
                            .clamp(sliderMin, sliderMax),
                      );
                      return RangeSlider(
                        values: clamped,
                        max: sliderMax,
                        min: sliderMin,
                        divisions: 4,
                        labels: RangeLabels(
                          clamped.start.toStringAsFixed(0),
                          clamped.end.toStringAsFixed(0),
                        ),
                        onChanged: (RangeValues values) {
                          setState(() {
                            numberOfPeopleRangeValues = values;
                          });
                        },
                      );
                    }),
                  ),
                )),
                Text(numberOfPeopleRangeValues.end.toStringAsFixed(0),
                    style: TextPalette.bodyText),
              ],
            ),
            SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.numberOfPlayersInfo,
                style: TextPalette.getBodyText(Palette.greyDark)),
            SizedBox(height: 8.0),
          ],
        ),
      ),
      Section(
        title: AppLocalizations.of(context)!.paymentSectionTitle,
        titleType: "big",
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // "Set Payment Info" checkbox
          Row(
            children: [
              Checkbox(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
                  value: hasPrice,
                  activeColor: Palette.primary,
                  onChanged: widget.existingMatch != null
                      ? null
                      : (v) {
                          setState(() {
                            hasPrice = v!;
                          });
                        }),
              Flexible(
                  child: Text(AppLocalizations.of(context)!.setPaymentInfo,
                      style: TextPalette.bodyText,
                      overflow: TextOverflow.visible)),
            ],
          ),
          if (hasPrice) ...[
            SizedBox(height: 16),
            // Price field
            Row(
              children: [
                Expanded(
                    child: TextFormField(
                        enabled: widget.existingMatch == null,
                        validator: (v) {
                          if (!hasPrice) return null;
                          if (v == null || v.isEmpty) return requiredError;
                          var f = regexPrice.firstMatch(v);
                          if (f == null || f.end - f.start != v.length)
                            return AppLocalizations.of(context)!
                                .invalidAmountError;
                          if (double.parse(v) < AppConfig.nutmegFeeEuros)
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
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*$')),
                        ],
                        decoration: getTextFormDecoration(
                            AppLocalizations.of(context)!.pricePerPlayerLabel,
                            prefixText: "€ ",
                            fill: widget.existingMatch == null))),
              ],
            ),
            SizedBox(height: 24),
            // Pay outside Nutmeg
            InkWell(
              onTap: widget.existingMatch != null
                  ? null
                  : () => setState(() => showPaymentInfo = true),
              child: Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: showPaymentInfo,
                    activeColor: Palette.primary,
                    onChanged: widget.existingMatch != null
                        ? null
                        : (v) => setState(() => showPaymentInfo = v!),
                  ),
                  Expanded(child: PayOutsideNutmegRow()),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Pay through Nutmeg
            InkWell(
              onTap: (widget.existingMatch != null ||
                      !ConfigsUtils.allowNutmegManagedPayments)
                  ? null
                  : () => setState(() => showPaymentInfo = false),
              child: Row(
                children: [
                  Radio<bool>(
                    value: false,
                    groupValue: showPaymentInfo,
                    activeColor: Palette.primary,
                    onChanged: (widget.existingMatch != null ||
                            !ConfigsUtils.allowNutmegManagedPayments)
                        ? null
                        : (v) => setState(() => showPaymentInfo = v!),
                  ),
                  Expanded(child: PayThroughNutmegRow()),
                ],
              ),
            ),
            if (!showPaymentInfo &&
                ConfigsUtils.allowNutmegManagedPayments)
              Divider(color: Palette.greyLight),
            // Pay through Nutmeg: additional content
            if (!showPaymentInfo &&
                ConfigsUtils.allowNutmegManagedPayments) ...[
              if (paymentsPossible) ...[
                SizedBox(height: 16),
                Row(children: [
                  Text(AppLocalizations.of(context)!.youWillGetLabel,
                      style: TextPalette.h3),
                  Spacer(),
                  Builder(builder: (BuildContext buildContext) {
                    var price = Decimal.tryParse(priceController.text);
                    var net =
                        (price != null) ? (price - Decimal.parse("0.5")) : null;
                    if (net != null && net < Decimal.zero) net = Decimal.zero;
                    return Text(
                        net == null
                            ? "€ --"
                            : "€ ${net.toDouble().toStringAsFixed(2)}",
                        style: TextPalette.h3);
                  }),
                ]),
                SizedBox(height: 8),
                Row(children: [
                  Text(AppLocalizations.of(context)!.stripeNutmegFeeLabel,
                      style: TextPalette.bodyText),
                  Spacer(),
                  Text("€ ${AppConfig.nutmegFeeEuros.toStringAsFixed(2)}", style: TextPalette.bodyText),
                ]),
                SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.stripePayoutExplanation,
                  style: TextPalette.getBodyText(Palette.greyDark),
                ),
              ],
              if (!paymentsPossible)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                      AppLocalizations.of(context)!.paymentNotPossibleInfo,
                      style: TextPalette.getBodyText(Palette.greyDark),
                      overflow: TextOverflow.visible),
                ),
            ],
          ],
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
                SizedBox(
                  width: 8,
                ),
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
                SizedBox(
                  width: 8,
                ),
                Flexible(
                    child: Text(AppLocalizations.of(context)!.privateMatchInfo,
                        style: TextPalette.bodyText,
                        overflow: TextOverflow.visible)),
              ],
            ),
          ]),
        ),
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

                    // Block creation if Pay through Nutmeg is selected but Stripe isn't ready
                    if (!showPaymentInfo &&
                        ConfigsUtils.allowNutmegManagedPayments) {
                      var ud = context.read<UserState>().getLoggedUserDetails();
                      var stripeReady =
                          ud?.areChargesEnabled(AppConfig.testMode) ?? false;
                      if (!stripeReady) {
                        var hasAccount = ud?.getStripeInfo(AppConfig.testMode)
                                ?.connectedAccountId !=
                            null;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          backgroundColor: Palette.warning,
                          content: InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              if (hasAccount) {
                                completeAccountAction(
                                    context, AppConfig.testMode);
                              } else {
                                showStripeHowItWorksModal(context);
                              }
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .stripeSetupRequired,
                                    style: TextStyle(color: Palette.black),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward,
                                    color: Palette.black, size: 20),
                              ],
                            ),
                          ),
                        ));
                        context
                            .read<GenericButtonWithLoaderState>()
                            .change(false);
                        return;
                      }
                    }

                    bool? v = _formKey.currentState?.validate();
                    if (v != null && v) {
                      try {
                        var forWeeks = repeatsForWeeks;

                        Iterable<Future<String>> idsFuture =
                            Iterable<int>.generate(forWeeks).map((w) async {
                          var dToAdd = Duration(days: 7 * w);

                          var startDateTime = tz.TZDateTime(
                                  tz.getLocation(sportCenter!.timezoneId),
                                  start!.year,
                                  start!.month,
                                  start!.day,
                                  startTime!.hour,
                                  startTime!.minute)
                              .add(dToAdd);
                          var endDateTime = tz.TZDateTime(
                                  tz.getLocation(sportCenter!.timezoneId),
                                  start!.year,
                                  start!.month,
                                  start!.day,
                                  endTime!.hour,
                                  endTime!.minute)
                              .add(dToAdd);

                          var match = Match(
                              startDateTime,
                              (isSavedSportCenter)
                                  ? sportCenter!.placeId
                                  : null,
                              sportCenter!,
                              courtNumber,
                              numberOfPeopleRangeValues.end.toInt(),
                              hasPrice
                                  ? Price(
                                      (Decimal.parse(price!) *
                                              Decimal.parse("100"))
                                          .toDouble()
                                          .toInt(),
                                      (!showPaymentInfo && organiserWithFee)
                                          ? AppConfig.nutmegFeeCents
                                          : 0)
                                  : null,
                              endDateTime.difference(startDateTime),
                              isTest,
                              numberOfPeopleRangeValues.start.toInt(),
                              widget.existingMatch != null
                                  ? existingMatch?.organizerId
                                  : context
                                      .read<UserState>()
                                      .getLoggedUserDetails()!
                                      .documentId,
                              widget.existingMatch != null
                                  ? existingMatch?.going ?? Map()
                                  : Map(),
                              widget.existingMatch != null
                                  ? existingMatch?.goingPaymentStatus ?? {}
                                  : {},
                              widget.existingMatch != null
                                  ? existingMatch?.goingWithPaymentIntent ?? {}
                                  : {},
                              widget.existingMatch != null
                                  ? existingMatch?.waitList ?? Map()
                                  : Map(),
                              widget.existingMatch != null
                                  ? existingMatch?.computedTeams ?? []
                                  : [],
                              widget.existingMatch != null
                                  ? existingMatch?.manualTeams ?? []
                                  : [],
                              widget.existingMatch != null
                                  ? existingMatch?.isPrivate ?? false
                                  : privateMatch,
                              withAutomaticCancellation ? cancelBefore : null,
                              widget.existingMatch != null
                                  ? existingMatch?.score
                                  : null,
                              showPaymentInfo);

                          var id;
                          if (widget.existingMatch == null) {
                            id = await context
                                .read<MatchesState>()
                                .createMatch(match);
                            logger.info("added match with id $id");
                          } else {
                            match.documentId = widget.existingMatch!;
                            await context
                                .read<MatchesState>()
                                .getMatch(widget.existingMatch!)
                                .editMatch(match.toJson());

                            id = widget.existingMatch!;
                          }
                          return id;
                        });

                        var ids = await Future.wait(idsFuture);

                        context.go("/match/${ids.first}");
                      } on Exception catch (e, s) {
                        logger.severe("error creating match", e, s);
                        if (mounted) {
                          GenericInfoModal(
                            title: AppLocalizations.of(context)!
                                .genericErrorMessage,
                            description: AppLocalizations.of(context)!
                                .genericErrorDesc,
                          ).show(context);
                        }
                      }
                    } else {
                      logger.severe("validation error");
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
    return Dismissible(
      key: ValueKey(sportCenter.placeId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: Colors.red,
        child: Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) {
        context.read<UserState>().deleteSportCenter(sportCenter.placeId);
      },
      child: InkWell(
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
                    SizedBox(height: 8),
                    Text(sportCenter.address,
                        style: TextPalette.getBodyText(Palette.greyDark)),
                  ]),
            ),
            SizedBox(width: 8),
            InkWell(
              onTap: () async {
                var confirmed = await _confirmDelete(context);
                if (confirmed == true) {
                  context
                      .read<UserState>()
                      .deleteSportCenter(sportCenter.placeId);
                }
              },
              child: Icon(Icons.close, color: Palette.greyDark, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteCourtTitle),
        content: Text(AppLocalizations.of(context)!.deleteCourtConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.deleteCourt,
              style: TextStyle(color: Colors.red),
            ),
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

    var yourCourts = Section(
        title: AppLocalizations.of(context)!.yourCourtsTitle,
        titleType: "big",
        topSpace: 0,
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
                  SportCenter? sp = await Navigator.push(context,
                      MaterialPageRoute(builder: (context) => CreateCourt()));
                  Navigator.of(context).pop(sp);
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
                    Text(
                        AppLocalizations.of(context)!
                            .createNewCourtText
                            .toString()
                            .toUpperCase(),
                        style: TextPalette.linkStyle),
                  ],
                ),
              )
            ]);

            return Column(children: yourCourtsWidgets);
          },
        ));

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [yourCourts]);
  }
}
