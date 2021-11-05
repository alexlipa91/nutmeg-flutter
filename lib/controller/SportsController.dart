import 'package:nutmeg/db/SportCentersFirestore.dart';
import 'package:nutmeg/db/SportsFirestore.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';


class SportsController {

  static Future<void> refreshAll(LoadOnceState loadOnceState) async {
    var sports = await SportsDb.getSports();
    loadOnceState.setSports(sports);
  }
}
