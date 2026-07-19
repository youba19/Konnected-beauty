import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'app_error.dart';
import 'error_codes.dart';
import 'error_sanitizer.dart';

/// Maps raw failures (exceptions, HTTP responses, legacy maps) to [AppError].
class ErrorMapper {
  ErrorMapper._();

  // ---------------------------------------------------------------------------
  // Network classification (single source of truth)
  // ---------------------------------------------------------------------------

  static bool isTransientNetworkError(Object error) {
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    if (error is http.ClientException) return true;
    if (error is HandshakeException) return true;
    final s = error.toString().toLowerCase();
    return ErrorSanitizer.looksLikeNetworkIssue(s) ||
        s.contains('socketexception') ||
        s.contains('errno = 51') ||
        s.contains('errno = 50');
  }

  static bool isTimeoutError(Object error) {
    if (error is TimeoutException) return true;
    final s = error.toString().toLowerCase();
    return s.contains('timed out') || s.contains('timeout');
  }

  // ---------------------------------------------------------------------------
  // Exception → AppError
  // ---------------------------------------------------------------------------

  static AppError fromException(
    Object error, [
    StackTrace? stackTrace,
    String? context,
  ]) {
    if (error is AppError) return error;

    if (error is TimeoutException) {
      return AppError(
        code: ErrorCodes.timeout,
        userMessage: 'The request took too long. Please try again.',
        debugMessage: _debug('Timeout', error, context),
        originalError: error,
        stackTrace: stackTrace,
        isRetryable: true,
      );
    }

    if (isTransientNetworkError(error)) {
      return AppError(
        code: ErrorCodes.offline,
        userMessage: 'Check your internet connection and try again.',
        debugMessage: _debug('Network', error, context),
        originalError: error,
        stackTrace: stackTrace,
        isRetryable: true,
        isOffline: true,
      );
    }

    if (error is FormatException) {
      return AppError(
        code: ErrorCodes.parse,
        userMessage: 'Something went wrong. Please try again.',
        debugMessage: _debug('Parse', error, context),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return AppError(
      code: ErrorCodes.unknown,
      userMessage: 'Something went wrong. Please try again later.',
      debugMessage: _debug('Unknown', error, context),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static String userMessageFrom(Object error, [StackTrace? stackTrace]) =>
      fromException(error, stackTrace).userMessage;

  // ---------------------------------------------------------------------------
  // HTTP response → AppError
  // ---------------------------------------------------------------------------

  static AppError fromHttpResponse(
    http.Response response, {
    String? context,
  }) {
    final status = response.statusCode;
    String? apiMessage;
    String? apiCode;

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        apiMessage = _extractMessage(body);
        apiCode = body['code']?.toString() ?? body['error']?.toString();
      }
    } catch (_) {
      // Body is not JSON — ignore for user messaging.
    }

    if (status == 401) {
      return AppError(
        code: ErrorCodes.unauthorized,
        userMessage: 'Session expired. Please log in again.',
        debugMessage: _debug('HTTP $status', apiMessage ?? response.body, context),
        statusCode: status,
        isAuthExpired: true,
      );
    }

    if (status == 403) {
      return AppError(
        code: ErrorCodes.forbidden,
        userMessage: 'You do not have permission to perform this action.',
        debugMessage: _debug('HTTP $status', apiMessage ?? response.body, context),
        statusCode: status,
      );
    }

    if (status == 404) {
      return AppError(
        code: ErrorCodes.notFound,
        userMessage: 'The requested resource was not found.',
        debugMessage: _debug('HTTP $status', apiMessage ?? response.body, context),
        statusCode: status,
      );
    }

    if (status == 422 || status == 400) {
      return AppError(
        code: ErrorCodes.validation,
        userMessage: ErrorSanitizer.fromApiMessage(
          apiMessage,
          fallback: 'Please check your input and try again.',
        ),
        debugMessage: _debug('HTTP $status', apiMessage ?? response.body, context),
        statusCode: status,
      );
    }

    if (status >= 500) {
      return AppError(
        code: ErrorCodes.server,
        userMessage: 'Something went wrong on our side. Please try again later.',
        debugMessage: _debug('HTTP $status', apiMessage ?? response.body, context),
        statusCode: status,
        isRetryable: true,
      );
    }

    return AppError(
      code: apiCode ?? ErrorCodes.api,
      userMessage: ErrorSanitizer.fromApiMessage(
        apiMessage,
        fallback: 'Something went wrong. Please try again.',
      ),
      debugMessage: _debug('HTTP $status', apiMessage ?? response.body, context),
      statusCode: status,
      isRetryable: status >= 500 || status == 408 || status == 429,
    );
  }

  // ---------------------------------------------------------------------------
  // Legacy service map → AppError
  // ---------------------------------------------------------------------------

  static AppError fromApiMap(Map<String, dynamic> map) {
    if (map['success'] == true) {
      return const AppError(
        code: 'SUCCESS',
        userMessage: 'success',
      );
    }

    final statusCode = map['statusCode'] is int
        ? map['statusCode'] as int
        : int.tryParse(map['statusCode']?.toString() ?? '');

    final rawMessage = map['message']?.toString();
    final code = map['code']?.toString() ??
        map['error']?.toString() ??
        ErrorCodes.api;

    if (map['offline'] == true || map['isOffline'] == true) {
      return AppError(
        code: ErrorCodes.offline,
        userMessage: 'Check your internet connection and try again.',
        debugMessage: rawMessage,
        statusCode: statusCode,
        isOffline: true,
        isRetryable: true,
      );
    }

    if (map['authExpired'] == true || statusCode == 401) {
      return AppError(
        code: ErrorCodes.unauthorized,
        userMessage: 'Session expired. Please log in again.',
        debugMessage: rawMessage,
        statusCode: statusCode,
        isAuthExpired: true,
      );
    }

    if (statusCode == 403) {
      return AppError(
        code: ErrorCodes.forbidden,
        userMessage: 'You do not have permission to perform this action.',
        debugMessage: rawMessage,
        statusCode: statusCode,
      );
    }

    if (statusCode == 422 || statusCode == 400) {
      return AppError(
        code: ErrorCodes.validation,
        userMessage: ErrorSanitizer.fromApiMessage(
          rawMessage,
          fallback: 'Please check your input and try again.',
        ),
        debugMessage: rawMessage,
        statusCode: statusCode,
      );
    }

    return AppError(
      code: code,
      userMessage: ErrorSanitizer.fromApiMessage(rawMessage),
      debugMessage: rawMessage,
      statusCode: statusCode,
      isRetryable: map['retryable'] == true,
    );
  }

  static String? _extractMessage(Map<String, dynamic> body) {
    final m = body['message'] ?? body['messgae']; // Stripe typo compatibility
    if (m == null) return null;
    if (m is List) return m.join(', ');
    return m.toString();
  }

  static String _debug(String kind, Object detail, String? context) {
    final prefix = context != null ? '[$context] ' : '';
    return '$prefix$kind: $detail';
  }
}
