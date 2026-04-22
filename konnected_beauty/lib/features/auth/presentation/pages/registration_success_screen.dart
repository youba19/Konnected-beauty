import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../company/presentation/pages/salon_main_wrapper.dart';
import '../../../influencer/presentation/pages/influencer_home_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';

class RegistrationSuccessScreen extends StatelessWidget {
  final String? message;
  final bool isError;
  final String? userRole; // 'influencer' or 'salon'

  const RegistrationSuccessScreen({
    super.key,
    this.message,
    this.isError = false,
    this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getScaffoldBackground(
        Theme.of(context).brightness,
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isError
                  ? [
                      Colors.red.withOpacity(0.1),
                      AppTheme.getScaffoldBackground(
                        Theme.of(context).brightness,
                      ),
                    ]
                  : [
                      AppTheme.greenPrimary.withOpacity(0.1),
                      AppTheme.getScaffoldBackground(
                        Theme.of(context).brightness,
                      ),
                    ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isError
                        ? Colors.red.withOpacity(0.1)
                        : AppTheme.greenPrimary.withOpacity(0.1),
                  ),
                  child: Icon(
                    isError ? LucideIcons.xCircle : LucideIcons.checkCircle,
                    size: 64,
                    color: isError ? Colors.red : AppTheme.greenPrimary,
                  ),
                ),
                const SizedBox(height: 32),
                // Title
                Text(
                  isError
                      ? AppTranslations.getString(context, 'registration_failed')
                      : AppTranslations.getString(
                          context, 'registration_success'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Message
                Text(
                  message ??
                      (isError
                          ? AppTranslations.getString(
                              context, 'registration_failed_message')
                          : AppTranslations.getString(
                              context, 'account_created_successfully')),
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                // Button to navigate to home
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate based on user role
                      if (userRole == 'influencer') {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const InfluencerHomeScreen(),
                          ),
                          (route) => false,
                        );
                      } else {
                        // Default to salon
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const SalonMainWrapper(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.greenPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.home,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppTranslations.getString(context, 'go_to_home'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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
