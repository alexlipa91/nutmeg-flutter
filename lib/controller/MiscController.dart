import 'package:nutmeg/db/MiscFirestore.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';


class MiscController {

  static Future<void> getGifs(LoadOnceState loadOnceState) async {
    var gifs = await MiscFirestore.getDocument("gif_joined_match");
    loadOnceState.setJoinedGifs(List<String>.from(gifs["links"]));
  }
}
