import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konnected_beauty/core/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/auth/auth_bloc.dart';
import '../../../../core/bloc/influencers/influencer_profile_bloc.dart';

import '../../../../core/services/storage/token_storage_service.dart';
import '../../../../core/services/api/influencers_service.dart';
import '../../../../core/services/api/influencer_wallet_service.dart';

import '../../../../features/auth/presentation/pages/welcome_screen.dart';
import 'personal_information_screen.dart';
import 'social_information_screen.dart';
import 'payment_information_screen.dart';
import 'security_screen.dart';
import 'campaigns_screen.dart';
import 'campaign_details_screen.dart';
import 'saloons_screen.dart';
import 'wallet_screen.dart';
import 'influencer_language_screen.dart';
import '../../../../core/bloc/influencer_report/influencer_report_bloc.dart';
import '../../../../core/bloc/influencer_report/influencer_report_event.dart';
import '../../../../core/bloc/influencer_report/influencer_report_state.dart';
import '../../../../core/bloc/delete_campaign/delete_campaign_bloc.dart';
import '../../../../core/bloc/influencer_account_deletion/influencer_account_deletion_bloc.dart';
import '../../../../core/bloc/theme/theme_bloc.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import '../../../../widgets/common/account_deletion_dialog.dart';
import '../../../../widgets/common/motivational_banner.dart';

class InfluencerHomeScreen extends StatefulWidget {
  const InfluencerHomeScreen({super.key});

  @override
  State<InfluencerHomeScreen> createState() => _InfluencerHomeScreenState();
}

