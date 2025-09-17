import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:konnected_beauty/features/company/presentation/pages/salon_security_screen.dart';
import 'package:konnected_beauty/features/company/presentation/pages/salon_information_screen.dart';
import 'package:konnected_beauty/features/company/presentation/pages/notifications_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/services/storage/token_storage_service.dart';
import '../../../../core/services/api/salon_profile_service.dart';
import 'salon_profile_details_screen.dart';
import '../../../../core/bloc/auth/auth_bloc.dart';
import '../../../auth/presentation/pages/welcome_screen.dart';

class SalonSettingsScreen extends StatefulWidget {
  const SalonSettingsScreen({super.key});

  @override
  State<SalonSettingsScreen> createState() => _SalonSettingsScreenState();
}

class _SalonSettingsScreenState extends State<SalonSettingsScreen> {
  final SalonProfileService _salonProfileService = SalonProfileService();

  String _personalName = '';
  String _salonName = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSalonProfile();
  }

  Future<void> _loadSalonProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await _salonProfileService.getSalonProfile();

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        print('🔍 Raw API data: $data');
        print('🔍 salonInfo: ${data['salonInfo']}');

        setState(() {
          _personalName = data['name'] ?? '';
          _salonName = data['salonInfo']?['name'] ?? '';
          _isLoading = false;
        });

        print('✅ Loaded salon profile:');
        print('👤 Personal Name: $_personalName');
        print('🏢 Salon Name: $_salonName');
        print('🔍 _salonName variable: $_salonName');
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

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
                child: _isLoading
                    ? _buildShimmerContent()
                    : _errorMessage != null
                        ? Column(
                            children: [
                              const SizedBox(height: 100),
                              Center(
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed: _loadSalonProfile,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF22C55E),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name Section
                              _buildSectionHeader(
                                _personalName.isNotEmpty
                                    ? _personalName
                                    : AppTranslations.getString(
                                        context, 'name'),
                              ),
                              const SizedBox(height: 16),
                              _buildSettingsOption(
                                icon: LucideIcons.user,
                                title: AppTranslations.getString(
                                    context, 'profile_details'),
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SalonProfileDetailsScreen(),
                                    ),
                                  );
                                  // Refresh profile data when returning
                                  _loadSalonProfile();
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildSettingsOption(
                                icon: LucideIcons.shield,
                                title: AppTranslations.getString(
                                    context, 'security'),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SalonSecurityScreen(),
                                    ),
                                  );
                                },
                              ),

                              // Divider between security and salon name
                              Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.2),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 20),
                              ),

                              // Salon Name Section
                              _buildSectionHeader(
                                _salonName.isNotEmpty
                                    ? _salonName
                                    : AppTranslations.getString(
                                        context, 'saloon_name'),
                              ),
                              const SizedBox(height: 16),
                              _buildSettingsOption(
                                icon: LucideIcons.building,
                                title: AppTranslations.getString(
                                    context, 'saloon_information'),
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SalonInformationScreen(),
                                    ),
                                  );
                                  // Refresh profile data when returning
                                  _loadSalonProfile();
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildSettingsOption(
                                icon: LucideIcons.bell,
                                title: AppTranslations.getString(
                                    context, 'notifications'),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const NotificationsScreen(),
                                    ),
                                  );
                                },
                              ),

                              // Divider between notifications and logout
                              Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.2),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 20),
                              ),

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
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextButton(
                            onPressed: () {
                              print('🔴 Logout confirmed by user');
                              Navigator.of(context).pop(true);
                            },
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.logout,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Yes, logout',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
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

  Widget _buildShimmerContent() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header shimmer
          _buildShimmerHeader(),
          const SizedBox(height: 32),
          // Settings options shimmer
          _buildShimmerSettingsOptions(),
        ],
      ),
    );
  }

  Widget _buildShimmerHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile name shimmer
        Container(
          height: 24,
          width: 200,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        // Subtitle shimmer
        Container(
          height: 16,
          width: 150,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerSettingsOptions() {
    return Column(
      children: [
        // Profile section shimmer
        _buildShimmerSection(
          title: 'Profile Section',
          options: 2,
        ),
        const SizedBox(height: 24),
        // Salon section shimmer
        _buildShimmerSection(
          title: 'Salon Section',
          options: 2,
        ),
        const SizedBox(height: 24),
        // Notifications section shimmer
        _buildShimmerSection(
          title: 'Notifications Section',
          options: 1,
        ),
        const SizedBox(height: 24),
        // Logout button shimmer
        _buildShimmerLogoutButton(),
      ],
    );
  }

  Widget _buildShimmerSection({required String title, required int options}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title shimmer
        Container(
          height: 18,
          width: 120,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 16),
        // Options shimmer
        ...List.generate(options, (index) => _buildShimmerOption()),
      ],
    );
  }

  Widget _buildShimmerOption() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          // Icon shimmer
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          // Text shimmer
          Expanded(
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Arrow shimmer
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLogoutButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon shimmer
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          // Text shimmer
          Container(
            height: 16,
            width: 100,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}
