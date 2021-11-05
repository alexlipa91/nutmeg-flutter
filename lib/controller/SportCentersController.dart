import 'package:nutmeg/db/SportCentersFirestore.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';


class SportCentersController {

  static Future<void> refreshAll(LoadOnceState sportCentersState) async {
    var sportCenters = await SportCentersFirestore.getSportCenters();
    sportCentersState.setSportCenters(sportCenters);
  }
}
