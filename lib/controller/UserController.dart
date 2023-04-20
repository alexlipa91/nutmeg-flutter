import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/CloudFunctionsUtils.dart';
import '../model/UserDetails.dart';
import '../screens/PlayerOfTheMatch.dart';
import '../state/UserState.dart';
import '../utils/UiUtils.dart';

class UserController {
  static var apiClient = CloudFunctionsClient();

  static Future<void> editUser(BuildContext context, UserDetails u) async {
    await apiClient
        .callFunction("edit_user", {"id": u.documentId, "data": u.toJson()});
    context.read<UserState>().setUserDetail(u);
  }

  static Future<void> updloadPicture(
      BuildContext context, UserDetails userDetails) async {
    var original = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (original == null) return;
    File? croppedFile = await ImageCropper().cropImage(
        maxHeight: 512,
        maxWidth: 512,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        sourcePath: original.path,
        aspectRatioPresets: [CropAspectRatioPreset.square],
        androidUiSettings: AndroidUiSettings(
            toolbarColor: Palette.primary,
            toolbarWidgetColor: Palette.greyLight,
            initAspectRatio: CropAspectRatioPreset.original,
            activeControlsWidgetColor: Palette.primary,
            lockAspectRatio: true),
        iosUiSettings: IOSUiSettings(
          minimumAspectRatio: 1.0,
        ));
    if (croppedFile == null) return;
    var uploaded = await FirebaseStorage.instance
        .ref("users/" + userDetails.documentId)
        .putFile(croppedFile);

    await context.read<UserState>()
        .editUser({"image": await uploaded.ref.getDownloadURL()});
  }

  static Future<void> showPotmIfNotSeen(BuildContext context,
      String matchId, String userId) async {
    var prefs = await SharedPreferences.getInstance();
    var preferencePath = "potm_screen_showed_" + matchId + "_" + userId;
    var seen = prefs.getBool(preferencePath) ?? false;

    if (!seen) {
      await Navigator.push(context,
          MaterialPageRoute(builder: (context) => PlayerOfTheMatch()));
      prefs.setBool(preferencePath, true);
    }
  }
}

