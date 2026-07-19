/// Stable machine-readable error codes returned by [AppError.toApiMap].
abstract final class ErrorCodes {
  static const String unknown = 'UNKNOWN_ERROR';
  static const String network = 'NETWORK_ERROR';
  static const String offline = 'OFFLINE_ERROR';
  static const String timeout = 'TIMEOUT_ERROR';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String forbidden = 'FORBIDDEN';
  static const String validation = 'VALIDATION_ERROR';
  static const String api = 'API_ERROR';
  static const String parse = 'PARSE_ERROR';
  static const String notFound = 'NOT_FOUND';
  static const String server = 'SERVER_ERROR';
  static const String cancelled = 'CANCELLED';
}
