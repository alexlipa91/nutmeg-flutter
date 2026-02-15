import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/model/LocationInfo.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/PageTemplate.dart';
import 'package:nutmeg/l10n/app_localizations.dart';

import '../utils/LocationUtils.dart';
import 'CreateMatch.dart';

class ChangeCity extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => ChangeCityState();
}

class ChangeCityState extends State<ChangeCity> {
  TextEditingController cityController = TextEditingController();

  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
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
                      builder: (context, controller, focusNode) {
                        return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            style: TextPalette.getBodyText(Palette.black),
                            decoration: CreateMatchState.getTextFormDecoration(
                                AppLocalizations.of(context)!
                                    .searchLocationInputFieldLabel));
                      },
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
                          normalText = description.substring(firstMatch.length);
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
                      // noItemsFoundBuilder: (value) => Container(
                      //   height: 0,
                      // ),
                      onSelected: (suggestion) async {
                        cityController.text = suggestion.description;
                        var resp = await CloudFunctionsClient()
                            .get("locations/place/${suggestion.placeId}");
                        Navigator.pop(
                            context,
                            LocationInfo(resp!["country"], resp["city"],
                                resp["lat"], resp["lng"]));
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
                    LocationInfo? location = await getLocationFromIP();
                    if (location != null) {
                      Navigator.pop(context, location);
                    } else {
                      GenericInfoModal(
                          title: AppLocalizations.of(context)!.locationErrorTitle,
                          description: AppLocalizations.of(context)!.locationErrorDescription)
                          .show(context);
                    }
                    setState(() {
                      _loading = false;
                    });
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
                NutmegDivider(horizontal: true),
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
    );
  }
}
