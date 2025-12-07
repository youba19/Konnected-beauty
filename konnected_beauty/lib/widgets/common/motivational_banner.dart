import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';

/// Rounded informational banner that can be reused across multiple screens.
class MotivationalBanner extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;

  const MotivationalBanner({
    super.key,
    required this.text,
    this.icon = LucideIcons.lightbulb,
    this.backgroundColor,
    this.textColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bgColor = backgroundColor ??
        (brightness == Brightness.dark
            ? const Color(0xFF5C5C5C)
            : AppTheme.lightBannerBackground);
    final txtColor = textColor ??
        (brightness == Brightness.dark
            ? Colors.white
            : AppTheme.lightTextPrimaryColor);

    return Container(
      width: double.infinity,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: txtColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.start,
              style: TextStyle(
                color: txtColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
