import 'package:nutmeg/db/SportsFirestore.dart';
import '../model/Sport.dart';
import '../state/LoadOnceState.dart';


class SportsController {

  static Future<List<Sport>> refreshAll(LoadOnceState loadOnceState) async {
    var sports = await SportsDb.getSports();
    loadOnceState.setSports(sports);
    return sports;
  }
}
