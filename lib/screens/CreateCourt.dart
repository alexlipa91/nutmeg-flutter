import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_place/google_place.dart';
import 'package:nutmeg/controller/SportCentersController.dart';
import 'package:nutmeg/model/SportCenter.dart';
import 'package:nutmeg/state/UserSportCentersState.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/PageTemplate.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:provider/provider.dart';

import '../widgets/ModalBottomSheet.dart';
import 'BottomBarMatch.dart';
import 'CreateMatch.dart';

class CreateCourt extends StatefulWidget {

  UserSportCentersState userSportCentersState;

  CreateCourt(this.userSportCentersState);

  @override
  State<StatefulWidget> createState() => CreateCourtState();
}

class CreateCourtState extends State<CreateCourt> {
  final TextEditingController surfaceController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController textEditingController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  List<AutocompletePrediction>? predictions;
  bool changeRoomsAvailable = false;

  String? address;
  String? name;
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
                          child: TypeAheadField<Map<String, dynamic>>(
                        textFieldConfiguration: TextFieldConfiguration(
                            style: TextPalette.getBodyText(Palette.black),
                            decoration: CreateMatchState.getTextFormDecoration(
                                "Court Location"),
                            controller: textEditingController),
                        suggestionsCallback: (pattern) async {
                          List<Map<String, dynamic>> predictions = [];
                          if (pattern.isNotEmpty) {
                            var result = await SportCentersController
                                .getPlacePrediction(pattern);
                            predictions = result;
                          }
                          return predictions;
                        },
                        itemBuilder: (context, suggestion) {
                          var description = suggestion["description"];
                          var matchedSubstrings =
                          suggestion["matched_substrings"];
                          // matchedSubstrings[0]["length"]
                          // matchedSubstrings[0]["offset"]
                          // todo get match bold

                          return ListTile(
                            leading: Icon(Icons.place),
                            title: RichText(
                              text: TextSpan(
                              style: TextPalette.bodyText,
                              children: <TextSpan>[
                                TextSpan(text: description),
                            ],)
                          ));
                        },
                        noItemsFoundBuilder: (value) => Container(height: 10),
                        onSuggestionSelected: (suggestion) async {
                          textEditingController.text =
                              suggestion["description"] ?? "";
                          setState(() {
                            placeId = suggestion["place_id"];
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
                        String? surface = await ModalBottomSheet.showNutmegModalBottomSheet(
                            context,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Surface",
                                  style: TextPalette.h2,
                                ),
                                SizedBox(height: 16.0),
                                SurfaceRow(title: "Indoor",
                                    description: "Boots without studs",
                                    imagePath: "assets/sportcenters/indoor_thumb.png"),
                                SizedBox(height: 16.0),
                                SurfaceRow(title: "Grass",
                                    description: "For boots that require studs",
                                    imagePath: "assets/sportcenters/grass_thumb.png"),
                              ],
                            ));

                        if (surface != null) {
                          surfaceController.text = surface;
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
              child: GenericButtonWithLoaderAndErrorHandling("CREATE NEW COURT",
                  (_) async {
                bool? v = _formKey.currentState?.validate();
                if (v != null && v) {
                  Map<String, dynamic> placeInfo = await SportCentersController
                      .getPlaceDetails(placeId!);

                  var sportCenter = SportCenter(placeId!,
                      placeInfo["formatted_address"],
                      placeInfo["name"],
                      placeInfo["geometry"]["location"]["lat"],
                      placeInfo["geometry"]["location"]["lng"],
                      surfaceController.text,
                      changeRoomsAvailable,
                      sizeController.text);

                  widget.userSportCentersState.addSportCenter(
                      context.read<UserState>().getLoggedUserDetails()!.documentId,
                      sportCenter);

                  Navigator.of(context).pop();
                }
              }, Primary()),
            )
          ]),
        )),
      ),
    );
  }
}

class SurfaceRow extends StatelessWidget {

  final String title;
  final String description;
  final String imagePath;

  const SurfaceRow({Key? key, required this.title,
    required this.description, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(title),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10), // Image border
            child: SizedBox.fromSize(
              size: Size.fromRadius(30), // Image radius
              child: Image.asset(imagePath),
            ),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextPalette.h3,),
              SizedBox(height: 8),
              Text(description,
                style: TextPalette.bodyText,)
            ],
          )
        ],),
    );
  }
}