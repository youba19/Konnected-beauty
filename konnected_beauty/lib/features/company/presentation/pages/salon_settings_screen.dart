import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:konnected_beauty/features/company/presentation/pages/salon_security_screen.dart';
import 'package:konnected_beauty/features/company/presentation/pages/salon_information_screen.dart';
import 'package:konnected_beauty/features/company/presentation/pages/salon_payment_information_screen.dart';
import 'package:konnected_beauty/features/company/presentation/pages/language_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/services/storage/token_storage_service.dart';
import '../../../../core/services/api/salon_profile_service.dart';
import 'salon_profile_details_screen.dart';
import '../../../../core/bloc/auth/auth_bloc.dart';
import '../../../auth/presentation/pages/welcome_screen.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import '../../../../core/bloc/salon_report/salon_report_bloc.dart';
import '../../../../core/bloc/salon_report/salon_report_event.dart';
import '../../../../core/bloc/salon_report/salon_report_state.dart';
import '../../../../core/bloc/salon_account_deletion/salon_account_deletion_bloc.dart';
import '../../../../widgets/common/account_deletion_dialog.dart';

class SalonSettingsScreen extends StatefulWidget {
  const SalonSettingsScreen({super.key});

  @override
  State<SalonSettingsScreen> createState() => _SalonSettingsScreenState();
}

class _SalonSettingsScreenState extends State<SalonSettingsScreen> {
  final SalonProfileService _salonProfileService = SalonProfileService();
  final TextEditingController _reportController = TextEditingController();

