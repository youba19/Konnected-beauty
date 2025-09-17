import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

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
    this.duration = const Duration(seconds: 3),
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
                  color: Colors.black.withOpacity(0.2),
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
  static void show({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismiss,
    IconData? icon,
  }) {
    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (context) => TopNotificationBanner(
        message: message,
        backgroundColor: backgroundColor,
        duration: duration,
        onDismiss: onDismiss,
        icon: icon,
      ),
    );

    overlay.insert(entry);

    Future.delayed(duration, () {
      entry.remove();
      onDismiss?.call();
    });
  }

  // Convenience methods for common notification types
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
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
    Duration duration = const Duration(seconds: 3),
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
    Duration duration = const Duration(seconds: 3),
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
    Duration duration = const Duration(seconds: 3),
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
