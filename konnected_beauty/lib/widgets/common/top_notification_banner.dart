import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/errors/app_error.dart';
import '../../core/errors/error_sanitizer.dart';

class TopNotificationBanner extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final Duration duration;
  final VoidCallback? onDismiss;
  final IconData? icon;

  const TopNotificationBanner({
    super.key,
    required this.message,
    required this.backgroundColor,
    this.duration = const Duration(seconds: 2),
    this.onDismiss,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(25), // Pill-shaped design
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                ],
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TopNotificationService {
  static OverlayEntry? _currentEntry;
  static int _token = 0;

  /// Hides stack traces, HTTP client dumps, and OS error details from the top banner.
  static String sanitizeNotificationMessage(String message) =>
      ErrorSanitizer.forUser(message);

  static void dismiss() {
    final entry = _currentEntry;
    _currentEntry = null;
    if (entry == null) return;
    try {
      if (entry.mounted) {
        entry.remove();
      }
    } catch (_) {
      // Overlay may already be torn down during route transitions.
    }
  }

  static OverlayState? _resolveOverlay(BuildContext context) {
    // Prefer the root navigator overlay so entries survive sheet/dialog
    // dismissal and avoid Duplicate GlobalKey reparenting.
    final rootNavigator = Navigator.maybeOf(context, rootNavigator: true);
    final rootOverlay = rootNavigator?.overlay;
    if (rootOverlay != null) return rootOverlay;

    try {
      return Overlay.of(context, rootOverlay: true);
    } catch (_) {
      try {
        return Overlay.of(context);
      } catch (_) {
        return null;
      }
    }
  }

  static void show({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onDismiss,
    IconData? icon,
  }) {
    // Resolve overlay while [context] is still valid (e.g. before a route pop).
    final overlay = _resolveOverlay(context);
    if (overlay == null) return;

    final displayMessage = sanitizeNotificationMessage(message);
    final token = ++_token;

    void insert() {
      if (token != _token) return;

      dismiss();

      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (overlayContext) => TopNotificationBanner(
          message: displayMessage,
          backgroundColor: backgroundColor,
          duration: duration,
          onDismiss: onDismiss,
          icon: icon,
        ),
      );

      try {
        overlay.insert(entry);
        _currentEntry = entry;
      } catch (_) {
        return;
      }

      Future.delayed(duration, () {
        if (token != _token) return;
        if (!identical(_currentEntry, entry)) return;
        dismiss();
        onDismiss?.call();
      });
    }

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      insert();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => insert());
    }
  }

  static void showAppError({
    required BuildContext context,
    required AppError error,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismiss,
  }) {
    showError(
      context: context,
      message: error.userMessage,
      duration: duration,
      onDismiss: onDismiss,
    );
  }

  // Convenience methods for common notification types
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onDismiss,
  }) {
    show(
      context: context,
      message: message,
      backgroundColor: const Color(0xFF4CAF50), // Bright green
      duration: duration,
      onDismiss: onDismiss,
      icon: Icons.check_circle,
    );
  }

  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onDismiss,
  }) {
    show(
      context: context,
      message: message,
      backgroundColor: const Color(0xFFD32F2F), // Muted red
      duration: duration,
      onDismiss: onDismiss,
      icon: Icons.error,
    );
  }

  static void showWarning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onDismiss,
  }) {
    show(
      context: context,
      message: message,
      backgroundColor: const Color(0xFFFF9800), // Orange
      duration: duration,
      onDismiss: onDismiss,
      icon: Icons.warning,
    );
  }

  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onDismiss,
  }) {
    show(
      context: context,
      message: message,
      backgroundColor: const Color(0xFF2196F3), // Blue
      duration: duration,
      onDismiss: onDismiss,
      icon: Icons.info,
    );
  }
}