  String _personalName = '';
  String _salonName = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSalonProfile();
  }

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
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
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.wifi_off,
                                    size: 64,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Connection Problem',
                                    style: TextStyle(
                                      color: AppTheme.textPrimaryColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Please check your internet connection and try again.',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _loadSalonProfile,
                                    icon: const Icon(Icons.refresh),
                                    label: Text(AppTranslations.getString(
                                        context, 'retry')),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accentColor,
                                      foregroundColor: AppTheme.primaryColor,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                                icon: LucideIcons.store,
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
                                icon: LucideIcons.wallet,
                                title: AppTranslations.getString(
                                    context, 'payment_information'),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SalonPaymentInformationScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildSettingsOption(
                                icon: LucideIcons.languages,
                                title: AppTranslations.getString(
                                    context, 'language'),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const LanguageScreen(),
                                    ),
                                  );
                                },
                              ),

                              // Divider between notifications and report
                              Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.2),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 20),
                              ),

                              // Report Button
                              _buildSettingsOption(
                                icon: LucideIcons.messageSquare,
                                title: AppTranslations.getString(
                                    context, 'report'),
                                onTap: () {
                                  _showReportBottomSheet(context);
                                },
                              ),
                              const SizedBox(height: 12),

                              // Account Deletion Button
                              _buildSettingsOption(
                                icon: LucideIcons.trash2,
                                title: AppTranslations.getString(
                                    context, 'delete_account'),
                                onTap: () {
                                  _showAccountDeletionDialog(context);
                                },
                                isDestructive: true,
                              ),
                              const SizedBox(height: 12),

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

  void _showReportBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.scaffoldBackground,
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
              decoration: const BoxDecoration(
                color: AppTheme.scaffoldBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 24.0,
                    top: 24.0,
                    right: 24.0,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
                  ),
                  child: BlocProvider(
                    create: (_) => SalonReportBloc(),
                    child: BlocConsumer<SalonReportBloc, SalonReportState>(
                      listener: (context, state) {
                        if (state is SalonReportSuccess) {
                          Navigator.of(context).pop();
                          _reportController.clear();
                          TopNotificationService.showSuccess(
                            context: this.context,
                            message: AppTranslations.getString(
                                this.context, 'report_submitted_successfully'),
                          );
                        } else if (state is SalonReportError) {
                          TopNotificationService.showError(
                            context: this.context,
                            message: state.message,
                          );
                        }
                      },
                      builder: (context, state) {
                        final bool isLoading = state is SalonReportLoading;
                        final brightness = Theme.of(context).brightness;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.getString(context, 'report'),
                              style: TextStyle(
                                color: brightness == Brightness.light
                                    ? AppTheme.lightTextPrimaryColor
                                    : Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppTranslations.getString(
                                  context, 'report_subtitle'),
                              style: TextStyle(
                                color: brightness == Brightness.light
                                    ? AppTheme.lightTextSecondaryColor
                                    : Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppTranslations.getString(context, 'report'),
                              style: TextStyle(
                                color: brightness == Brightness.light
                                    ? AppTheme.lightTextPrimaryColor
                                    : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: brightness == Brightness.light
                                    ? AppTheme.lightCardBackground
                                    : AppTheme.scaffoldBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: brightness == Brightness.light
                                      ? AppTheme.lightTextPrimaryColor
                                      : const Color(0xFF4A4A4A),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: _reportController,
                                maxLines: 6,
                                maxLength: 100,
                                style: TextStyle(
                                  color: brightness == Brightness.light
                                      ? AppTheme.lightTextPrimaryColor
                                      : Colors.white,
                                ),
                                decoration: InputDecoration(
                                  hintText: AppTranslations.getString(
                                      context, 'describe_your_problem'),
                                  hintStyle: TextStyle(
                                    color: brightness == Brightness.light
                                        ? AppTheme.lightTextSecondaryColor
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                  counterStyle: TextStyle(
                                    color: brightness == Brightness.light
                                        ? AppTheme.lightTextSecondaryColor
                                        : Colors.white.withOpacity(0.6),
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
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      decoration: BoxDecoration(
                                        color: brightness == Brightness.light
                                            ? AppTheme.lightCardBackground
                                            : AppTheme.scaffoldBackground,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: brightness == Brightness.light
                                              ? AppTheme.lightTextPrimaryColor
                                              : const Color(0xFF4A4A4A),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        AppTranslations.getString(
                                            context, 'cancel'),
                                        style: TextStyle(
                                          color: brightness == Brightness.light
                                              ? AppTheme.lightTextPrimaryColor
                                              : Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: brightness == Brightness.light
                                          ? AppTheme.lightTextPrimaryColor
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TextButton(
                                      onPressed: isLoading
                                          ? null
                                          : () {
                                              final text =
                                                  _reportController.text.trim();
                                              if (text.isEmpty) {
                                                TopNotificationService.showInfo(
                                                  context: this.context,
                                                  message:
                                                      AppTranslations.getString(
                                                          this.context,
                                                          'no_comment'),
                                                );
                                                return;
                                              }
                                              context
                                                  .read<SalonReportBloc>()
                                                  .add(SubmitSalonReport(text));
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
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: brightness ==
                                                        Brightness.light
                                                    ? AppTheme
                                                        .lightCardBackground
                                                    : Colors.black,
                                              ),
                                            )
                                          : Text(
                                              AppTranslations.getString(
                                                  this.context, 'submit'),
                                              style: TextStyle(
                                                color: brightness ==
                                                        Brightness.light
                                                    ? AppTheme
                                                        .lightCardBackground
                                                    : Colors.black,
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
        );
      },
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
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? AppTheme.lightBannerBackground
              : const Color(0xFF363636),
          borderRadius: BorderRadius.circular(12),
          border: Theme.of(context).brightness == Brightness.light
              ? Border.all(
                  color: AppTheme.lightCardBorderColor,
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive
                  ? Colors.red
                  : Theme.of(context).brightness == Brightness.light
                      ? AppTheme.lightTextPrimaryColor
                      : Colors.white,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDestructive
                      ? Colors.red
                      : Theme.of(context).brightness == Brightness.light
                          ? AppTheme.lightTextPrimaryColor
                          : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: isDestructive
                  ? Colors.red
                  : Theme.of(context).brightness == Brightness.light
                      ? AppTheme.lightTextPrimaryColor
                      : Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final brightness = Theme.of(context).brightness;
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
          color: brightness == Brightness.light
              ? AppTheme.lightBannerBackground
              : const Color(0xFF363636),
          borderRadius: BorderRadius.circular(12),
          border: brightness == Brightness.light
              ? Border.all(
                  color: AppTheme.lightCardBorderColor,
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.logOut,
              color: AppTheme.errorColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                AppTranslations.getString(context, 'logout'),
                style: TextStyle(
                  color: AppTheme.errorColor,
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
        final modalBrightness = Theme.of(context).brightness;
        return Container(
          decoration: BoxDecoration(
            color: modalBrightness == Brightness.light
                ? AppTheme.lightCardBackground
                : const Color(0xFF2C2C2C),
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
                      color: modalBrightness == Brightness.light
                          ? AppTheme.lightTextPrimaryColor
                          : Colors.white,
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
                              color: modalBrightness == Brightness.light
                                  ? AppTheme.lightCardBackground
                                  : const Color(0xFF3A3A3A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: modalBrightness == Brightness.light
                                    ? AppTheme.lightTextPrimaryColor
                                    : const Color(0xFF4A4A4A),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              AppTranslations.getString(context, 'cancel'),
                              style: TextStyle(
                                color: modalBrightness == Brightness.light
                                    ? AppTheme.lightTextPrimaryColor
                                    : Colors.white,
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
                            color: AppTheme.errorColor,
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.logout,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    AppTranslations.getString(
                                        context, 'yes_logout'),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
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
          options: 3, // Updated to include payment information
        ),
        const SizedBox(height: 24),
        // Notifications section shimmer
        _buildShimmerSection(
          title: 'Notifications Section',
          options: 1,
        ),
        const SizedBox(height: 24),
        // Report section shimmer
        _buildShimmerSection(
          title: 'Report Section',
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

  void _showAccountDeletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BlocProvider(
        create: (context) => SalonAccountDeletionBloc(),
        child: const AccountDeletionDialog(userType: 'salon'),
      ),
    );
  }
}
