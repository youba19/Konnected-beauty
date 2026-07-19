import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../core/translations/app_translations.dart';

/// Graceful empty/error state with optional retry — use instead of raw exception text.
class ErrorFallbackWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  final bool compact;

  const ErrorFallbackWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = LucideIcons.alertCircle,
    this.compact = false,
  });

  factory ErrorFallbackWidget.network({VoidCallback? onRetry, bool compact = false}) {
    return ErrorFallbackWidget(
      message: 'Check your internet connection and try again.',
      onRetry: onRetry,
      icon: LucideIcons.wifiOff,
      compact: compact,
    );
  }

  factory ErrorFallbackWidget.generic({VoidCallback? onRetry, bool compact = false}) {
    return ErrorFallbackWidget(
      message: 'Something went wrong. Please try again later.',
      onRetry: onRetry,
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor =
        isLight ? AppTheme.lightTextSecondaryColor : AppTheme.textWhite70;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 24)
        : const EdgeInsets.all(32);

    return Padding(
      padding: padding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: compact ? 36 : 48,
              color: isLight ? AppTheme.lightTextSecondaryColor : Colors.white38,
            ),
            SizedBox(height: compact ? 12 : 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: compact ? 14 : 16,
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: compact ? 16 : 20),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: Text(
                  AppTranslations.getString(context, 'try_again'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
