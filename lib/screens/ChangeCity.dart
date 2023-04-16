import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/PageTemplate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../utils/LocationUtils.dart';
import 'CreateMatch.dart';

class ChangeCity extends StatefulWidget {
  LocationInfo originalLocationInfo;

  ChangeCity(this.originalLocationInfo);

  @override
  State<StatefulWidget> createState() => ChangeCityState();
}

class ChangeCityState extends State<ChangeCity> {
  TextEditingController cityController = TextEditingController();

  // this is what we save if we git city from GPS
  LocationInfo? selectedLocationInfo;

  // this is what we save if we get city from the list
  String? placeId;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    cityController.text = widget.originalLocationInfo.getText();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (selectedLocationInfo == null && placeId == null) {
          return true;
        }
        var newUserLocation;
        if (selectedLocationInfo != null)
          newUserLocation = selectedLocationInfo;
        else {
          var resp =
              await CloudFunctionsClient().get("locations/place/$placeId");
          newUserLocation = LocationInfo(
              resp!["country"], resp["city"], resp["lat"], resp["lng"]);
        }
        await context
            .read<UserState>()
            .editUser({"location": newUserLocation.toJson()});
        return true;
      },
      child: PageTemplate(
        refreshState: null,
        widgets: [
          Center(
            child: Container(
              width: 700,
              child: Column(
                children: [
                  Row(children: [
                    Text(AppLocalizations.of(context)!.searchLocationTitle,
                        style: TextPalette.h1Default)
                  ]),
                  SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      Expanded(
                          child: TypeAheadField<PredictionResult>(
                        textFieldConfiguration: TextFieldConfiguration(
                            style: TextPalette.getBodyText(Palette.black),
                            decoration: CreateMatchState.getTextFormDecoration(
                                AppLocalizations.of(context)!
                                    .searchLocationInputFieldLabel),
                            controller: cityController),
                        suggestionsCallback: (pattern) async {
                          List<PredictionResult> predictions = [];
                          if (pattern.isNotEmpty) {
                            var result = await getCitiesPrediction(pattern);
                            predictions = result;
                          }
                          return predictions;
                        },
                        itemBuilder: (context, suggestion) {
                          String description = suggestion.description;
                          var matchedSubstrings = suggestion.matches;

                          // todo check case of more matches
                          var firstMatch = matchedSubstrings[0];
                          String? boldText;
                          String normalText;

                          if (firstMatch.offset == 0) {
                            boldText =
                                description.substring(0, firstMatch.length);
                            normalText =
                                description.substring(firstMatch.length);
                          } else {
                            normalText = description;
                          }

                          return ListTile(
                              leading: Icon(Icons.place),
                              title: RichText(
                                  text: TextSpan(
                                style: TextPalette.bodyText,
                                children: <TextSpan>[
                                  if (boldText != null)
                                    TextSpan(
                                        text: boldText,
                                        style: TextPalette.bodyText.copyWith(
                                            fontWeight: FontWeight.bold)),
                                  TextSpan(text: normalText),
                                ],
                              )));
                        },
                        noItemsFoundBuilder: (value) => Container(height: 0,),
                        onSuggestionSelected: (suggestion) async {
                          cityController.text = suggestion.description;
                          setState(() {
                            placeId = suggestion.placeId;
                          });
                        },
                      ))
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  InkWell(
                    onTap: () async {
                      setState(() {
                        _loading = true;
                      });
                      Position? position = await determinePosition();
                      if (position != null) {
                        var fetchedLocationInfo = await fetchLocationInfo(
                            position.latitude, position.longitude);
                        cityController.text = "${fetchedLocationInfo.city}, "
                            "${fetchedLocationInfo.country}";
                        setState(() {
                          selectedLocationInfo = LocationInfo(
                              fetchedLocationInfo.country,
                              fetchedLocationInfo.city,
                              fetchedLocationInfo.lat,
                              fetchedLocationInfo.lng);
                          _loading = false;
                        });
                      }
                    },
                    child: Row(
                      children: [
                        Icon(Icons.gps_fixed, color: Palette.primary),
                        SizedBox(width: 10),
                        Text(AppLocalizations.of(context)!.currentLocationLabel,
                            style: TextPalette.linkStyle),
                        Spacer(),
                        if (_loading)
                          SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                color: Palette.primary,
                                strokeWidth: 2,
                              )),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Divider(
                    color: Palette.grey_light,
                  ),
                  SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context)!.currentLocationInfo,
                    style: TextPalette.bodyText,
                  )
                ],
              ),
            ),
          )
        ],
        appBar: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BackButton(color: Palette.black),
          ],
        ),
      ),
    );
  }
}
