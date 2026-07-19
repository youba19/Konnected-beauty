import 'package:flutter/foundation.dart';

/// Central place for environment-aware behavior.
///
/// Production builds hide technical details from users while still logging
/// internally. Development / debug builds emit full console output.
class AppEnvironment {
  AppEnvironment._();

  static bool get isProduction => kReleaseMode;

  static bool get isDevelopment => !kReleaseMode;

  /// Verbose logs (stack traces, raw responses) are allowed in development only.
  static bool get verboseLogging => isDevelopment;
}
