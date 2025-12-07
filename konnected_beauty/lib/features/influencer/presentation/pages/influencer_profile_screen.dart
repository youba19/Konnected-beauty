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
import 'influencer_language_screen.dart';
import '../../../../core/bloc/influencer_report/influencer_report_bloc.dart';
import '../../../../core/bloc/influencer_report/influencer_report_event.dart';
import '../../../../core/bloc/influencer_report/influencer_report_state.dart';
import '../../../../core/bloc/theme/theme_bloc.dart';
import '../../../../widgets/common/top_notification_banner.dart';

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
  String _displayName = 'Loading...';
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
          // Set display name (prefer 'name' field, fallback to username)
          _displayName = profileData['name'] ??
              profileData['firstName'] ??
              profileData['fullName'] ??
              'Unknown User';

          // Set username (prefer 'username' field, fallback to userName)
          _profileName = profileData['username'] ??
              profileData['userName'] ??
              profileData['pseudo'] ??
              'unknown_user';

          _profilePicture = profileData['profilePicture'] ?? '';
          _isProfileLoading = false;
          _profileError = null;
        });

        print('👤 Profile updated:');
        print('   Display Name: $_displayName');
        print('   Username: $_profileName');
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
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: AppTheme.getScaffoldBackground(brightness),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // TOP GREEN GLOW
          Positioned(
            top: -120,
            left: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  // soft radial green halo like the screenshot
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 0.8,
                    colors: [
                      AppTheme.greenPrimary.withOpacity(0.35),
                      brightness == Brightness.dark
                          ? AppTheme.transparentBackground
                          : AppTheme.textWhite54,
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
                        SizedBox(height: 32),
                        _buildProfileOptions(),
                        SizedBox(height: 20), // Add some bottom padding
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
                border: Border.all(
                    color: AppTheme.getTextPrimaryColor(
                        Theme.of(context).brightness),
                    width: 2),
                color: _profilePicture.isEmpty
                    ? AppTheme.getPlaceholderBackground(
                        Theme.of(context).brightness)
                    : null,
              ),
              child: _profilePicture.isEmpty || !_isValidUrl(_profilePicture)
                  ? Icon(
                      Icons.person,
                      color: AppTheme.getTextPrimaryColor(
                          Theme.of(context).brightness),
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
                            decoration: BoxDecoration(
                              color: AppTheme.getPlaceholderBackground(
                                  Theme.of(context).brightness),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              color: AppTheme.getTextPrimaryColor(
                                  Theme.of(context).brightness),
                              size: 50,
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),

          SizedBox(height: 16),

          // Display Name
          Center(
            child: _isProfileLoading
                ? CircularProgressIndicator(
                    color: AppTheme.greenPrimary,
                    strokeWidth: 2,
                  )
                : _profileError != null
                    ? Column(
                        children: [
                          Text(
                            'Error loading profile',
                            style: AppTheme.headingStyle.copyWith(
                              color: AppTheme.statusRed,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _fetchProfileData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.greenPrimary,
                              foregroundColor: AppTheme.getTextPrimaryColor(
                                  Theme.of(context).brightness),
                            ),
                            child: Text('Retry'),
                          ),
                        ],
                      )
                    : Text(
                        _displayName,
                        style: AppTheme.headingStyle.copyWith(
                          color: AppTheme.getTextPrimaryColor(
                              Theme.of(context).brightness),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
          ),

          SizedBox(height: 8),

          // Username Handle
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.getPlaceholderBackground(
                    Theme.of(context).brightness),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.getTextPrimaryColor(
                            Theme.of(context).brightness)
                        .withOpacity(0.1)),
              ),
              child: Text(
                "@${_profileName}",
                style: AppTheme.subtitleStyle.copyWith(
                    color: AppTheme.getTextPrimaryColor(
                        Theme.of(context).brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),

          SizedBox(height: 16),

          // Refresh Profile Button
          if (!_isProfileLoading)
            Center(
              child: ElevatedButton.icon(
                onPressed: _fetchProfileData,
                icon: Icon(Icons.refresh, size: 18),
                label: Text('Refresh Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.greenPrimary,
                  foregroundColor: AppTheme.getTextPrimaryColor(
                      Theme.of(context).brightness),
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
          SizedBox(height: 16),
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
          SizedBox(height: 16),
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
                  title: Text('Security Test'),
                  content: Text(
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
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 16),
          _buildProfileOption(
            icon: Icons.language,
            title: AppTranslations.getString(context, 'language'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InfluencerLanguageScreen(),
                ),
              );
            },
          ),
          SizedBox(height: 16),
          _buildProfileOption(
            icon: Icons.report_problem_outlined,
            title: AppTranslations.getString(context, 'report'),
            onTap: () {
              _showReportBottomSheet(context);
            },
          ),
          SizedBox(height: 16),
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
          color:
              AppTheme.getPlaceholderBackground(Theme.of(context).brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness)
                  .withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isLogout
                  ? AppTheme.statusRed
                  : AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              size: 24,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTheme.subtitleStyle.copyWith(
                    color: isLogout
                        ? AppTheme.statusRed
                        : AppTheme.getTextPrimaryColor(
                            Theme.of(context).brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isLogout
                  ? AppTheme.statusRed
                  : AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showReportBottomSheet(BuildContext context) {
    final TextEditingController _reportController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          AppTheme.getScaffoldBackground(Theme.of(context).brightness),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.65,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.getScaffoldBackground(
                    Theme.of(context).brightness),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                top: false,
                child: GestureDetector(
                  onTap: () {
                    // Close keyboard when tapping outside text fields
                    FocusScope.of(context).unfocus();
                  },
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 24.0,
                      top: 24.0,
                      right: 24.0,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
                    ),
                    child: BlocProvider(
                      create: (_) => InfluencerReportBloc(),
                      child: BlocConsumer<InfluencerReportBloc,
                          InfluencerReportState>(
                        listener: (context, state) {
                          if (state is InfluencerReportSuccess) {
                            Navigator.of(context).pop();
                            _reportController.clear();
                            TopNotificationService.showSuccess(
                              context: this.context,
                              message: AppTranslations.getString(this.context,
                                  'report_submitted_successfully'),
                            );
                          } else if (state is InfluencerReportError) {
                            TopNotificationService.showError(
                              context: this.context,
                              message: state.message,
                            );
                          }
                        },
                        builder: (context, state) {
                          final bool isLoading =
                              state is InfluencerReportLoading;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.getString(context, 'report'),
                                style: TextStyle(
                                  color: AppTheme.getTextPrimaryColor(
                                      Theme.of(context).brightness),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                AppTranslations.getString(
                                    context, 'report_subtitle'),
                                style: TextStyle(
                                  color: AppTheme.getTextPrimaryColor(
                                          Theme.of(context).brightness)
                                      .withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                AppTranslations.getString(context, 'report'),
                                style: TextStyle(
                                  color: AppTheme.getTextPrimaryColor(
                                      Theme.of(context).brightness),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.getScaffoldBackground(
                                      Theme.of(context).brightness),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppTheme.getCardBackground(
                                          Theme.of(context).brightness)),
                                ),
                                child: TextField(
                                  controller: _reportController,
                                  maxLines: 6,
                                  maxLength: 100,
                                  style: TextStyle(
                                      color: AppTheme.getTextPrimaryColor(
                                          Theme.of(context).brightness)),
                                  decoration: InputDecoration(
                                    hintText: AppTranslations.getString(
                                        context, 'describe_your_problem'),
                                    hintStyle: TextStyle(
                                      color: AppTheme.getTextPrimaryColor(
                                              Theme.of(context).brightness)
                                          .withOpacity(0.5),
                                    ),
                                    counterStyle: TextStyle(
                                      color: AppTheme.getTextPrimaryColor(
                                              Theme.of(context).brightness)
                                          .withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: isLoading
                                          ? null
                                          : () => Navigator.of(context).pop(),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        decoration: BoxDecoration(
                                          color: AppTheme.getScaffoldBackground(
                                              Theme.of(context).brightness),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: AppTheme.getCardBackground(
                                                  Theme.of(context)
                                                      .brightness)),
                                        ),
                                        child: Text(
                                          AppTranslations.getString(
                                              context, 'cancel'),
                                          style: TextStyle(
                                            color: AppTheme.getTextPrimaryColor(
                                                Theme.of(context).brightness),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppTheme.getTextPrimaryColor(
                                            Theme.of(context).brightness),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: TextButton(
                                        onPressed: isLoading
                                            ? null
                                            : () {
                                                final text = _reportController
                                                    .text
                                                    .trim();
                                                if (text.isEmpty) {
                                                  TopNotificationService
                                                      .showInfo(
                                                    context: this.context,
                                                    message: AppTranslations
                                                        .getString(this.context,
                                                            'no_comment'),
                                                  );
                                                  return;
                                                }
                                                context
                                                    .read<
                                                        InfluencerReportBloc>()
                                                    .add(SubmitInfluencerReport(
                                                        text));
                                              },
                                        style: TextButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: isLoading
                                            ? SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppTheme
                                                      .lightTextPrimaryColor,
                                                ),
                                              )
                                            : Text(
                                                AppTranslations.getString(
                                                    this.context, 'submit'),
                                                style: TextStyle(
                                                  color: AppTheme
                                                      .lightTextPrimaryColor,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// BOTTOM NAVIGATION WITH GREEN HALF-CIRCLE GLOW
  Widget _buildBottomNavigation(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final itemWidth = width / 5;

    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.getScaffoldBackground(Theme.of(context).brightness),
        border: Border(
          top: BorderSide(
              color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness)
                  .withOpacity(0.08),
              width: 1),
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
                            AppTheme.greenPrimary.withOpacity(0.6),
                            Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.transparentBackground
                                : AppTheme.textWhite54,
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
              children: [
                Expanded(
                  child: _navItem(0, Icons.home_outlined,
                      AppTranslations.getString(context, 'home')),
                ),
                Expanded(
                  child: _navItem(1, Icons.storefront_outlined,
                      AppTranslations.getString(context, 'saloons')),
                ),
                Expanded(
                  child: _navItem(2, Icons.campaign_outlined,
                      AppTranslations.getString(context, 'campaign')),
                ),
                Expanded(
                  child: _navItem(3, Icons.account_balance_wallet_outlined,
                      AppTranslations.getString(context, 'wallet')),
                ),
                Expanded(
                  child: _navItem(4, Icons.person_outline,
                      AppTranslations.getString(context, 'profile')),
                ),
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected
                ? AppTheme.getTextPrimaryColor(Theme.of(context).brightness)
                : AppTheme.getNavBarTextColor(Theme.of(context).brightness),
            size: 24,
          ),
          SizedBox(height: 4),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.getTextPrimaryColor(Theme.of(context).brightness)
                    : AppTheme.getNavBarTextColor(Theme.of(context).brightness),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
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
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.transparentBackground
          : AppTheme.textWhite54,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color:
                AppTheme.getPlaceholderBackground(Theme.of(context).brightness),
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
                    style: TextStyle(
                      color: AppTheme.getTextPrimaryColor(
                          Theme.of(context).brightness),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),

                  // Buttons row
                  Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppTheme.transparentBackground
                                    : AppTheme.textWhite54,
                            border: Border.all(
                                color: AppTheme.getTextPrimaryColor(
                                    Theme.of(context).brightness),
                                width: 1),
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
                              style: TextStyle(
                                color: AppTheme.getTextPrimaryColor(
                                    Theme.of(context).brightness),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),

                      // Logout button
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.statusRed,
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
                                Icon(
                                  Icons.logout,
                                  color: AppTheme.getTextPrimaryColor(
                                      Theme.of(context).brightness),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Yes, logout',
                                  style: TextStyle(
                                    color: AppTheme.getTextPrimaryColor(
                                        Theme.of(context).brightness),
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
                  SizedBox(height: 16),
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
          return Center(
            child: CircularProgressIndicator(
              color: AppTheme.greenPrimary,
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
            backgroundColor: AppTheme.statusRed,
          ),
        );
      }
    }
  }
}
