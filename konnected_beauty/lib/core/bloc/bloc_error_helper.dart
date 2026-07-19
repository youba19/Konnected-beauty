import '../errors/app_error.dart';
import '../errors/error_mapper.dart';

/// Thin helper for blocs — keeps catch blocks one-liners.
class BlocErrorHelper {
  BlocErrorHelper._();

  static String messageFrom(Object error, [StackTrace? stackTrace, String? context]) =>
      ErrorMapper.fromException(error, stackTrace, context).userMessage;

  static AppError from(Object error, [StackTrace? stackTrace, String? context]) =>
      ErrorMapper.fromException(error, stackTrace, context);

  static String messageFromApiMap(Map<String, dynamic> map) =>
      ErrorMapper.fromApiMap(map).userMessage;
}
