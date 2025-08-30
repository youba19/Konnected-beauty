import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konnected_beauty/core/theme/app_theme.dart';
import '../../../../core/bloc/auth/auth_bloc.dart';
import '../../../../core/bloc/influencers/influencer_profile_bloc.dart';

import '../../../../core/services/storage/token_storage_service.dart';

import '../../../../features/auth/presentation/pages/welcome_screen.dart';
import 'personal_information_screen.dart';
import 'social_information_screen.dart';
import 'security_screen.dart';
import 'influencer_campaigns_screen.dart';
import 'influencer_campaign_detail_screen.dart';

class InfluencerHomeScreen extends StatefulWidget {
  const InfluencerHomeScreen({super.key});

  @override
  State<InfluencerHomeScreen> createState() => _InfluencerHomeScreenState();
}

class _InfluencerHomeScreenState extends State<InfluencerHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load profile data using BLoC
    context.read<InfluencerProfileBloc>().add(LoadInfluencerProfile());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // TOP GREEN GLOW
          Positioned(
            top: -140,
            left: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  // soft radial green halo like the screenshot
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
                // Content based on selected tab
                Expanded(
                  child: _buildContentBasedOnTab(),
                ),

                // Bottom Navigation (fixed at bottom)
                _buildBottomNavigation(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentBasedOnTab() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return _buildSaloonsContent();
      case 2:
        return _buildCampaignContent();
      case 3:
        return _buildWalletContent();
      case 4:
        return _buildProfileContent();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 90), // Add padding for navbar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildDashboardCards(),
          const SizedBox(height: 24),
          _buildOngoingCampaign(),
          const SizedBox(height: 20),
          _buildReceivedInvitations(),
        ],
      ),
    );
  }

  Widget _buildSaloonsContent() {
    return const Center(
      child: Text(
        'Saloons Screen',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }

  Widget _buildCampaignContent() {
    return const InfluencerCampaignsScreen();
  }

  Widget _buildWalletContent() {
    return const Center(
      child: Text(
        'Wallet Screen',
        style: TextStyle(
            color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 90), // Add padding for navbar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 32),
          _buildProfileOptions(),
        ],
      ),
    );
  }

  /// HEADER
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          ClipOval(
            child: BlocBuilder<InfluencerProfileBloc, InfluencerProfileState>(
              builder: (context, state) {
                if (state is InfluencerProfileLoading) {
                  return Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }

                if (state is InfluencerProfileLoaded ||
                    state is InfluencerProfileUpdated) {
                  final profileData = state is InfluencerProfileUpdated
                      ? state.updatedProfile
                      : state as InfluencerProfileLoaded;

                  final profilePicture = profileData.profilePicture;

                  return profilePicture.isEmpty || profilePicture == 'null'
                      ? Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2C2C2C),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                        )
                      : Image.network(
                          profilePicture,
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
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
                                size: 24,
                              ),
                            );
                          },
                        );
                }

                // Default fallback
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
                    size: 24,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          BlocBuilder<InfluencerProfileBloc, InfluencerProfileState>(
            builder: (context, state) {
              String displayName = 'Loading...';

              if (state is InfluencerProfileLoaded ||
                  state is InfluencerProfileUpdated) {
                final profileData = state is InfluencerProfileUpdated
                    ? state.updatedProfile
                    : state as InfluencerProfileLoaded;
                displayName = profileData.name;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Good morning,",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              );
            },
          ),
          const Spacer(),
          const Icon(Icons.notifications_outlined,
              color: Colors.white, size: 26),
        ],
      ),
    );
  }

  /// Check if profile picture URL is valid
  bool _isValidProfilePictureUrl(String url) {
    if (url.isEmpty || url == 'null') return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      print('❌ Invalid profile picture URL: $url, Error: $e');
      return false;
    }
  }

  /// PROFILE HEADER
  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Profile Picture
          Center(
            child: BlocBuilder<InfluencerProfileBloc, InfluencerProfileState>(
              builder: (context, state) {
                String profilePicture = '';

                if (state is InfluencerProfileLoaded ||
                    state is InfluencerProfileUpdated) {
                  final profileData = state is InfluencerProfileUpdated
                      ? state.updatedProfile
                      : state as InfluencerProfileLoaded;
                  profilePicture = profileData.profilePicture;
                }

                return Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    color: !_isValidProfilePictureUrl(profilePicture)
                        ? const Color(0xFF2C2C2C)
                        : null,
                  ),
                  child: !_isValidProfilePictureUrl(profilePicture)
                      ? const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        )
                      : ClipOval(
                          child: Image.network(
                            profilePicture,
                            width: 42,
                            height: 42,
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
                                  size: 30,
                                ),
                              );
                            },
                          ),
                        ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Username Handle
          Center(
            child: BlocBuilder<InfluencerProfileBloc, InfluencerProfileState>(
              builder: (context, state) {
                String username = 'Loading...';

                if (state is InfluencerProfileLoaded ||
                    state is InfluencerProfileUpdated) {
                  final profileData = state is InfluencerProfileUpdated
                      ? state.updatedProfile
                      : state as InfluencerProfileLoaded;
                  username = profileData.pseudo.isNotEmpty
                      ? profileData.pseudo
                      : profileData.name;
                }

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.borderColor.withOpacity(0.1)),
                  ),
                  child: Text(
                    "@$username",
                    style: AppTheme.subtitleStyle.copyWith(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// PROFILE OPTIONS
  Widget _buildProfileOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildProfileOption(
            icon: Icons.person_outline,
            title: 'Personal Information',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PersonalInformationScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildProfileOption(
            icon: Icons.alternate_email,
            title: 'Social Information',
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
            title: 'Security',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SecurityScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildProfileOption(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {
              // Handle notifications
            },
          ),
          const SizedBox(height: 16),
          _buildProfileOption(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () async {
              // Store context locally to avoid async gap issues
              final currentContext = context;
              // Show confirmation dialog
              final shouldLogout =
                  await _showLogoutConfirmation(currentContext);
              if (shouldLogout == true && currentContext.mounted) {
                await _handleLogout(currentContext);
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
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isLogout ? AppTheme.errorColor : AppTheme.textPrimaryColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTheme.subtitleStyle.copyWith(
                  color: isLogout
                      ? AppTheme.errorColor
                      : AppTheme.textPrimaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isLogout ? AppTheme.errorColor : AppTheme.textPrimaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// DASHBOARD CARDS
  Widget _buildDashboardCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatCard("12k", "Total Revenue", Icons.settings),
          const SizedBox(width: 12),
          _buildStatCard("1,200", "Total Orders", Icons.groups_2_outlined),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String title, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                Icon(icon, color: Colors.black87, size: 22),
              ],
            ),
            const SizedBox(height: 10),

            // Green curved chart look (simple gradient block to match mock)
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF22C55E).withOpacity(0.6),
                    const Color(0xFF22C55E).withOpacity(0.22),
                    const Color(0xFF22C55E).withOpacity(0.06),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ONGOING CAMPAIGN
  Widget _buildOngoingCampaign() {
    // Mock campaign data - replace with actual data from BLoC
    final mockCampaign = {
      'id': '2',
      'saloonName': 'Beauty Studio',
      'createdAt': '15/07/2025',
      'status': 'on going',
      'promotionType': 'Fixed Amount',
      'promotionValue': '50 EUR',
      'message': 'Great collaboration opportunity!',
      'clicks': 1250,
      'completedOrders': 35,
      'total': '1,750 EUR',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ongoing campaign",
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      InfluencerCampaignDetailScreen(campaign: mockCampaign),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: AppTheme.borderColor.withOpacity(0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        (mockCampaign['saloonName'] as String?) ??
                            "Saloon name",
                        style: TextStyle(
                          color: AppTheme.textPrimaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        (mockCampaign['promotionValue'] as String?) ?? "20%",
                        style: TextStyle(
                          color: AppTheme.textPrimaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (mockCampaign['createdAt'] as String?) ??
                        "20/08/2025 12:00",
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${mockCampaign['completedOrders']} Orders",
                    style: TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// RECEIVED INVITATIONS
  Widget _buildReceivedInvitations() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Received invitations",
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderColor.withOpacity(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Saloon name",
                      style: TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "20%",
                      style: TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "20/08/2025 12:00",
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Salut Perdo! Accepter svp!",
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// BOTTOM NAVIGATION WITH GREEN HALF-CIRCLE GLOW
  Widget _buildBottomNavigation() {
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
        height: 70,
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
                _navItem(0, Icons.home_outlined, "Home"),
                _navItem(1, Icons.storefront_outlined, "Saloons"),
                _navItem(2, Icons.campaign_outlined, "Campaign"),
                _navItem(3, Icons.account_balance_wallet_outlined, "Wallet"),
                _navItem(4, Icons.person_outline, "Profile"),
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
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Color(0xFF1F1E1E),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1F1E1E),
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
                  const Text(
                    'Are you sure you want to logout?',
                    style: TextStyle(
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
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.logout,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
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
