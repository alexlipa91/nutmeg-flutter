import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_place/google_place.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/PageTemplate.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../model/SportCenter.dart';
import '../utils/LocationUtils.dart';
import '../widgets/ModalBottomSheet.dart';
import 'BottomBarMatch.dart';
import 'CreateMatch.dart';

class CreateCourt extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => CreateCourtState();
}

class CreateCourtState extends State<CreateCourt> {

  final TextEditingController surfaceController = TextEditingController();
  final TextEditingController courtTypeController = TextEditingController();
  final TextEditingController textEditingController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  List<AutocompletePrediction>? predictions;
  bool changeRoomsAvailable = false;

  String? address;
  String? name;
  String? placeId;
  double? lat;
  double? lng;

  Surface? surface;
  String? courtType;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: PageTemplate(
        refreshState: null,
        widgets: [
          Center(child: Container(
            width: 700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                  AppLocalizations.of(context)!.createNewCourtText,
                  style: TextPalette.h1Default),
              Section(
                  title:  AppLocalizations.of(context)!.courtInfoText,
                  titleType: "big",
                  body: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: TypeAheadField<PredictionResult>(
                                textFieldConfiguration: TextFieldConfiguration(
                                    style: TextPalette.getBodyText(Palette.black),
                                    decoration: CreateMatchState.getTextFormDecoration(
                                        AppLocalizations.of(context)!.courtLocationLabel),
                                    controller: textEditingController),
                                suggestionsCallback: (pattern) async {
                                  List<PredictionResult> predictions = [];
                                  if (pattern.isNotEmpty) {
                                    var result = await getPlacePrediction(pattern);
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
                                    boldText = description.substring(0,
                                        firstMatch.length);
                                    normalText = description
                                        .substring(firstMatch.length);
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
                                                TextSpan(text: boldText,
                                                    style: TextPalette.bodyText
                                                        .copyWith(fontWeight: FontWeight.bold)),
                                              TextSpan(text: normalText),
                                            ],)
                                      ));
                                },
                                noItemsFoundBuilder: (value) => Container(height: 0),
                                onSuggestionSelected: (suggestion) async {
                                  textEditingController.text = suggestion.description;
                                  setState(() {
                                    placeId = suggestion.placeId;
                                  });
                                },
                              ))
                        ],
                      )
                    ],
                  )),
              Section(
                  title: AppLocalizations.of(context)!.courtTypeTitleText,
                  titleType: "big",
                  body: Column(children: [
                    Row(
                      children: [
                        Expanded(
                            child: TextFormField(
                              readOnly: true,
                              controller: surfaceController,
                              decoration: CreateMatchState.getTextFormDecoration(
                                AppLocalizations.of(context)!.surfaceLabelText,
                                  isDropdown: true),
                              onTap: () async {
                                Surface? surface = await ModalBottomSheet.showNutmegModalBottomSheet(
                                    context,
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!.surfaceLabelText,
                                          style: TextPalette.h2,
                                        ),
                                        SizedBox(height: 16.0),
                                        SurfaceRow(
                                            surface: Surface.indoor,
                                        ),
                                        SizedBox(height: 16.0),
                                        SurfaceRow(
                                            surface: Surface.grass
                                        ),
                                      ],
                                    ));

                                if (surface != null) {
                                  surfaceController.text = surface.getTitle(context);
                                  setState(() {
                                    this.surface = surface;
                                  });
                                }
                              },
                              validator: (v) {
                                if (v == null || v.isEmpty) return AppLocalizations.of(context)!.requiredError;
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
                              controller: courtTypeController,
                              decoration: CreateMatchState.getTextFormDecoration(
                                  AppLocalizations.of(context)!.sizeTitle,
                                  isDropdown: true),
                              onTap: () async {
                                var sizes = ["5v5", "6v6", "7v7", "11v11"];

                                int? i = await CreateMatchState
                                    .showMultipleChoiceSheetWithText(
                                    context,
                                    AppLocalizations.of(context)!.sizeTitle,
                                    sizes);

                                if (i != null) {
                                  courtTypeController.text = sizes[i];
                                }
                              },
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return AppLocalizations.of(context)!.requiredError;
                                return null;
                              },
                            )),
                      ],
                    ),
                  ])),
              Section(
                  title: AppLocalizations.of(context)!.facilitiesTitle,
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
                              child: Text(
                                  AppLocalizations.of(context)!.changeRoomsAvailableLabel,
                                  style: TextPalette.bodyText,
                                  overflow: TextOverflow.visible)),
                        ],
                      ),
                    ],
                  )),
            ],),
          ),)
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
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            Expanded(
              child: Container(
                width: 700,
                child: GenericButtonWithLoaderAndErrorHandling(
                    AppLocalizations.of(context)!.createNewCourtText.toUpperCase(),
                    (_) async {
                  bool? v = _formKey.currentState?.validate();
                  if (v != null && v) {
                    await CloudFunctionsClient().post(
                      "/sportcenters/add", {
                        "place_id": placeId!,
                        "surface": surface!.getDbName(),
                        "hasChangingRooms": changeRoomsAvailable,
                        "courtType": courtTypeController.text
                      }
                    );
                    await context.read<UserState>().fetchLoggedUserSportCenters();

                    Navigator.of(context).pop();
                  }
                }, Primary()),
              ),
            )
          ]),
        )),
      ),
    );
  }
}

class SurfaceRow extends StatelessWidget {

  final Surface surface;

  const SurfaceRow({Key? key, required this.surface}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(surface),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10), // Image border
            child: SizedBox.fromSize(
              size: Size.fromRadius(30), // Image radius
              child: Image.asset(surface.getImagePath()),
            ),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(surface.getTitle(context), style: TextPalette.h3,),
              SizedBox(height: 8),
              Text(surface.getDescription(context),
                style: TextPalette.bodyText,)
            ],
          )
        ],),
    );
  }
}