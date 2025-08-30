import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/auth/auth_bloc.dart';
import '../../../../core/services/storage/token_storage_service.dart';
import '../../../../core/services/api/influencer_auth_service.dart';
import '../../../../features/auth/presentation/pages/welcome_screen.dart';
import 'social_information_screen.dart';
import 'security_screen.dart';

class InfluencerProfileScreen extends StatefulWidget {
  const InfluencerProfileScreen({super.key});

  @override
  State<InfluencerProfileScreen> createState() =>
      _InfluencerProfileScreenState();
}

class _InfluencerProfileScreenState extends State<InfluencerProfileScreen> {
  int _selectedIndex = 4; // Profile tab is selected

  // Profile data state
  String _profileName = 'Loading...';
  String _profilePicture = '';
  bool _isProfileLoading = true;
  String? _profileError;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  /// Fetch influencer profile data from API
  Future<void> _fetchProfileData() async {
    try {
      setState(() {
        _isProfileLoading = true;
        _profileError = null;
      });

      print('👤 === FETCHING INFLUENCER PROFILE ===');
      final result = await InfluencerAuthService.getProfile();

      if (result['success'] && mounted) {
        final profileData = result['data'];
        print('✅ Profile data received: $profileData');
        print('🔍 Available profile fields: ${profileData.keys.toList()}');
        print('🔍 Username field: ${profileData['username']}');
        print('🔍 UserName field: ${profileData['userName']}');
        print('🔍 Name field: ${profileData['name']}');

        setState(() {
          _profileName = profileData['username'] ??
              profileData['userName'] ??
              profileData['name'] ??
              'Unknown User';
          _profilePicture = profileData['profilePicture'] ?? '';
          _isProfileLoading = false;
          _profileError = null;
        });

        print('👤 Profile updated:');
        print('   Name: $_profileName');
        print('   Picture: $_profilePicture');
      } else {
        print('❌ Profile fetch failed: ${result['message']}');
        if (mounted) {
          setState(() {
            _isProfileLoading = false;
            _profileError = result['message'] ?? 'Failed to load profile';
          });
        }
      }
    } catch (e) {
      print('❌ Exception fetching profile: $e');
      if (mounted) {
        setState(() {
          _isProfileLoading = false;
          _profileError = 'Error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // TOP GREEN GLOW
          Positioned(
            top: -90,
            left: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 0.9,
                    colors: [
                      const Color(0xFF22C55E).withOpacity(0.55),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // CONTENT
          SafeArea(
            child: Column(
              children: [
                // Scrollable content area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                        bottom: 90), // Add padding for navbar
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileHeader(),
                        const SizedBox(height: 32),
                        _buildProfileOptions(),
                        const SizedBox(height: 20), // Add some bottom padding
                      ],
                    ),
                  ),
                ),

                // Bottom Navigation (fixed at bottom)
                _buildBottomNavigation(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Check if URL is valid
  bool _isValidUrl(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  /// PROFILE HEADER WITH DYNAMIC DATA
  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Profile Picture
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                color: _profilePicture.isEmpty ? const Color(0xFF2C2C2C) : null,
              ),
              child: _profilePicture.isEmpty || !_isValidUrl(_profilePicture)
                  ? const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 50,
                    )
                  : ClipOval(
                      child: Image.network(
                        _profilePicture,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('❌ Error loading profile image: $error');
                          return Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2C2C2C),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 50,
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // User Name
          Center(
            child: _isProfileLoading
                ? const CircularProgressIndicator(
                    color: Color(0xFF22C55E),
                    strokeWidth: 2,
                  )
                : _profileError != null
                    ? Column(
                        children: [
                          Text(
                            'Error loading profile',
                            style: AppTheme.headingStyle.copyWith(
                              color: Colors.red,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _fetchProfileData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      )
                    : Text(
                        _profileName,
                        style: AppTheme.headingStyle.copyWith(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
          ),

          const SizedBox(height: 12),

          // Username Handle
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                "@${_profileName}",
                style: AppTheme.subtitleStyle.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Refresh Profile Button
          if (!_isProfileLoading)
            Center(
              child: ElevatedButton.icon(
                onPressed: _fetchProfileData,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// PROFILE OPTIONS/SETTINGS
  Widget _buildProfileOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildProfileOption(
            icon: Icons.person_outline,
            title: AppTranslations.getString(context, 'personal_information'),
            onTap: () {
              // Navigate to personal information
            },
          ),
          const SizedBox(height: 16),
          _buildProfileOption(
            icon: Icons.alternate_email,
            title: AppTranslations.getString(context, 'social_information'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SocialInformationScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildProfileOption(
            icon: Icons.shield_outlined,
            title: AppTranslations.getString(context, 'security'),
            onTap: () {
              print('🔒 === SECURITY BUTTON TAPPED ===');
              print('🔒 Attempting to navigate to SecurityScreen...');

              // First, let's test if navigation works at all
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Security Test'),
                  content: const Text(
                      'Security button is working! Click OK to navigate to Security screen.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog

                        // Now try to navigate to SecurityScreen
                        try {
                          print('🔒 Dialog closed, attempting navigation...');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SecurityScreen(),
                            ),
                          );
                          print('🔒 Navigation to SecurityScreen successful');
                        } catch (e) {
                          print('🔒 Navigation failed: $e');
                          print('🔒 Error details: ${e.toString()}');
                        }
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildProfileOption(
            icon: Icons.notifications_outlined,
            title: AppTranslations.getString(context, 'notifications'),
            onTap: () {
              // Navigate to notification settings
            },
          ),
          const SizedBox(height: 16),
          _buildProfileOption(
            icon: Icons.logout,
            title: AppTranslations.getString(context, 'logout'),
            onTap: () async {
              print('🔴 === LOGOUT BUTTON TAPPED ===');
              // Store context locally to avoid async gap issues
              final currentContext = context;
              print('🔴 Context stored, showing confirmation dialog...');
              // Show confirmation dialog
              final shouldLogout =
                  await _showLogoutConfirmation(currentContext);
              print('🔴 Confirmation result: $shouldLogout');
              if (shouldLogout == true && currentContext.mounted) {
                print('🔴 User confirmed logout, proceeding...');
                await _handleLogout(currentContext);
              } else {
                print('🔴 Logout cancelled or context not mounted');
              }
            },
            isLogout: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isLogout ? Colors.red : Colors.white,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTheme.subtitleStyle.copyWith(
                    color: isLogout ? Colors.red : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isLogout ? Colors.red : Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// BOTTOM NAVIGATION WITH GREEN HALF-CIRCLE GLOW
  Widget _buildBottomNavigation(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final itemWidth = width / 5;

    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
        ),
      ),
      child: SizedBox(
        height: 80,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // GREEN HALF-CIRCLE LIGHT ABOVE SELECTED NAV ITEM
            AnimatedPositioned(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              left: _selectedIndex * itemWidth + (itemWidth / 2) - 40,
              top: 10,
              child: IgnorePointer(
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 0.5,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          radius: 0.6,
                          colors: [
                            const Color(0xFF22C55E).withOpacity(0.6),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // NAV ITEMS ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_outlined,
                    AppTranslations.getString(context, 'home')),
                _navItem(1, Icons.storefront_outlined,
                    AppTranslations.getString(context, 'saloons')),
                _navItem(2, Icons.campaign_outlined,
                    AppTranslations.getString(context, 'campaign')),
                _navItem(3, Icons.account_balance_wallet_outlined,
                    AppTranslations.getString(context, 'wallet')),
                _navItem(4, Icons.person_outline,
                    AppTranslations.getString(context, 'profile')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? AppTheme.textPrimaryColor
                : AppTheme.navBartextColor,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? AppTheme.textPrimaryColor
                  : AppTheme.navBartextColor,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// Show logout confirmation bottom sheet
  Future<bool?> _showLogoutConfirmation(BuildContext context) {
    print('🔴 === SHOWING LOGOUT CONFIRMATION BOTTOM SHEET ===');
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
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(color: Colors.white, width: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              AppTranslations.getString(context, 'cancel'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
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
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
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
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Yes, logout',
                                  style: const TextStyle(
                                    color: Colors.white,
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Handle logout process
  Future<void> _handleLogout(BuildContext context) async {
    print('🔴 === HANDLING LOGOUT PROCESS ===');
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
