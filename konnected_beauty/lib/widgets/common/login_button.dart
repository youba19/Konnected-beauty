import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/translations/app_translations.dart';

class LoginButton extends StatelessWidget {
  final VoidCallback onPressed;

  const LoginButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textPrimaryColor,
          side: const BorderSide(color: AppTheme.borderColor, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppTranslations.getString(context, 'login_to_account'),
              style: AppTheme.loginButtonTextStyle,
            ),
            const SizedBox(width: 8),
            const Icon(
              LucideIcons.arrowRight, // Right arrow like in the image
              size: 16,
              color: AppTheme.textPrimaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
