import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/PageTemplate.dart';
import 'package:nutmeg/widgets/Section.dart';
import 'package:provider/provider.dart';
import 'package:nutmeg/l10n/app_localizations.dart';

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
  static const int _minImageWidth = 600;
  static const int _minImageHeight = 300;
  static const double _minImageAspectRatio = 1.6;
  static const double _maxImageAspectRatio = 2.4;

  final TextEditingController surfaceController = TextEditingController();
  final TextEditingController textEditingController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool changeRoomsAvailable = false;

  String? address;
  String? name; 
  String? placeId;
  String? city;
  double? lat;
  double? lng;
  Uint8List? courtImageBytes;
  String? courtImageValidationError;

  Surface? surface = Surface.grass;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (surfaceController.text.isEmpty && surface != null) {
      surfaceController.text = surface!.getTitle(context);
    }
  }

  Future<void> _pickCourtImage() async {
    final XFile? original =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (original == null) return;

    final Uint8List bytes = await original.readAsBytes();
    final ui.Image decoded = await decodeImageFromList(bytes);
    final int width = decoded.width;
    final int height = decoded.height;
    final double ratio = width / height;
    decoded.dispose();

    if (width < _minImageWidth || height < _minImageHeight) {
      setState(() {
        courtImageValidationError = AppLocalizations.of(context)!
            .imageTooSmallError(_minImageWidth, _minImageHeight);
        courtImageBytes = null;
      });
      return;
    }

    if (ratio < _minImageAspectRatio || ratio > _maxImageAspectRatio) {
      setState(() {
        courtImageValidationError =
            AppLocalizations.of(context)!.invalidImageRatioError;
        courtImageBytes = null;
      });
      return;
    }

    setState(() {
      courtImageBytes = bytes;
      courtImageValidationError = null;
    });
  }

  Future<String?> _uploadCourtImageIfNeeded(String placeId) async {
    if (courtImageBytes == null) return null;

    final String objectPath =
        "sportcenters/custom/$placeId/cover_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final uploaded = await FirebaseStorage.instance
        .ref(objectPath)
        .putData(courtImageBytes!);
    return uploaded.ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: PageTemplate(
        refreshState: null,
        widgets: [
          Center(
            child: Container(
              width: 700,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.createNewCourtText,
                      style: TextPalette.h1Default),
                  Section(
                      title: AppLocalizations.of(context)!.pictureTitleText,
                      titleType: "big",
                      body: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.all(Radius.circular(15)),
                                child: courtImageBytes != null
                                    ? Image.memory(
                                        courtImageBytes!,
                                        width: double.infinity,
                                        height: 220,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        surface!.getImagePath(),
                                        width: double.infinity,
                                        height: 220,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: InkWell(
                                  onTap: _pickCourtImage,
                                  borderRadius: BorderRadius.circular(100),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Palette.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.photo_library_outlined,
                                      color: Palette.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (courtImageValidationError != null) ...[
                            SizedBox(height: 8),
                            Text(
                              courtImageValidationError!,
                              style: TextPalette.bodyText
                                  .copyWith(color: Palette.destructive),
                            ),
                          ],
                        ],
                      )),
                  Section(
                      title: AppLocalizations.of(context)!.informationTitleText,
                      titleType: "big",
                      body: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: TypeAheadField<PredictionResult>(
                                controller: textEditingController,
                                builder: (context, controller, focusNode) {
                                  return TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    style:
                                        TextPalette.getBodyText(Palette.black),
                                    decoration:
                                        CreateMatchState.getTextFormDecoration(
                                            AppLocalizations.of(context)!
                                                .courtLocationLabel),
                                  );
                                },
                                emptyBuilder: (context) => Container(height: 0),
                                suggestionsCallback: (pattern) async {
                                  List<PredictionResult> predictions = [];
                                  if (pattern.isNotEmpty) {
                                    var result =
                                        await getPlacePrediction(pattern);
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
                                    boldText = description.substring(
                                        0, firstMatch.length);
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
                                            TextSpan(
                                                text: boldText,
                                                style: TextPalette.bodyText
                                                    .copyWith(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                          TextSpan(text: normalText),
                                        ],
                                      )));
                                },
                                onSelected: (prediction) async {
                                  textEditingController.text =
                                      prediction.description;
                                  setState(() {
                                    placeId = prediction.placeId;
                                  });
                                },
                              ))
                            ],
                          )
                        ],
                      )),
                  Section(
                      title: AppLocalizations.of(context)!.typeTitleText,
                      titleType: "big",
                      body: Column(children: [
                        Row(
                          children: [
                            Expanded(
                                child: TextFormField(
                              readOnly: true,
                              controller: surfaceController,
                              decoration:
                                  CreateMatchState.getTextFormDecoration(
                                      AppLocalizations.of(context)!
                                          .surfaceLabelText,
                                      isDropdown: true),
                              onTap: () async {
                                Surface? surface = await ModalBottomSheet
                                    .showNutmegModalBottomSheet(
                                        context,
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppLocalizations.of(context)!
                                                  .surfaceLabelText,
                                              style: TextPalette.h2,
                                            ),
                                            SizedBox(height: 16.0),
                                            SurfaceRow(
                                              surface: Surface.indoor,
                                            ),
                                            SizedBox(height: 16.0),
                                            SurfaceRow(surface: Surface.grass),
                                          ],
                                        ));

                                if (surface != null) {
                                  surfaceController.text =
                                      surface.getTitle(context);
                                  setState(() {
                                    this.surface = surface;
                                  });
                                }
                              },
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return AppLocalizations.of(context)!
                                      .requiredError;
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
                                      AppLocalizations.of(context)!
                                          .changeRoomsAvailableLabel,
                                      style: TextPalette.bodyText,
                                      overflow: TextOverflow.visible)),
                            ],
                          ),
                        ],
                      )),
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
        bottomNavigationBar: GenericBottomBar(
            child: Padding(
          padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Expanded(
              child: Container(
                width: 700,
                child: GenericButtonWithLoaderAndErrorHandling(
                    AppLocalizations.of(context)!
                        .createNewCourtText
                        .toUpperCase(), (_) async {
                  bool? v = _formKey.currentState?.validate();
                  if (v != null && v) {
                    final String? uploadedImageUrl =
                        await _uploadCourtImageIfNeeded(placeId!);
                    await CloudFunctionsClient().post("/sportcenters/add", {
                      "place_id": placeId!,
                      "surface": surface!.getDbName(),
                      "hasChangingRooms": changeRoomsAvailable,
                      "courtType": "5v5",
                      if (uploadedImageUrl != null)
                        "thumbnailUrl": uploadedImageUrl,
                      if (uploadedImageUrl != null)
                        "largeImageUrls": [uploadedImageUrl],
                    });
                    await context
                        .read<UserState>()
                        .fetchLoggedUserSportCenters();
                    List<SportCenter> sportCenters =
                        context.read<UserState>().getSportCenters() ?? [];

                    var match = sportCenters
                        .where((s) => s.placeId == placeId!)
                        .firstOrNull;
                    Navigator.of(context).pop(match);
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
              Text(
                surface.getTitle(context),
                style: TextPalette.h3,
              ),
              SizedBox(height: 8),
              Text(
                surface.getDescription(context),
                style: TextPalette.bodyText,
              )
            ],
          )
        ],
      ),
    );
  }
}
