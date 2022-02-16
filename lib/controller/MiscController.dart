import 'package:nutmeg/db/MiscFirestore.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:version/version.dart';


class MiscController {

  static Future<void> getGifs(LoadOnceState loadOnceState) async {
    var gifs = await MiscFirestore.getDocument("gif_joined_match");
    loadOnceState.setJoinedGifs(List<String>.from(gifs["links"]));
  }

  static Future<Version> getMinimumVersion() async {
    var doc = await MiscFirestore.getDocument("startup_checks");
    var parts = doc["minimum_version"].split(".");
    return Version(int.parse(parts[0]), int.parse(parts[1]),
        int.parse(parts[2]));
  }
}
