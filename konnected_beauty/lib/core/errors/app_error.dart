/// Domain error type used across services, blocs, and UI.
///
/// Always carry a safe [userMessage] for display and optional [debugMessage]
/// for internal logging. Never show [debugMessage] or [originalError] in UI.
class AppError implements Exception {
  final String code;
  final String userMessage;
  final String? debugMessage;
  final int? statusCode;
  final Object? originalError;
  final StackTrace? stackTrace;
  final bool isRetryable;
  final bool isAuthExpired;
  final bool isOffline;

  const AppError({
    required this.code,
    required this.userMessage,
    this.debugMessage,
    this.statusCode,
    this.originalError,
    this.stackTrace,
    this.isRetryable = false,
    this.isAuthExpired = false,
    this.isOffline = false,
  });

  /// Standard API failure envelope consumed by legacy `Map` callers.
  Map<String, dynamic> toApiMap({dynamic data}) => {
        'success': false,
        'message': userMessage,
        'code': code,
        if (statusCode != null) 'statusCode': statusCode,
        if (isOffline) 'offline': true,
        if (isAuthExpired) 'authExpired': true,
        if (isRetryable) 'retryable': true,
        if (data != null) 'data': data,
      };

  AppError copyWith({
    String? code,
    String? userMessage,
    String? debugMessage,
    int? statusCode,
    Object? originalError,
    StackTrace? stackTrace,
    bool? isRetryable,
    bool? isAuthExpired,
    bool? isOffline,
  }) {
    return AppError(
      code: code ?? this.code,
      userMessage: userMessage ?? this.userMessage,
      debugMessage: debugMessage ?? this.debugMessage,
      statusCode: statusCode ?? this.statusCode,
      originalError: originalError ?? this.originalError,
      stackTrace: stackTrace ?? this.stackTrace,
      isRetryable: isRetryable ?? this.isRetryable,
      isAuthExpired: isAuthExpired ?? this.isAuthExpired,
      isOffline: isOffline ?? this.isOffline,
    );
  }

  @override
  String toString() =>
      'AppError(code: $code, userMessage: $userMessage, statusCode: $statusCode)';
}

/// Typed wrapper for service-layer results (success or [AppError]).
class ApiResult<T> {
  final bool success;
  final T? data;
  final AppError? error;
  final int? statusCode;

  const ApiResult._({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResult.ok(T data, {int? statusCode}) => ApiResult._(
        success: true,
        data: data,
        statusCode: statusCode,
      );

  factory ApiResult.fail(AppError error) => ApiResult._(
        success: false,
        error: error,
        statusCode: error.statusCode,
      );

  String get userMessage => error?.userMessage ?? 'Something went wrong.';

  Map<String, dynamic> toLegacyMap({dynamic dataOverride}) {
    if (success) {
      return {
        'success': true,
        'message': 'success',
        'data': dataOverride ?? data,
        if (statusCode != null) 'statusCode': statusCode,
      };
    }
    return error!.toApiMap(data: dataOverride);
  }
}
