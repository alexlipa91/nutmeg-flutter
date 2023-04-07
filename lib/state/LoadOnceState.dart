import 'package:universal_io/io.dart';
import 'package:flutter/cupertino.dart';


class LoadOnceState extends ChangeNotifier {
  static String localeStr = const String.fromEnvironment("LOCALE", defaultValue: "");

  Locale locale = Locale((localeStr == "") ? Platform.localeName : localeStr);
  
  late List<String> joinedGifs;

  String getRandomGif() {
    joinedGifs..shuffle();
    return joinedGifs.first;
  }

  void setLocale(String locale) {
    this.locale = Locale(locale);
    notifyListeners();
  }
}
