import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:nutmeg/utils/InfoModals.dart';


class ErrorHandlingUtils {
  static Future<void> handleError(
      Exception e, StackTrace stackTrace, BuildContext context) {
    print("handling error: " + e.toString());
    print(stackTrace);
    FirebaseCrashlytics.instance.recordError(e, stackTrace);

    switch (e.runtimeType) {
      case OutdatedAppException:
        return GenericInfoModal(
                title: "Outdated app version!",
                description: "Please update the app from the store before continuing.")
            .show(context)
            .then((value) =>
                SystemChannels.platform.invokeMethod('SystemNavigator.pop'));
      default:
        return GenericInfoModal(
                title: "Something went wrong!",
                description: "Please contact us for support.")
            .show(context);
    }
  }
}

class OutdatedAppException implements Exception {}
