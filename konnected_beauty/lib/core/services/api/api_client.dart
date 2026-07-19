import 'dart:async';

import 'package:http/http.dart' as http;

import '../../errors/app_error.dart';
import '../../errors/error_mapper.dart';
import 'http_interceptor.dart';
import '../logger_service.dart';

export '../../errors/app_error.dart' show AppError, ApiResult;

/// High-level HTTP client with retry, standardized errors, and legacy map output.
///
/// Prefer this over calling [HttpInterceptor] directly in new code.
class ApiClient {
  ApiClient._();

  static const _defaultRetries = 2;
  static const _retryDelay = Duration(milliseconds: 800);

  /// Executes an authenticated request with optional retry for transient failures.
  static Future<ApiResult<http.Response>> request({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? queryParameters,
    int maxRetries = _defaultRetries,
    String? context,
  }) async {
    Object? lastError;
    StackTrace? lastStack;

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await HttpInterceptor.authenticatedRequest(
          method: method,
          endpoint: endpoint,
          headers: headers,
          body: body,
          queryParameters: queryParameters,
        );

        LoggerService.api(
          method: method,
          endpoint: endpoint,
          statusCode: response.statusCode,
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return ApiResult.ok(response, statusCode: response.statusCode);
        }

        final appError = ErrorMapper.fromHttpResponse(response, context: context);
        if (!appError.isRetryable || attempt == maxRetries) {
          return ApiResult.fail(appError);
        }

        LoggerService.warning(
          'Retrying $method $endpoint (${appError.code}) attempt ${attempt + 1}',
        );
        await Future<void>.delayed(_retryDelay * (attempt + 1));
        continue;
      } catch (e, st) {
        lastError = e;
        lastStack = st;
        final mapped = ErrorMapper.fromException(e, st, context);
        if (!mapped.isRetryable || attempt == maxRetries) {
          return ApiResult.fail(mapped);
        }
        LoggerService.warning(
          'Retrying $method $endpoint (${mapped.code}) attempt ${attempt + 1}',
        );
        await Future<void>.delayed(_retryDelay * (attempt + 1));
      }
    }

    return ApiResult.fail(
      ErrorMapper.fromException(
        lastError ?? StateError('Request failed'),
        lastStack,
        context,
      ),
    );
  }

  /// Backward-compatible `Map` response for existing services.
  static Future<Map<String, dynamic>> requestAsMap({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? queryParameters,
    int maxRetries = _defaultRetries,
    String? context,
  }) async {
    final result = await request(
      method: method,
      endpoint: endpoint,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
      maxRetries: maxRetries,
      context: context,
    );
    if (result.success) {
      return {
        'success': true,
        'message': 'success',
        'response': result.data,
        if (result.statusCode != null) 'statusCode': result.statusCode,
      };
    }
    return result.error!.toApiMap();
  }
}