class _InfluencerHomeScreenState extends State<InfluencerHomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _reportController = TextEditingController();

  // Stats data
  Map<String, dynamic> _stats = {};
  String _statsErrorMessage = '';
  bool _isLoadingStats = true;

  // Campaigns data
  List<dynamic> _campaigns = [];
  String _campaignsErrorMessage = '';
  bool _isLoadingCampaigns = true;

  @override
  void initState() {
    super.initState();
    // Load profile data using BLoC
    context.read<InfluencerProfileBloc>().add(LoadInfluencerProfile());
    // Load stats data
    _loadStats();
    // Load campaigns data
    _loadCampaigns();
  }

  Future<void> _loadStats() async {
    try {
      print('📊 === LOADING INFLUENCER HOME STATS ===');

      final statsResult = await InfluencerWalletService.getHomeStats();

      if (mounted) {
        if (statsResult['success'] == true) {
          _stats = statsResult['data'] as Map<String, dynamic>;
          _statsErrorMessage = '';
          print('📊 Home stats loaded successfully: $_stats');
        } else {
          _statsErrorMessage = statsResult['message'] ?? 'Failed to load stats';
          print('❌ Failed to load home stats: ${statsResult['message']}');
        }

        setState(() {
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      print('❌ Error loading home stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
          _statsErrorMessage = 'Error loading stats: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _loadCampaigns() async {
    try {
      print('📋 === LOADING INFLUENCER CAMPAIGNS FOR HOME ===');

      final result = await InfluencersService.getInfluencerCampaigns(
        page: 1,
        limit: 10,
        status: null, // Get all campaigns for filtering
      );

      if (mounted) {
        if (result['success'] == true) {
          _campaigns = List<dynamic>.from(result['data'] ?? []);
          _campaignsErrorMessage = '';
          print(
              '📋 Campaigns loaded successfully: ${_campaigns.length} campaigns');
        } else {
          // Check if it's a 403 error (account not active)
          final statusCode = result['statusCode'] ?? 0;
          if (statusCode == 403) {
            _campaignsErrorMessage =
                AppTranslations.getString(context, 'account_not_active');
          } else {
            _campaignsErrorMessage =
                result['message'] ?? 'Failed to load campaigns';
          }
          print('❌ Failed to load campaigns: ${result['message']}');
        }

        setState(() {
          _isLoadingCampaigns = false;
        });
      }
    } catch (e) {
      print('❌ Error loading campaigns: $e');
      if (mounted) {
        setState(() {
          _isLoadingCampaigns = false;
          _campaignsErrorMessage = 'Error loading campaigns: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
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

  void _showReportBottomSheet(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.getScaffoldBackground(brightness),
      isScrollControlled: true,
      builder: (BuildContext context) {
        final modalBrightness = Theme.of(context).brightness;
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
                color: AppTheme.getScaffoldBackground(modalBrightness),
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
                                  color:
                                      AppTheme.getTextPrimaryColor(brightness),
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
                                  color:
                                      AppTheme.getTextPrimaryColor(brightness),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: modalBrightness == Brightness.light
                                      ? AppTheme.lightCardBackground
                                      : AppTheme.getScaffoldBackground(
                                          Theme.of(context).brightness),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: modalBrightness == Brightness.light
                                        ? AppTheme.lightTextPrimaryColor
                                        : AppTheme.accentColor,
                                    width: 1,
                                  ),
                                ),
                                child: TextField(
                                  controller: _reportController,
                                  maxLines: 6,
                                  maxLength: 100,
                                  style: TextStyle(
                                    color: modalBrightness == Brightness.light
                                        ? AppTheme.lightTextPrimaryColor
                                        : AppTheme.getTextPrimaryColor(
                                            Theme.of(context).brightness),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: AppTranslations.getString(
                                        context, 'describe_your_problem'),
                                    hintStyle: TextStyle(
                                      color: modalBrightness == Brightness.light
                                          ? AppTheme.lightTextSecondaryColor
                                          : AppTheme.getTextPrimaryColor(
                                                  Theme.of(context).brightness)
                                              .withOpacity(0.5),
                                    ),
                                    counterStyle: TextStyle(
                                      color: modalBrightness == Brightness.light
                                          ? AppTheme.lightTextSecondaryColor
                                          : AppTheme.getTextPrimaryColor(
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
                                          color: modalBrightness ==
                                                  Brightness.light
                                              ? AppTheme.lightCardBackground
                                              : AppTheme.getScaffoldBackground(
                                                  Theme.of(context).brightness),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: modalBrightness ==
                                                    Brightness.light
                                                ? AppTheme.lightTextPrimaryColor
                                                : AppTheme.accentColor,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          AppTranslations.getString(
                                              context, 'cancel'),
                                          style: TextStyle(
                                            color: modalBrightness ==
                                                    Brightness.light
                                                ? AppTheme.lightTextPrimaryColor
                                                : AppTheme.getTextPrimaryColor(
                                                    brightness),
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
                                        color:
                                            modalBrightness == Brightness.light
                                                ? AppTheme.lightTextPrimaryColor
                                                : AppTheme.getTextPrimaryColor(
                                                    brightness),
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
                                                  color: modalBrightness ==
                                                          Brightness.light
                                                      ? AppTheme
                                                          .lightCardBackground
                                                      : AppTheme
                                                          .lightTextPrimaryColor,
                                                ),
                                              )
                                            : Text(
                                                AppTranslations.getString(
                                                    this.context, 'submit'),
                                                style: TextStyle(
                                                  color: modalBrightness ==
                                                          Brightness.light
                                                      ? AppTheme
                                                          .lightCardBackground
                                                      : AppTheme
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
    return RefreshIndicator(
      onRefresh: _refreshHomeData,
      color: AppTheme.greenPrimary,
      backgroundColor:
          AppTheme.getScaffoldBackground(Theme.of(context).brightness),
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh even when content doesn't fill screen
        padding: const EdgeInsets.only(bottom: 90), // Add padding for navbar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 20),
            _buildDashboardCards(),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: MotivationalBanner(
                text: AppTranslations.getString(context, 'share_more_win_more'),
              ),
            ),
            SizedBox(height: 24),
            _buildOngoingCampaign(),
            SizedBox(height: 20),
            _buildReceivedInvitations(),
          ],
        ),
      ),
    );
  }

  Widget _buildSaloonsContent() {
    return const SaloonsScreen();
  }

  Widget _buildCampaignContent() {
    return const CampaignsScreen();
  }

  Widget _buildWalletContent() {
    return const WalletScreen();
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 90), // Add padding for navbar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          SizedBox(height: 16),
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
                    decoration: BoxDecoration(
                      color: AppTheme.borderColorLight,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.getTextPrimaryColor(
                            Theme.of(context).brightness),
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
                          decoration: BoxDecoration(
                            color: AppTheme.getPlaceholderBackground(
                                Theme.of(context).brightness),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person,
                            color: AppTheme.getTextPrimaryColor(
                                Theme.of(context).brightness),
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
                              decoration: BoxDecoration(
                                color: AppTheme.getPlaceholderBackground(
                                    Theme.of(context).brightness),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                color: AppTheme.getTextPrimaryColor(
                                    Theme.of(context).brightness),
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
                  decoration: BoxDecoration(
                    color: AppTheme.getPlaceholderBackground(
                        Theme.of(context).brightness),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: AppTheme.getTextPrimaryColor(
                        Theme.of(context).brightness),
                    size: 24,
                  ),
                );
              },
            ),
          ),
          SizedBox(width: 12),
          BlocBuilder<InfluencerProfileBloc, InfluencerProfileState>(
            builder: (context, state) {
              String displayName =
                  AppTranslations.getString(context, 'loading');

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
                  Text(
                    AppTranslations.getString(context, 'good_morning'),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.textWhite70
                          : AppTheme.lightTextSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    displayName,
                    style: TextStyle(
                      color: AppTheme.getTextPrimaryColor(
                          Theme.of(context).brightness),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              );
            },
          ),
          Spacer(),
          // Notification icon hidden as requested
          // Icon(Icons.notifications_outlined,
          //     color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness), size: 26),
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
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppTheme.getBorderColor(
                            Theme.of(context).brightness),
                        width: 2),
                    color: !_isValidProfilePictureUrl(profilePicture)
                        ? AppTheme.getPlaceholderBackground(
                            Theme.of(context).brightness)
                        : null,
                  ),
                  child: !_isValidProfilePictureUrl(profilePicture)
                      ? Icon(
                          Icons.person,
                          color: AppTheme.getTextPrimaryColor(
                              Theme.of(context).brightness),
                          size: 30,
                        )
                      : ClipOval(
                          child: Image.network(
                            profilePicture,
                            width: 72,
                            height: 72,
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

          SizedBox(height: 16),

          // Display Name
          Center(
            child: BlocBuilder<InfluencerProfileBloc, InfluencerProfileState>(
              builder: (context, state) {
                String displayName =
                    AppTranslations.getString(context, 'loading');

                if (state is InfluencerProfileLoaded ||
                    state is InfluencerProfileUpdated) {
                  final profileData = state is InfluencerProfileUpdated
                      ? state.updatedProfile
                      : state as InfluencerProfileLoaded;
                  displayName = profileData.name.isNotEmpty
                      ? profileData.name
                      : AppTranslations.getString(context, 'unknown_user');
                }

                return Text(
                  displayName,
                  style: AppTheme.headingStyle.copyWith(
                    color: AppTheme.getTextPrimaryColor(
                        Theme.of(context).brightness),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 8),

          // Username Handle
          Center(
            child: BlocBuilder<InfluencerProfileBloc, InfluencerProfileState>(
              builder: (context, state) {
                String username = AppTranslations.getString(context, 'loading');

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
                    color: AppTheme.getSecondaryColor(
                        Theme.of(context).brightness),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.getBorderColor(
                                Theme.of(context).brightness)
                            .withOpacity(0.1)),
                  ),
                  child: Text(
                    "@$username",
                    style: AppTheme.subtitleStyle.copyWith(
                      color: AppTheme.getTextPrimaryColor(
                          Theme.of(context).brightness),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildThemeOption(),
          SizedBox(height: 10),
          _buildProfileOption(
            icon: LucideIcons.personStanding,
            title: AppTranslations.getString(context, 'personal_information'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PersonalInformationScreen(),
                ),
              );
            },
          ),
          SizedBox(height: 10),
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
          SizedBox(height: 10),
          _buildProfileOption(
            icon: LucideIcons.wallet,
            title: AppTranslations.getString(context, 'payment_information'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentInformationScreen(),
                ),
              );
            },
          ),
          SizedBox(height: 10),
          _buildProfileOption(
            icon: Icons.shield_outlined,
            title: AppTranslations.getString(context, 'security'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SecurityScreen(),
                ),
              );
            },
          ),
          SizedBox(height: 10),
          _buildProfileOption(
            icon: LucideIcons.messageSquare,
            title: AppTranslations.getString(context, 'report'),
            onTap: () {
              _showReportBottomSheet(context);
            },
          ),
          SizedBox(height: 10),
          _buildProfileOption(
            icon: LucideIcons.languages,
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
          SizedBox(height: 10),

          // Notification button hidden as requested
          // SizedBox(height: 7),
          // _buildProfileOption(
          //   icon: Icons.notifications_outlined,
          //   title: AppTranslations.getString(context, 'notifications'),
          //   onTap: () {
          //     // Handle notifications
          //   },
          // ),
          // SizedBox(height: 7),
          _buildProfileOption(
            icon: Icons.delete_forever,
            title: AppTranslations.getString(context, 'delete_account'),
            onTap: () {
              _showAccountDeletionDialog(context);
            },
            isDestructive: true,
          ),
          SizedBox(height: 10),
          _buildProfileOption(
            icon: Icons.logout,
            title: AppTranslations.getString(context, 'logout'),
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

  Widget _buildThemeOption() {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final isDarkMode = themeState.brightness == Brightness.dark;
        final brightness = Theme.of(context).brightness;
        return GestureDetector(
          onTap: () {
            final newBrightness =
                isDarkMode ? Brightness.light : Brightness.dark;
            context.read<ThemeBloc>().add(ChangeTheme(newBrightness));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: brightness == Brightness.light
                  ? AppTheme.lightCardBackground
                  : AppTheme.getSecondaryColor(brightness),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: brightness == Brightness.light
                      ? AppTheme.lightCardBorderColor
                      : AppTheme.getBorderColor(brightness).withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: brightness == Brightness.light
                      ? AppTheme.lightTextPrimaryColor
                      : AppTheme.getTextPrimaryColor(brightness),
                  size: 24,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppTranslations.getString(context, 'appearance'),
                        style: AppTheme.subtitleStyle.copyWith(
                          color: brightness == Brightness.light
                              ? AppTheme.lightTextPrimaryColor
                              : AppTheme.getTextPrimaryColor(brightness),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        isDarkMode
                            ? AppTranslations.getString(context, 'dark_mode')
                            : AppTranslations.getString(context, 'light_mode'),
                        style: TextStyle(
                          color: brightness == Brightness.light
                              ? AppTheme.lightTextSecondaryColor
                              : AppTheme.getTextSecondaryColor(brightness),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: !isDarkMode,
                  onChanged: (value) {
                    final newBrightness =
                        value ? Brightness.light : Brightness.dark;
                    context.read<ThemeBloc>().add(ChangeTheme(newBrightness));
                  },
                  activeColor: AppTheme.greenPrimary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? AppTheme.lightBannerBackground
              : AppTheme.getSecondaryColor(Theme.of(context).brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Theme.of(context).brightness == Brightness.light
                  ? AppTheme.lightCardBorderColor
                  : AppTheme.getBorderColor(Theme.of(context).brightness)
                      .withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: (isLogout || isDestructive)
                  ? AppTheme.errorColor
                  : Theme.of(context).brightness == Brightness.light
                      ? AppTheme.lightTextPrimaryColor
                      : AppTheme.getTextPrimaryColor(
                          Theme.of(context).brightness),
              size: 24,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTheme.subtitleStyle.copyWith(
                  color: (isLogout || isDestructive)
                      ? AppTheme.errorColor
                      : Theme.of(context).brightness == Brightness.light
                          ? AppTheme.lightTextPrimaryColor
                          : AppTheme.getTextPrimaryColor(
                              Theme.of(context).brightness),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: (isLogout || isDestructive)
                  ? AppTheme.errorColor
                  : Theme.of(context).brightness == Brightness.light
                      ? AppTheme.lightTextPrimaryColor
                      : AppTheme.getTextPrimaryColor(
                          Theme.of(context).brightness),
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
          _buildStatCard(
            _isLoadingStats
                ? AppTranslations.getString(context, 'loading')
                : _statsErrorMessage.isNotEmpty || _stats.isEmpty
                    ? "--"
                    : "€ ${(_stats['totalRevenue']?['totalRevenue'] ?? 0.0).toStringAsFixed(0)}",
            AppTranslations.getString(context, 'total_revenue'),
            Icons.euro,
          ),
          SizedBox(width: 12),
          _buildStatCard(
            _isLoadingStats
                ? AppTranslations.getString(context, 'loading')
                : _statsErrorMessage.isNotEmpty || _stats.isEmpty
                    ? "--"
                    : "${_stats['totalOrders']?['totalOrders'] ?? 0}",
            AppTranslations.getString(context, 'total_orders'),
            Icons.groups_2_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String title, IconData icon) {
    final isLoading = value == AppTranslations.getString(context, 'loading');
    final brightness = Theme.of(context).brightness;
    // In dark mode: white background with black text (original design)
    // In light mode: white background with black text
    final backgroundColor = brightness == Brightness.dark
        ? AppTheme.getTextPrimaryColor(brightness) // White in dark mode
        : AppTheme.getCardBackground(brightness); // White in light mode
    final textColor = brightness == Brightness.dark
        ? AppTheme.textBlack87 // Black text in dark mode
        : AppTheme.getTextPrimaryColor(brightness); // Black text in light mode

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: brightness == Brightness.light
              ? Border.all(color: AppTheme.lightCardBorderColor)
              : null,
        ),
        child: isLoading
            ? _buildShimmerStatCard()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: value == "Error"
                                ? AppTheme.statusRed
                                : textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(icon,
                          color:
                              value == "Error" ? AppTheme.statusRed : textColor,
                          size: 22),
                    ],
                  ),
                  SizedBox(height: 10),

                  // Real chart using stats API data
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CustomPaint(
                      painter: _HomeChartPainter(
                        dailyData: title ==
                                AppTranslations.getString(
                                    context, 'total_revenue')
                            ? (_stats['totalRevenue']?['dailyRevenue'] ?? [])
                            : (_stats['totalOrders']?['dailyOrders'] ?? []),
                        isRevenue: title ==
                            AppTranslations.getString(context, 'total_revenue'),
                      ),
                      size: const Size(double.infinity, 56),
                    ),
                  ),

                  SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildShimmerStatCard() {
    return Shimmer.fromColors(
      baseColor: AppTheme.getShimmerBase(Theme.of(context).brightness),
      highlightColor:
          AppTheme.getShimmerHighlight(Theme.of(context).brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Value shimmer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 80,
                height: 22,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.getSecondaryColor(Theme.of(context).brightness)
                      : AppTheme.getTextPrimaryColor(
                          Theme.of(context).brightness),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.getSecondaryColor(Theme.of(context).brightness)
                      : AppTheme.getTextPrimaryColor(
                          Theme.of(context).brightness),
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),

          // Chart shimmer
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.getSecondaryColor(Theme.of(context).brightness)
                  : AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              borderRadius: BorderRadius.circular(12),
            ),
          ),

          SizedBox(height: 10),

          // Title shimmer
          Container(
            width: 100,
            height: 15,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.getSecondaryColor(Theme.of(context).brightness)
                  : AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  /// ONGOING CAMPAIGN
  Widget _buildOngoingCampaign() {
    if (_isLoadingCampaigns) {
      return _buildShimmerCampaignCard();
    }

    if (_campaignsErrorMessage.isNotEmpty) {
      return _buildErrorCard(_campaignsErrorMessage);
    }

    final ongoingCampaign = _getLastOngoingCampaign();

    if (ongoingCampaign == null) {
      return _buildEmptyCard(
          AppTranslations.getString(context, 'no_ongoing_campaigns'));
    }

    return _buildCampaignCard(
      campaign: ongoingCampaign,
      title: AppTranslations.getString(context, 'ongoing_campaign'),
      icon: LucideIcons.playCircle,
      color: AppTheme.greenPrimary,
    );
  }

  /// RECEIVED INVITATIONS
  Widget _buildReceivedInvitations() {
    if (_isLoadingCampaigns) {
      return _buildShimmerCampaignCard();
    }

    // Don't show error for account not active in received invitations
    // since it's already shown in ongoing campaigns section
    if (_campaignsErrorMessage.isNotEmpty) {
      final isAccountNotActive =
          _campaignsErrorMessage.toLowerCase().contains('account not active') ||
              _campaignsErrorMessage.toLowerCase().contains('compte non actif');
      if (isAccountNotActive) {
        return const SizedBox
            .shrink(); // Hide this section for account not active
      }
      return _buildErrorCard(_campaignsErrorMessage);
    }

    final invitation = _getLastReceivedInvitation();

    if (invitation == null) {
      return _buildEmptyCard(
          AppTranslations.getString(context, 'no_pending_invitations'));
    }

    return _buildCampaignCard(
      campaign: invitation,
      title: AppTranslations.getString(context, 'received_invitation'),
      icon: LucideIcons.mail,
      color: AppTheme.statusBlue,
    );
  }

  /// BOTTOM NAVIGATION WITH GREEN HALF-CIRCLE GLOW
  Widget _buildBottomNavigation() {
    final width = MediaQuery.of(context).size.width;
    final itemWidth = width / 5;

    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.getScaffoldBackground(Theme.of(context).brightness),
        border: Border(
          top: BorderSide(
              color: AppTheme.getBorderColor(Theme.of(context).brightness)
                  .withOpacity(0.08),
              width: 1),
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
                  child: _navItem(0, LucideIcons.clipboardList,
                      AppTranslations.getString(context, 'home')),
                ),
                Expanded(
                  child: _navItem(1, LucideIcons.store,
                      AppTranslations.getString(context, 'saloons')),
                ),
                Expanded(
                  child: _navItem(2, LucideIcons.ticket,
                      AppTranslations.getString(context, 'campaign')),
                ),
                Expanded(
                  child: _navItem(3, LucideIcons.wallet,
                      AppTranslations.getString(context, 'wallet')),
                ),
                Expanded(
                  child: _navItem(4, LucideIcons.user,
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
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor:
          AppTheme.getScaffoldBackground(Theme.of(context).brightness),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.getScaffoldBackground(Theme.of(context).brightness),
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
                    AppTranslations.getString(context, 'are_you_sure_logout'),
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
                                Theme.of(context).brightness == Brightness.light
                                    ? AppTheme.lightCardBackground
                                    : AppTheme.transparentBackground,
                            border: Border.all(
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? AppTheme.lightTextPrimaryColor
                                    : AppTheme.getBorderColor(
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
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? AppTheme.lightTextPrimaryColor
                                    : AppTheme.getTextPrimaryColor(
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
                            color: AppTheme.errorColor,
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
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  AppTranslations.getString(
                                      context, 'yes_logout'),
                                  style: TextStyle(
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
            content: Text(
                '${AppTranslations.getString(context, 'logout_failed')}: ${e.toString()}'),
            backgroundColor: AppTheme.statusRed,
          ),
        );
      }
    }
  }

  void _showAccountDeletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BlocProvider(
        create: (context) => InfluencerAccountDeletionBloc(),
        child: const AccountDeletionDialog(userType: 'influencer'),
      ),
    );
  }

  /// Get the last ongoing campaign
  Map<String, dynamic>? _getLastOngoingCampaign() {
    if (_campaigns.isEmpty) return null;

    // Filter for ongoing campaigns (status: 'in progress') - same logic as campaigns screen
    final ongoingCampaigns = _campaigns.where((campaign) {
      final status = campaign['status']?.toString().toLowerCase();
      return status == 'in progress';
    }).toList();

    if (ongoingCampaigns.isEmpty) return null;

    // Sort by creation date (newest first) and return the first one
    ongoingCampaigns.sort((a, b) {
      final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(1970);
      final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });

    return ongoingCampaigns.first;
  }

  /// Get the last received invitation
  Map<String, dynamic>? _getLastReceivedInvitation() {
    if (_campaigns.isEmpty) return null;

    // Filter for received invitations (initiator: 'salon' && status: 'pending') - same logic as campaigns screen
    final receivedInvitations = _campaigns.where((campaign) {
      final status = campaign['status']?.toString().toLowerCase();
      final initiator = campaign['initiator']?.toString().toLowerCase();
      return initiator == 'salon' && status == 'pending';
    }).toList();

    if (receivedInvitations.isEmpty) return null;

    // Sort by creation date (newest first) and return the first one
    receivedInvitations.sort((a, b) {
      final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(1970);
      final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });

    return receivedInvitations.first;
  }

  /// Format date
  String _formatDate(String? dateString) {
    if (dateString == null)
      return AppTranslations.getString(context, 'unknown');

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} ${difference.inDays == 1 ? AppTranslations.getString(context, 'day_ago') : AppTranslations.getString(context, 'days_ago')}';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ${difference.inHours == 1 ? AppTranslations.getString(context, 'hour_ago') : AppTranslations.getString(context, 'hours_ago')}';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? AppTranslations.getString(context, 'minute_ago') : AppTranslations.getString(context, 'minutes_ago')}';
      } else {
        return AppTranslations.getString(context, 'just_now');
      }
    } catch (e) {
      return AppTranslations.getString(context, 'unknown');
    }
  }

  /// Build campaign card
  /// Get promotion icon based on promotionType
  IconData _getPromotionIcon(Map<String, dynamic> campaign) {
    final promotionType = campaign['promotionType']?.toString().toLowerCase();
    if (promotionType == 'percentage') {
      return LucideIcons.percent;
    } else {
      return LucideIcons.euro;
    }
  }

  /// Get promotion text based on promotionType
  String _getPromotionText(Map<String, dynamic> campaign) {
    final promotionType = campaign['promotionType']?.toString().toLowerCase();
    final promotionValue = campaign['promotion'] ?? '0';

    if (promotionType == 'percentage') {
      return '$promotionValue';
    } else {
      return '$promotionValue';
    }
  }

  /// Get translated status text
  String _getTranslatedStatus(String? status) {
    if (status == null) return AppTranslations.getString(context, 'pending');

    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'pending':
        return AppTranslations.getString(context, 'pending');
      case 'in progress':
      case 'ongoing':
        return AppTranslations.getString(context, 'on_going_status');
      case 'accepted':
        return AppTranslations.getString(context, 'accepted');
      case 'rejected':
        return AppTranslations.getString(context, 'rejected');
      case 'finished':
        return AppTranslations.getString(context, 'finished');
      default:
        return status.toUpperCase();
    }
  }

  Widget _buildCampaignCard({
    required Map<String, dynamic> campaign,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => DeleteCampaignBloc(),
                    child: CampaignDetailsScreen(
                      campaign: campaign,
                      onCampaignDeleted: () {
                        // Refresh campaigns when a campaign is deleted
                        // You can add refresh logic here if needed
                      },
                    ),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.getSecondaryColor(Theme.of(context).brightness)
                    : AppTheme.lightCardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.getBorderColor(Theme.of(context).brightness)
                            .withOpacity(0.12)
                        : AppTheme.lightCardBorderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          campaign['salon']?['salonInfo']?['name'] ??
                              AppTranslations.getString(
                                  context, 'campaign_title'),
                          style: TextStyle(
                            color: AppTheme.getTextPrimaryColor(
                                Theme.of(context).brightness),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getTranslatedStatus(campaign['status']?.toString()),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    campaign['invitationMessage'] ??
                        AppTranslations.getString(
                            context, 'no_description_available'),
                    style: TextStyle(
                      color: AppTheme.getTextSecondaryColor(
                          Theme.of(context).brightness),
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      // Show different icon based on promotionType
                      Icon(_getPromotionIcon(campaign),
                          size: 16,
                          color: AppTheme.getTextSecondaryColor(
                              Theme.of(context).brightness)),
                      SizedBox(width: 4),
                      Text(
                        _getPromotionText(campaign),
                        style: TextStyle(
                          color: AppTheme.getTextPrimaryColor(
                              Theme.of(context).brightness),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Spacer(),
                      Text(
                        _formatDate(campaign['createdAt']),
                        style: TextStyle(
                          color: AppTheme.getTextSecondaryColor(
                              Theme.of(context).brightness),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build loading card
  Widget _buildLoadingCard(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.getSecondaryColor(Theme.of(context).brightness),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Shimmer.fromColors(
          baseColor: AppTheme.getShimmerBase(Theme.of(context).brightness),
          highlightColor:
              AppTheme.getShimmerHighlight(Theme.of(context).brightness),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.getSecondaryColor(Theme.of(context).brightness)
                      : AppTheme.getTextPrimaryColor(
                          Theme.of(context).brightness),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.getSecondaryColor(
                            Theme.of(context).brightness)
                        : AppTheme.getTextPrimaryColor(
                            Theme.of(context).brightness),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build shimmer campaign card
  Widget _buildShimmerCampaignCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title shimmer
          Shimmer.fromColors(
            baseColor: AppTheme.getShimmerBase(Theme.of(context).brightness),
            highlightColor:
                AppTheme.getShimmerHighlight(Theme.of(context).brightness),
            child: Container(
              width: 150,
              height: 22,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.getSecondaryColor(Theme.of(context).brightness)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          SizedBox(height: 14),
          // Card shimmer
          Shimmer.fromColors(
            baseColor: AppTheme.getShimmerBase(Theme.of(context).brightness),
            highlightColor:
                AppTheme.getShimmerHighlight(Theme.of(context).brightness),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.getSecondaryColor(Theme.of(context).brightness)
                    : AppTheme.getTextPrimaryColor(
                        Theme.of(context).brightness),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row shimmer
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.getSecondaryColor(
                                  Theme.of(context).brightness)
                              : AppTheme.getTextPrimaryColor(
                                  Theme.of(context).brightness),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 18,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppTheme.getSecondaryColor(
                                        Theme.of(context).brightness)
                                    : AppTheme.getTextPrimaryColor(
                                        Theme.of(context).brightness),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        width: 60,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.getSecondaryColor(
                                  Theme.of(context).brightness)
                              : AppTheme.getTextPrimaryColor(
                                  Theme.of(context).brightness),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Description shimmer
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppTheme.getTextPrimaryColor(
                          Theme.of(context).brightness),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 12),
                  // Bottom row shimmer
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.getSecondaryColor(
                                  Theme.of(context).brightness)
                              : AppTheme.getTextPrimaryColor(
                                  Theme.of(context).brightness),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      SizedBox(width: 4),
                      Container(
                        width: 80,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppTheme.getTextPrimaryColor(
                              Theme.of(context).brightness),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Spacer(),
                      Container(
                        width: 60,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppTheme.getTextPrimaryColor(
                              Theme.of(context).brightness),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build error card
  Widget _buildErrorCard(String message) {
    // Check if it's an account not active error
    final isAccountNotActive =
        message.toLowerCase().contains('account not active') ||
            message.toLowerCase().contains('compte non actif');

    if (isAccountNotActive) {
      return SizedBox(
        height: 300, // Use more screen space
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  size: 80, // Larger icon
                  color: AppTheme.greenColor,
                ),
                SizedBox(height: 24),
                Text(
                  AppTranslations.getString(context, 'account_not_active'),
                  style: AppTheme.applyPoppins(TextStyle(
                    color: AppTheme.getTextPrimaryColor(
                        Theme.of(context).brightness),
                    fontSize: 20, // Larger text
                    fontWeight: FontWeight.bold,
                  )),
                ),
                SizedBox(height: 12),
                Text(
                  AppTranslations.getString(context, 'account_not_active'),
                  style: AppTheme.applyPoppins(TextStyle(
                    color: AppTheme.greenColor,
                    fontSize: 16, // Larger subtitle
                  )),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.statusRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: AppTheme.statusRed, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.statusRed,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty card
  Widget _buildEmptyCard(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.borderColorLight.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(Icons.info, color: AppTheme.shimmerBaseMedium, size: 20),
            SizedBox(width: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.getTextSecondaryColor(
                        Theme.of(context).brightness)
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Refresh home data
  Future<void> _refreshHomeData() async {
    print('🔄 === REFRESHING HOME DATA ===');
    try {
      // Reload stats and campaigns data
      await Future.wait([
        _loadStats(),
        _loadCampaigns(),
      ]);
      print('✅ Home data refreshed successfully');
    } catch (e) {
      print('❌ Error refreshing home data: $e');
    }
  }
}

class _HomeChartPainter extends CustomPainter {
  final List<dynamic> dailyData;
  final bool isRevenue;

  _HomeChartPainter({
    required this.dailyData,
    required this.isRevenue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Process daily data from home stats API
    List<double> values = [];
    if (dailyData.isNotEmpty) {
      for (var day in dailyData) {
        if (day is Map<String, dynamic>) {
          if (isRevenue) {
            values.add((day['revenue'] ?? 0.0).toDouble());
          } else {
            // For orders, use the count field
            values.add((day['count'] ?? 0.0).toDouble());
          }
        }
      }
    }

    // If no data, create a flat line
    if (values.isEmpty) {
      values = List.filled(30, 0.0);
    }

    // Find max value for scaling
    double maxValue =
        values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 1.0;
    if (maxValue == 0) maxValue = 1.0; // Avoid division by zero

    // Create path based on actual data from stats API with smooth curves
    final path = Path();
    final linePath = Path();

    // Check if we have real data (not all zeros)
    final hasRealData = maxValue > 0;

    if (!hasRealData) {
      // If no real data, draw a flat line at the bottom
      path.moveTo(0, size.height * 0.9);
      path.lineTo(size.width, size.height * 0.9);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      linePath.moveTo(0, size.height * 0.9);
      linePath.lineTo(size.width, size.height * 0.9);
    } else {
      // Calculate data points
      List<Offset> dataPoints = [];
      for (int i = 0; i < values.length; i++) {
        double x = (i / (values.length - 1)) * size.width;
        double normalizedValue = values[i] / maxValue;
        double y = size.height -
            (normalizedValue * size.height * 0.8) -
            (size.height * 0.1);
        dataPoints.add(Offset(x, y));
      }

      // Create smooth curves using cubic Bézier
      if (dataPoints.isNotEmpty) {
        path.moveTo(dataPoints[0].dx, dataPoints[0].dy);
        linePath.moveTo(dataPoints[0].dx, dataPoints[0].dy);

        for (int i = 1; i < dataPoints.length; i++) {
          final current = dataPoints[i];
          final previous = dataPoints[i - 1];

          // Calculate control points for smooth curves
          double tension = 0.3; // Controls curve smoothness
          double controlPointOffset = (current.dx - previous.dx) * tension;

          Offset controlPoint1, controlPoint2;

          if (i == 1) {
            // First curve segment
            controlPoint1 = Offset(
              previous.dx + controlPointOffset,
              previous.dy,
            );
            controlPoint2 = Offset(
              current.dx - controlPointOffset,
              current.dy,
            );
          } else if (i == dataPoints.length - 1) {
            // Last curve segment
            controlPoint1 = Offset(
              previous.dx + controlPointOffset,
              previous.dy,
            );
            controlPoint2 = Offset(
              current.dx - controlPointOffset,
              current.dy,
            );
          } else {
            // Middle curve segments
            final next = dataPoints[i + 1];
            final prev = dataPoints[i - 1];

            controlPoint1 = Offset(
              previous.dx + (current.dx - prev.dx) * tension,
              previous.dy + (current.dy - prev.dy) * tension,
            );
            controlPoint2 = Offset(
              current.dx - (next.dx - previous.dx) * tension,
              current.dy - (next.dy - previous.dy) * tension,
            );
          }

          path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx,
              controlPoint2.dy, current.dx, current.dy);
          linePath.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx,
              controlPoint2.dy, current.dx, current.dy);
        }
      }
    }

    // Close the path for fill
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Create gradient fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.greenPrimary.withOpacity(0.6),
          AppTheme.greenPrimary.withOpacity(0.22),
          AppTheme.greenPrimary.withOpacity(0.06),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppTheme.greenPrimary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw fill
    canvas.drawPath(path, fillPaint);

    // Draw line
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is _HomeChartPainter) {
      return oldDelegate.dailyData != dailyData ||
          oldDelegate.isRevenue != isRevenue;
    }
    return true;
  }
}
