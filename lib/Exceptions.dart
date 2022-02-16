import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:nutmeg/utils/InfoModals.dart';

class ErrorHandlingUtils {
  static Future<void> handleError(
      Exception e, StackTrace stackTrace, BuildContext context) {
    print(e);
    print(stackTrace);

    switch (e.runtimeType) {
      case OutdatedAppException:
        return GenericInfoModal(
                title: "Outdated app version!",
                body: "Please update the app from the store before continuing.")
            .show(context)
            .then((value) =>
                SystemChannels.platform.invokeMethod('SystemNavigator.pop'));
      default:
        return GenericInfoModal(
                title: "Something went wrong!",
                body: "Please contact us for support.")
            .show(context);
    }
  }
}

class OutdatedAppException implements Exception {}
