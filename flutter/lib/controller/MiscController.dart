import 'package:nutmeg/db/MiscFirestore.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../state/LoadOnceState.dart';

final logger = CrashlyticsLogger('MiscController');

class MiscController {
  // get 3 gifs and preload them
  static Future<void> getGifs(LoadOnceState loadOnceState) async {
    try {
      var gifs = await MiscFirestore.getDocument("gif_joined_match");
      var links = gifs?["links"];
      if (links == null) return;

      var urls = List<String>.from(links);
      urls.shuffle();

      var urlsSublist = urls.sublist(0, urls.length.clamp(0, 7));
      await Future.wait(
        urlsSublist.map((u) => DefaultCacheManager().downloadFile(u)),
      );
      loadOnceState.joinedGifs = urlsSublist;
    } catch (e) {
      logger.warning("Failed to load gifs", e);
    }
  }
}
