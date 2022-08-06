import 'package:nutmeg/db/MiscFirestore.dart';
import 'package:version/version.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../state/LoadOnceState.dart';


class MiscController {

  // get 3 gifs and preload them
  static Future<void> getGifs(LoadOnceState loadOnceState) async {
    var gifs = await MiscFirestore.getDocument("gif_joined_match");
    var urls = List<String>.from(gifs!["links"]);
    urls.shuffle();

    var urlsSublist = urls.sublist(0, 3);

    var urlsFuture = urlsSublist.map((u) =>
        DefaultCacheManager().downloadFile(u).then((u) {}));

    Future.wait(urlsFuture);
    loadOnceState.joinedGifs = urlsSublist;
  }

  static Future<Version?> getMinimumVersion() async {
    var doc = await MiscFirestore.getDocument("startup_checks");
    if (doc == null)
      return null;

    var parts = doc["minimum_version"]?.split(".");
    return Version(int.parse(parts[0]), int.parse(parts[1]),
        int.parse(parts[2]));
  }
}
