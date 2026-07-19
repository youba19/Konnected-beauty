/// Strips technical details before anything reaches the UI.
///
/// Used by [ErrorMapper] and [TopNotificationService] so there is a single
/// sanitization path for user-visible strings.
class ErrorSanitizer {
  ErrorSanitizer._();

  static const int maxUserMessageLength = 200;

  static const _technicalHints = [
    'clientexception',
    'socketexception',
    'httpexception',
    'formatexception',
    'platformexception',
    'dart:',
    'package:',
    'stack trace',
    'stacktrace',
    '#0      ',
    '#1      ',
    'failed assertion',
    'uri=http',
    'uri: http',
    'os error',
    'errno =',
    'connection failed',
    'handshakeexception',
    'tlsexception',
    'certificateexception',
    'sql',
    'sqlite',
    'postgres',
    'mysql',
    'sequelize',
    'prisma',
    'mongodb',
    'syntax error',
    'internal server error',
    'bearer ',
    'access_token',
    'refresh_token',
    '/api/',
    '/v1/',
    'ngrok',
    'exception:',
    'error:',
    'type \'',
    'subtype of',
    'null check operator',
    'rangeerror',
    'stateerror',
    'nosuchmethoderror',
    'unimplementederror',
    'unsupported operation',
  ];

  static const _networkHints = [
    'network is unreachable',
    'network unreachable',
    'failed host lookup',
    'no address associated',
    'connection refused',
    'connection reset',
    'connection timed out',
    'timed out',
    'connection closed',
    'host lookup failed',
    'software caused connection abort',
    'network unavailable',
    'no internet',
  ];

  static bool looksTechnical(String message) {
    final lower = message.toLowerCase();
    return _technicalHints.any(lower.contains);
  }

  static bool looksLikeNetworkIssue(String message) {
    final lower = message.toLowerCase();
    return _networkHints.any(lower.contains);
  }

  /// Returns a safe, short message suitable for banners, snackbars, and dialogs.
  static String forUser(
    String? raw, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    final t = (raw ?? '').trim();
    if (t.isEmpty) return fallback;

    if (looksTechnical(t) || looksLikeNetworkIssue(t)) {
      if (looksLikeNetworkIssue(t)) {
        return 'Check your internet connection and try again.';
      }
      return fallback;
    }

    if (t.length > maxUserMessageLength) {
      return '${t.substring(0, maxUserMessageLength - 1).trimRight()}…';
    }
    return t;
  }

  /// Prefer API-provided message when it is already user-safe.
  static String fromApiMessage(
    dynamic message, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    if (message == null) return fallback;
    if (message is List) {
      return forUser(message.join(', '), fallback: fallback);
    }
    return forUser(message.toString(), fallback: fallback);
  }
}
