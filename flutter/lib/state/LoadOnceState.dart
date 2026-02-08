import 'package:universal_io/io.dart';
import 'package:flutter/cupertino.dart';

import '../api/CloudFunctionsUtils.dart';
import '../model/SportCenter.dart';


class LoadOnceState extends ChangeNotifier {

  static String localeStr = const String.fromEnvironment("LOCALE", defaultValue: "");

  Locale locale = Locale((localeStr == "") ? Platform.localeName.substring(0, 2) : localeStr);
  
  late List<String> joinedGifs;
  List<SportCenter>? savedSportCenters;

  String getRandomGif() {
    joinedGifs..shuffle();
    return joinedGifs.first;
  }

  Future<List<SportCenter>> fetchSavedSportCenters() async {
    Map<String, dynamic> data = await CloudFunctionsClient()
        .get("sportcenters") ?? {};

    savedSportCenters = data.entries.map((e) => SportCenter
        .fromJson(Map<String, dynamic>.from(e.value), e.key))
        .toList();
    return savedSportCenters!;
  }
}
