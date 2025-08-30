import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konnected_beauty/features/company/presentation/pages/salon_security_screen.dart';
import 'package:konnected_beauty/features/company/presentation/pages/salon_information_screen.dart';
import 'package:konnected_beauty/features/company/presentation/pages/notifications_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/services/storage/token_storage_service.dart';
import 'salon_profile_details_screen.dart';
import '../../../../core/bloc/auth/auth_bloc.dart';
import '../../../auth/presentation/pages/welcome_screen.dart';

class SalonSettingsScreen extends StatelessWidget {
  const SalonSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color(0xFF1F1E1E),
            Color(0xFF3B3B3B),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: BlocBuilder<LanguageBloc, LanguageState>(
            builder: (context, languageState) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name Section
                    _buildSectionHeader(
                      AppTranslations.getString(context, 'name'),
                    ),
                    const SizedBox(height: 16),
                    _buildSettingsOption(
                      icon: LucideIcons.user,
                      title:
                          AppTranslations.getString(context, 'profile_details'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const SalonProfileDetailsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsOption(
                      icon: LucideIcons.shield,
                      title: AppTranslations.getString(context, 'security'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SalonSecurityScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Salon Name Section
                    _buildSectionHeader(
                      AppTranslations.getString(context, 'saloon_name'),
                    ),
                    const SizedBox(height: 16),
                    _buildSettingsOption(
                      icon: LucideIcons.building,
                      title: AppTranslations.getString(
                          context, 'saloon_information'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const SalonInformationScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsOption(
                      icon: LucideIcons.bell,
                      title:
                          AppTranslations.getString(context, 'notifications'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Logout Button - using influencer pattern
                    _buildLogoutButton(context),

                    const SizedBox(height: 50),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF363636),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        print('🔴 === SALON LOGOUT BUTTON TAPPED ===');
        // Store context locally to avoid async gap issues
        final currentContext = context;
        print('🔴 Context stored, showing confirmation dialog...');
        // Show confirmation dialog
        final shouldLogout = await _showLogoutConfirmation(currentContext);
        print('🔴 Confirmation result: $shouldLogout');
        if (shouldLogout == true && currentContext.mounted) {
          print('🔴 User confirmed logout, proceeding...');
          await _handleLogout(currentContext);
        } else {
          print('🔴 Logout cancelled or context not mounted');
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF363636),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.logOut,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                AppTranslations.getString(context, 'logout'),
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show logout confirmation bottom sheet (influencer pattern)
  Future<bool?> _showLogoutConfirmation(BuildContext context) {
    print('🔴 === SHOWING SALON LOGOUT CONFIRMATION BOTTOM SHEET ===');
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2C2C2C),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Confirmation message
                  Text(
                    'Are you sure you want to logout?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Buttons row
                  Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            print('🔴 Logout cancelled by user');
                            Navigator.of(context).pop(false);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A3A3A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF4A4A4A),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Logout button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            print('🔴 Logout confirmed by user');
                            Navigator.of(context).pop(true);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Handle logout process (influencer pattern)
  Future<void> _handleLogout(BuildContext context) async {
    print('🔴 === HANDLING SALON LOGOUT PROCESS ===');
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF22C55E),
            ),
          );
        },
      );

      // Clear all tokens and user data
      await TokenStorageService.clearAuthData();

      // Trigger logout in AuthBloc
      if (context.mounted) {
        context.read<AuthBloc>().add(Logout());
      }

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to welcome screen and clear all previous routes
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const WelcomeScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog if there's an error
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
