import 'package:logging/logging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CrashlyticsLogger {
  final Logger _logger;

  CrashlyticsLogger(String name) : _logger = Logger(name);

  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.info(message);    
  }

  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.warning(message);    
  }

  void severe(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.severe(message, error, stackTrace);
    _logToCrashlytics(message, error, stackTrace, level: 'SEVERE');
  }

  void _logToCrashlytics(String message, Object? error, StackTrace? stackTrace, {required String level}) {
    if (!kIsWeb) { // Crashlytics is not supported on web
      FirebaseCrashlytics.instance.log('[$level] $message');
      if (error != null) {
        FirebaseCrashlytics.instance.recordError(error, stackTrace ?? StackTrace.current, reason: message);
      }
    }
  }
}