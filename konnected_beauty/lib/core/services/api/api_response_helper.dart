import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../errors/app_error.dart';
import '../../errors/error_mapper.dart';

/// Builds standardized success/failure maps for legacy service methods.
class ApiResponseHelper {
  ApiResponseHelper._();

  static Map<String, dynamic> success({
    dynamic data,
    String message = 'success',
    int? statusCode,
    Map<String, dynamic>? extra,
  }) {
    return {
      'success': true,
      'message': message,
      if (data != null) 'data': data,
      if (statusCode != null) 'statusCode': statusCode,
      if (extra != null) ...extra,
    };
  }

  static Map<String, dynamic> failure(AppError error, {dynamic data}) =>
      error.toApiMap(data: data);

  static Map<String, dynamic> failureFromException(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    dynamic data,
  }) =>
      ErrorMapper.fromException(error, stackTrace, context)
          .toApiMap(data: data);

  static Map<String, dynamic> failureFromMap(Map<String, dynamic> map) =>
      ErrorMapper.fromApiMap(map).toApiMap(data: map['data']);

  /// Parses a successful HTTP body or returns a standardized failure map.
  static Map<String, dynamic> fromHttpResponse(
    http.Response response, {
    String? context,
    dynamic defaultData,
  }) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded['success'] == false) {
            return ErrorMapper.fromApiMap(decoded).toApiMap(data: decoded['data']);
          }
          return success(
            data: decoded['data'] ?? decoded,
            message: decoded['message']?.toString() ?? 'success',
            statusCode: response.statusCode,
            extra: _paginationFields(decoded),
          );
        }
        return success(data: decoded, statusCode: response.statusCode);
      } catch (e, st) {
        return failureFromException(e, stackTrace: st, context: context, data: defaultData);
      }
    }
    return ErrorMapper.fromHttpResponse(response, context: context)
        .toApiMap(data: defaultData);
  }

  static Map<String, dynamic>? _paginationFields(Map<String, dynamic> body) {
    final fields = <String, dynamic>{};
    for (final key in ['currentPage', 'totalPages', 'total', 'limit', 'page']) {
      if (body.containsKey(key)) fields[key] = body[key];
    }
    return fields.isEmpty ? null : fields;
  }
}
