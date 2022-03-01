import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:nutmeg/db/SportCentersFirestore.dart';
import 'package:provider/provider.dart';

import '../model/SportCenter.dart';
import '../state/LoadOnceState.dart';


class SportCentersController {

  static Future<List<SportCenter>> refreshAll(BuildContext context) async {
    var sportCentersState = context.read<LoadOnceState>();

    var sportCenters = await SportCentersFirestore.getSportCenters();

    var futures = sportCenters.map((s) async {
      s.thumbnailUrl = await getSportCenterThumbnailUrl(s.placeId);
      s.imagesUrls = await getSportCenterPicturesUrls(s.placeId);
    });
    await Future.wait(futures);

    sportCentersState.setSportCenters(sportCenters);
    return sportCenters;
  }

  static Future<List<String>> getSportCenterPicturesUrls(String sportCenterId) async {
    // it loads all pictures from the sportcenter in folder sportcenters/<sportcenter_id>/large
    // if no <sportcenter_id> subfolder it uses "default"

    var mainFolderRef = await FirebaseStorage.instance.ref("sportcenters").listAll();
    var listOfFolders = mainFolderRef.prefixes;

    var folder;
    if (listOfFolders.where((ref) => ref.name == sportCenterId).isEmpty) {
      folder = "default";
    } else {
      folder = sportCenterId;
    }

    var allRefs = await FirebaseStorage.instance
        .ref("sportcenters/" + folder + "/large")
        .listAll();
    var urls = await Future.wait(allRefs.items.map((e) => e.getDownloadURL()));
    return urls;
  }

  static Future<String> getSportCenterThumbnailUrl(String sportCenterId) async {
    // it loads the thumbnail picture from the sportcenter at sportcenters/<sportcenter_id>/thumbnail.png
    // if no <sportcenter_id> subfolder it uses "default"

    var listOfFiles =
    await FirebaseStorage.instance.ref("sportcenters/").listAll();

    var file;
    if (listOfFiles.prefixes
        .where((ref) => ref.name == sportCenterId)
        .isEmpty) {
      file = "sportcenters/default/thumbnail.png";
    } else {
      file = "sportcenters/" + sportCenterId + "/thumbnail.png";
    }

    var url = await FirebaseStorage.instance.ref(file).getDownloadURL();
    return url;
  }
}
