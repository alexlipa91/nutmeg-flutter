import 'package:nutmeg/db/SportsFirestore.dart';
import '../state/LoadOnceState.dart';


class SportsController {

  static Future<void> refreshAll(LoadOnceState loadOnceState) async {
    var sports = await SportsDb.getSports();
    loadOnceState.setSports(sports);
  }
}
