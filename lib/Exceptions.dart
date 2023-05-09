import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:nutmeg/utils/InfoModals.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class ErrorHandlingUtils {
  static Future<void> handleError(
      dynamic e, StackTrace stackTrace, BuildContext context) {
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
                title: AppLocalizations.of(context)!.genericErrorMessage,
                description: AppLocalizations.of(context)!.genericErrorDesc)
            .show(context);
    }
  }
}

class OutdatedAppException implements Exception {}
