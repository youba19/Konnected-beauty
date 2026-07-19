import 'dart:ui';

import 'package:flutter/material.dart';

import '../config/app_environment.dart';
import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import '../errors/error_sanitizer.dart';
import 'logger_service.dart';
import '../../widgets/common/top_notification_banner.dart';

/// Orchestrates logging + user-visible error notifications.
///
/// Architecture:
/// 1. Low-level layers throw / return [AppError] via [ErrorMapper].
/// 2. [ErrorService.log] records full detail internally.
/// 3. [ErrorService.showUserError] surfaces only [AppError.userMessage].
class ErrorService {
  ErrorService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Install Flutter / platform / zone error handlers in [main].
  static void installGlobalHandlers() {
    FlutterError.onError = (details) {
      LoggerService.error(
        'Flutter framework error',
        error: details.exception,
        stackTrace: details.stack,
      );
      if (AppEnvironment.verboseLogging) {
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      final appError = ErrorMapper.fromException(error, stack, 'platform');
      log(appError);
      return true;
    };
  }

  static void log(AppError error) {
    if (error.isOffline) {
      LoggerService.warning(error.debugMessage ?? error.userMessage);
      return;
    }
    LoggerService.error(
      '${error.code}: ${error.debugMessage ?? error.userMessage}',
      error: error.originalError,
      stackTrace: error.stackTrace,
    );
  }

  static AppError handle(
    Object error,
    StackTrace stack, {
    String? context,
  }) {
    final appError = ErrorMapper.fromException(error, stack, context);
    log(appError);
    return appError;
  }

  static void showUserError(
    AppError error, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 3),
  }) {
    log(error);
    final message = ErrorSanitizer.forUser(error.userMessage);
    _showBanner(message, context: context, duration: duration);
  }

  static void showUserMessage(
    String message, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 3),
  }) {
    final safe = ErrorSanitizer.forUser(message);
    _showBanner(safe, context: context, duration: duration);
  }

  static void showSuccess(
    String message, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 2),
  }) {
    final ctx = _resolveContext(context);
    if (ctx == null) return;
    TopNotificationService.showSuccess(
      context: ctx,
      message: ErrorSanitizer.forUser(message, fallback: message),
      duration: duration,
    );
  }

  static void _showBanner(
    String message, {
    BuildContext? context,
    Duration duration = const Duration(seconds: 3),
  }) {
    final ctx = _resolveContext(context);
    if (ctx == null) {
      LoggerService.warning('No context for error banner: $message');
      return;
    }
    TopNotificationService.showError(
      context: ctx,
      message: message,
      duration: duration,
    );
  }

  static BuildContext? _resolveContext(BuildContext? context) {
    if (context != null && context.mounted) return context;
    return navigatorKey.currentContext;
  }
}
