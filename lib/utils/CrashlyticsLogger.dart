import 'package:logging/logging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CrashlyticsLogger {
  final Logger _logger;
  final String _name;

  CrashlyticsLogger(String name) : _logger = Logger(name), _name = name;

  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.info('[$_name] $message');    
  }

  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.warning('[$_name] $message');    
  }

  void severe(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.severe('[$_name] $message', error, stackTrace);
    _logToCrashlytics(message, error, stackTrace, level: 'SEVERE');
  }

  void _logToCrashlytics(String message, Object? error, StackTrace? stackTrace, {required String level}) {
    if (!kIsWeb) { // Crashlytics is not supported on web
      FirebaseCrashlytics.instance.log('[$level][$_name] $message');
      if (error != null) {
        FirebaseCrashlytics.instance.recordError(error, stackTrace ?? StackTrace.current, reason: '[$_name] $message');
      }
    }
  }
}