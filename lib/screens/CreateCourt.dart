import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_place/google_place.dart';
import 'package:nutmeg/model/SportCenter.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/PageTemplate.dart';
import 'package:nutmeg/widgets/Section.dart';

import 'BottomBarMatch.dart';
import 'CreateMatch.dart';

class CreateCourt extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => CreateCourtState();
}

class CreateCourtState extends State<CreateCourt> {
  final GooglePlace googlePlace = GooglePlace("AIzaSyDlU4z5DbXqoafB-T-t2mJ8rGv3Y4rAcWY");

  final TextEditingController surfaceController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController textEditingController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  List<AutocompletePrediction>? predictions;
  bool changeRoomsAvailable = false;

  String? address;
  String? placeId;
  double? lat;
  double? lng;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: PageTemplate(
        refreshState: null,
        widgets: [
          Text("Create New Court", style: TextPalette.h1Default),
          Section(
              title: "Court Information",
              titleType: "big",
              body: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: TypeAheadField<AutocompletePrediction>(
                        textFieldConfiguration: TextFieldConfiguration(
                            style: TextPalette.getBodyText(Palette.black),
                            decoration: CreateMatchState.getTextFormDecoration(
                                "Court Address"),
                            controller: textEditingController),
                        suggestionsCallback: (pattern) async {
                          List<AutocompletePrediction> predictions = [];
                          if (pattern.isNotEmpty) {
                            var result =
                                await googlePlace.autocomplete.get(pattern);
                            predictions = result?.predictions ?? [];
                          }
                          return predictions;
                        },
                        itemBuilder: (context, suggestion) {
                          return ListTile(
                            leading: Icon(Icons.place),
                            title: Text(suggestion.description ?? ""),
                          );
                        },
                        noItemsFoundBuilder: (value) => Container(height: 10),
                        onSuggestionSelected: (suggestion) async {
                          textEditingController.text =
                              suggestion.description ?? "";
                          var resp = await googlePlace.details.get(suggestion.placeId!);

                          setState(() {
                            placeId = suggestion.placeId;
                            address = suggestion.description;
                            lng = resp?.result?.geometry?.location?.lng!;
                            lat = resp?.result?.geometry?.location?.lat!;
                          });
                        },
                      ))
                    ],
                  )
                ],
              )),
          Section(
              title: "Court Type",
              titleType: "big",
              body: Column(children: [
                Row(
                  children: [
                    Expanded(
                        child: TextFormField(
                      readOnly: true,
                      controller: surfaceController,
                      decoration: CreateMatchState.getTextFormDecoration(
                          "Surface",
                          isDropdown: true),
                      onTap: () async {
                        var surfaces = ["Indoor", "Outdoor"];

                        int? i = await CreateMatchState
                            .showMultipleChoiceSheetWithText(
                                context, "Surface", surfaces);

                        if (i != null) {
                          surfaceController.text = surfaces[i];
                        }
                      },
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Required";
                        return null;
                      },
                    )),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: TextFormField(
                      readOnly: true,
                      controller: sizeController,
                      decoration: CreateMatchState.getTextFormDecoration("Size",
                          isDropdown: true),
                      onTap: () async {
                        var sizes = ["5v5", "6v6", "7v7", "11v11"];

                        int? i = await CreateMatchState
                            .showMultipleChoiceSheetWithText(
                                context, "Size", sizes);

                        if (i != null) {
                          sizeController.text = sizes[i];
                        }
                      },
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Required";
                        return null;
                      },
                    )),
                  ],
                ),
              ])),
          Section(
              title: "Facilities",
              titleType: "big",
              body: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                          value: changeRoomsAvailable,
                          activeColor: Palette.primary,
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                changeRoomsAvailable = v;
                              });
                            }
                          }),
                      Flexible(
                          child: Text("Change Rooms available",
                              style: TextPalette.bodyText,
                              overflow: TextOverflow.visible)),
                    ],
                  ),
                ],
              )),
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
          child: Row(children: [
            Expanded(
              child: GenericButtonWithLoader("CREATE NEW COURT",
                  (BuildContext context) async {
                bool? v = _formKey.currentState?.validate();
                if (v != null && v) {
                  Map<String, dynamic> info = Map();
                  if (changeRoomsAvailable)
                    info["changeRooms"] = true;
                  info["courtType"] = sizeController.text;
                  info["surface"] = surfaceController.text;

                  Navigator.of(context).pop(
                      SportCenter(address!, placeId!, lat!, lng!, info));
                }
              }, Primary()),
            )
          ]),
        )),
      ),
    );
  }
}
