import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Build-time and environment configuration.
///
/// Flags that are only enabled when explicitly passed via --dart-define
/// are always false in production (release builds never pass these).
class AppConfig {
  AppConfig._();

  /// When true, the current user is treated as the match organizer (for testing).
  /// Only enabled if built with: --dart-define=TEST_MODE_ORGANIZER=true
  /// Production builds do not pass this, so it is always false in prod.
  static const bool testModeOrganizer =
      bool.fromEnvironment('TEST_MODE_ORGANIZER', defaultValue: false);

  /// When true, test matches are fetched and shown alongside production matches.
  /// Override with: --dart-define=TEST_MODE=true
  static const bool testMode =
      bool.fromEnvironment('TEST_MODE', defaultValue: false);

  /// Custom auth token for debugging (sign in as another user).
  /// Set via: INJECT_AUTH_TOKEN_UID=<uid> ./scripts/start_app_web.sh
  static const String injectAuthToken =
      String.fromEnvironment('INJECT_AUTH_TOKEN', defaultValue: '');

  /// Backend URL. Override with: --dart-define=BACKEND_URL=http://localhost:8080
  static const String backendUrl = String.fromEnvironment('BACKEND_URL',
      defaultValue: 'https://nutmeg-9099c.ew.r.appspot.com');

  /// Google Places API key. Set via: --dart-define=GOOGLE_API_KEY=...
  static const String googleApiKey = String.fromEnvironment('GOOGLE_API_KEY');

  /// Firebase VAPID key for web push notifications.
  /// Set via: --dart-define=FIREBASE_VAPID_KEY=...
  static const String firebaseVapidKey =
      String.fromEnvironment('FIREBASE_VAPID_KEY');
}

class ConfigsUtils {
  ConfigsUtils._();

  static bool get allowUsersToMarkPayments =>
      FirebaseRemoteConfig.instance.getBool("allow_users_to_mark_payments");

  /// Override with: --dart-define=ALLOW_NUTMEG_MANAGED_PAYMENTS=true
  static const bool _allowNutmegManagedPaymentsOverride =
      bool.fromEnvironment('ALLOW_NUTMEG_MANAGED_PAYMENTS');

  static bool get allowNutmegManagedPayments =>
      _allowNutmegManagedPaymentsOverride ||
      FirebaseRemoteConfig.instance.getBool("allow_nutmeg_managed_payments");
}
