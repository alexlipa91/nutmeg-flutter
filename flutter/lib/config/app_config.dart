import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Build-time test mode. Override with: --dart-define=TEST_MODE=true
  static const bool _buildTimeTestMode =
      bool.fromEnvironment('TEST_MODE', defaultValue: false);

  /// Runtime override enabled via hidden UI actions (e.g. debug tap gesture).
  static bool _runtimeTestMode = false;
  static const String _runtimeTestModePrefKey = "runtime_test_mode_enabled";

  /// When true, test matches are fetched and shown alongside production matches.
  /// This is true when either build-time TEST_MODE is set or runtime override is enabled.
  static bool get testMode => _buildTimeTestMode || _runtimeTestMode;
  static bool get runtimeTestMode => _runtimeTestMode;

  static void setRuntimeTestMode(bool enabled) {
    _runtimeTestMode = enabled;
  }

  static Future<void> setRuntimeTestModePersisted(bool enabled) async {
    _runtimeTestMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_runtimeTestModePrefKey, enabled);
  }

  static Future<void> loadRuntimeOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    _runtimeTestMode = prefs.getBool(_runtimeTestModePrefKey) ?? false;
  }

  /// Custom auth token for debugging (sign in as another user).
  /// Set via: INJECT_AUTH_TOKEN=<uid> ./scripts/start_app_web.sh
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

  /// Log level. Override with: --dart-define=LOG_LEVEL=ALL
  /// Valid values: ALL, FINEST, FINER, FINE, CONFIG, INFO, WARNING, SEVERE, OFF
  static const String logLevel =
      String.fromEnvironment('LOG_LEVEL', defaultValue: 'WARNING');

  /// Git commit SHA injected at build time.
  static const String commitSha =
      String.fromEnvironment('COMMIT_SHA', defaultValue: '');

  /// Git commit timestamp (Unix epoch seconds) injected at build time.
  static const String commitTimestampEpoch =
      String.fromEnvironment('COMMIT_TIMESTAMP', defaultValue: '');

  /// Parsed UTC commit timestamp, or null when not available/invalid.
  static DateTime? get commitTimestampUtc {
    if (commitTimestampEpoch.isEmpty) return null;
    final epochSeconds = int.tryParse(commitTimestampEpoch);
    if (epochSeconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000, isUtc: true);
  }

  /// Nutmeg platform fee in cents charged per player per match.
  static const int nutmegFeeCents = 50;

  /// Nutmeg fee formatted as a currency amount (euros).
  static double get nutmegFeeEuros => nutmegFeeCents / 100;
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
