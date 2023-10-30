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

class UserController {
  static var apiClient = CloudFunctionsClient();

  static Future<void> updloadPicture(
      BuildContext context, UserDetails userDetails) async {
    var original = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (original == null) return;
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: original.path,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
      ],
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(
          title: 'Cropper',
        ),
        WebUiSettings(
          context: context,
        ),
      ],
    );
    if (croppedFile == null) return;
    var uploaded = await FirebaseStorage.instance
        .ref("users/" + userDetails.documentId)
        .putFile(File(croppedFile.path));

    await context
        .read<UserState>()
        .editUser({"image": await uploaded.ref.getDownloadURL()});
  }

  static Future<void> showPotmIfNotSeen(
      BuildContext context, String matchId, String userId) async {
    var prefs = await SharedPreferences.getInstance();
    var preferencePath = "potm_screen_showed_" + matchId + "_" + userId;
    var seen = prefs.getBool(preferencePath) ?? false;

    if (!seen) {
      await Navigator.push(
          context, MaterialPageRoute(builder: (context) => PlayerOfTheMatch()));
      prefs.setBool(preferencePath, true);
    }
  }
}
