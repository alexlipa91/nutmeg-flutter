import 'package:flutter/cupertino.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:provider/provider.dart';

import '../model/SportCenter.dart';
import '../state/LoadOnceState.dart';


class SportCentersController {

  static Future<SportCenter> refresh(BuildContext context, String sportCenterId) async {
    var sportCentersState = context.read<LoadOnceState>();

    var data = await CloudFunctionsClient().callFunction("get_sportcenter",
        {"id" : sportCenterId});

    var sportCenter = SportCenter.fromJson(data, sportCenterId);
    sportCentersState.setSportCenter(sportCenterId, sportCenter);

    return sportCenter;
  }
}
