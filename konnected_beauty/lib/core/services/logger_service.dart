import '../config/app_environment.dart';

/// Internal logging only — never pass output directly to the UI.
class LoggerService {
  LoggerService._();

  static void debug(String message) {
    if (AppEnvironment.verboseLogging) {
      // ignore: avoid_print
      print('🐛 $message');
    }
  }

  static void info(String message) {
    if (AppEnvironment.verboseLogging) {
      // ignore: avoid_print
      print('ℹ️ $message');
    }
  }

  static void warning(String message, {Object? error}) {
    if (AppEnvironment.verboseLogging) {
      // ignore: avoid_print
      print('⚠️ $message${error != null ? ': $error' : ''}');
    }
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (AppEnvironment.isProduction) {
      // Production: concise log without full stack unless explicitly provided.
      // ignore: avoid_print
      print('❌ $message${error != null ? ' (${error.runtimeType})' : ''}');
      return;
    }

    // ignore: avoid_print
    print('❌ $message');
    if (error != null) {
      // ignore: avoid_print
      print('   error: $error');
    }
    if (stackTrace != null) {
      // ignore: avoid_print
      print('   stack: $stackTrace');
    }
  }

  static void api({
    required String method,
    required String endpoint,
    int? statusCode,
    String? note,
  }) {
    if (!AppEnvironment.verboseLogging) return;
    final status = statusCode != null ? ' → $statusCode' : '';
    final extra = note != null ? ' ($note)' : '';
    // ignore: avoid_print
    print('🌐 $method $endpoint$status$extra');
  }
}
