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
}
