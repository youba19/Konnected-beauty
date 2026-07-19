import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:konnected_beauty/features/company/presentation/pages/salon_security_screen.dart';
import 'package:konnected_beauty/features/company/presentation/pages/salon_information_screen.dart';
import 'package:konnected_beauty/features/company/presentation/pages/salon_payment_information_screen.dart';
import 'package:konnected_beauty/features/company/presentation/pages/salon_notifications_screen.dart';
import 'package:konnected_beauty/features/company/presentation/pages/language_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/theme/theme_bloc.dart';
import '../../../../core/theme/salon_ui_theme.dart';
import '../../../../core/services/storage/token_storage_service.dart';
import '../../../../core/services/api/salon_profile_service.dart';
import '../../../../core/services/api/salon_auth_service.dart';
import 'salon_profile_details_screen.dart';
import '../../../../core/bloc/auth/auth_bloc.dart';
import '../../../auth/presentation/pages/welcome_screen.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import '../../../../core/bloc/salon_report/salon_report_bloc.dart';
import '../../../../core/bloc/salon_report/salon_report_event.dart';
import '../../../../core/bloc/salon_report/salon_report_state.dart';
import '../../../../widgets/common/account_deletion_dialog.dart';

abstract final class _SalonProfileUi {
  static const Color accentOrange = Color(0xFFFF8A3D);
  static const Color logoutRed = Color(0xFFE04B4B);
  static const Color avatarBlue = Color(0xFF3B6FD4);
  static const double radius = 16;
  static const double buttonSize = 48;
  static const double buttonRadius = 14;
}

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

  String get _profileInitial {
    final source = _personalName.trim();
    if (source.isEmpty) return 'K';
    return source[0].toUpperCase();
  }

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
        setState(() {
          _personalName = data['name']?.toString() ?? '';
          _salonName = data['salonInfo']?['name']?.toString() ?? '';
          _isLoading = false;
        });
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
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final ui = SalonUiTheme.from(themeState.brightness);
        final topInset = MediaQuery.paddingOf(context).top;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: ui.systemOverlay,
          child: Scaffold(
            backgroundColor: ui.bg,
            body: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: topInset + 220,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: ui.fullSheetGradient,
                        stops: ui.fullSheetStops,
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: BlocBuilder<LanguageBloc, LanguageState>(
                    builder: (context, languageState) {
                      if (_isLoading) {
                        return _buildShimmerContent(ui);
                      }
                      if (_errorMessage != null) {
                        return _buildErrorState(ui);
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                            child: _buildBackButton(ui),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 32),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildProfileHeader(ui),
                                  const SizedBox(height: 28),
                                  _buildMenuTile(
                                    ui: ui,
                                    icon: LucideIcons.user,
                                    title: AppTranslations.getString(
                                      context,
                                      'profile_details',
                                    ),
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SalonProfileDetailsScreen(),
                                        ),
                                      );
                                      _loadSalonProfile();
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMenuTile(
                                    ui: ui,
                                    icon: LucideIcons.shield,
                                    title: AppTranslations.getString(
                                      context,
                                      'security',
                                    ),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SalonSecurityScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildAppearanceMenuTile(ui),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    child: Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: ui.borderSubtle
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                  _buildSalonSectionHeader(ui),
                                  const SizedBox(height: 12),
                                  _buildMenuTile(
                                    ui: ui,
                                    icon: LucideIcons.store,
                                    title: AppTranslations.getString(
                                      context,
                                      'saloon_information',
                                    ),
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SalonInformationScreen(),
                                        ),
                                      );
                                      _loadSalonProfile();
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMenuTile(
                                    ui: ui,
                                    icon: LucideIcons.wallet,
                                    title: AppTranslations.getString(
                                      context,
                                      'payment_information',
                                    ),
                                    highlightLeft: true,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SalonPaymentInformationScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMenuTile(
                                    ui: ui,
                                    icon: LucideIcons.bell,
                                    title: AppTranslations.getString(
                                      context,
                                      'notifications',
                                    ),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SalonNotificationsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMenuTile(
                                    ui: ui,
                                    icon: LucideIcons.languages,
                                    title: AppTranslations.getString(
                                      context,
                                      'language',
                                    ),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const LanguageScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color:
                                        ui.borderSubtle.withValues(alpha: 0.28),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMenuTile(
                                    ui: ui,
                                    icon: LucideIcons.messageSquare,
                                    title: AppTranslations.getString(
                                      context,
                                      'report',
                                    ),
                                    onTap: () => _showReportBottomSheet(context),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMenuTile(
                                    ui: ui,
                                    icon: LucideIcons.trash2,
                                    title: AppTranslations.getString(
                                      context,
                                      'delete_account',
                                    ),
                                    isDestructive: true,
                                    showChevron: true,
                                    onTap: () =>
                                        _showAccountDeletionDialog(context),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMenuTile(
                                    ui: ui,
                                    icon: LucideIcons.logOut,
                                    title: AppTranslations.getString(
                                      context,
                                      'logout',
                                    ),
                                    isDestructive: true,
                                    showChevron: false,
                                    onTap: () async {
                                      final currentContext = context;
                                      final shouldLogout =
                                          await _showLogoutConfirmation(
                                        currentContext,
                                      );
                                      if (shouldLogout == true &&
                                          currentContext.mounted) {
                                        await _handleLogout(currentContext);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackButton(SalonUiTheme ui) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: _SalonProfileUi.buttonSize,
        height: _SalonProfileUi.buttonSize,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ui.buttonFillTop,
              ui.buttonFillBottom,
            ],
          ),
          borderRadius: BorderRadius.circular(_SalonProfileUi.buttonRadius),
          border: ui.isDark
              ? null
              : Border.all(color: ui.cardBorder, width: 1),
        ),
        alignment: Alignment.center,
        child: Icon(
          LucideIcons.arrowLeft,
          color: ui.buttonIcon,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(SalonUiTheme ui) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: _SalonProfileUi.avatarBlue,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            _profileInitial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            _personalName.isNotEmpty
                ? _personalName
                : AppTranslations.getString(context, 'name'),
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSalonSectionHeader(SalonUiTheme ui) {
    return Text(
      _salonName.isNotEmpty
          ? _salonName
          : AppTranslations.getString(context, 'saloon_name'),
      style: TextStyle(
        color: ui.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildAppearanceMenuTile(SalonUiTheme ui) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final isDarkMode = themeState.brightness == Brightness.dark;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final newBrightness =
                  isDarkMode ? Brightness.light : Brightness.dark;
              context.read<ThemeBloc>().add(ChangeTheme(newBrightness));
            },
            borderRadius: BorderRadius.circular(_SalonProfileUi.radius),
            child: Ink(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: ui.card,
                borderRadius: BorderRadius.circular(_SalonProfileUi.radius),
                border: Border.all(color: ui.cardBorder, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: ui.textPrimary,
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppTranslations.getString(context, 'appearance'),
                          style: TextStyle(
                            color: ui.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isDarkMode
                              ? AppTranslations.getString(context, 'dark_mode')
                              : AppTranslations.getString(context, 'light_mode'),
                          style: TextStyle(
                            color: ui.textSecondary,
                            fontSize: 13,
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
                      context
                          .read<ThemeBloc>()
                          .add(ChangeTheme(newBrightness));
                    },
                    activeTrackColor: SalonUiTheme.accentBlue,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuTile({
    required SalonUiTheme ui,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool showChevron = true,
    bool highlightLeft = false,
  }) {
    final color =
        isDestructive ? _SalonProfileUi.logoutRed : ui.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_SalonProfileUi.radius),
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            color: ui.card,
            borderRadius: BorderRadius.circular(_SalonProfileUi.radius),
            border: Border.all(color: ui.cardBorder, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_SalonProfileUi.radius),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  if (highlightLeft)
                    Container(
                      width: 3,
                      color: _SalonProfileUi.accentOrange,
                    ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        highlightLeft ? 15 : 18,
                        16,
                        18,
                        16,
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: color, size: 22),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: color,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (showChevron)
                            Icon(
                              LucideIcons.chevronRight,
                              color: color,
                              size: 20,
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
      ),
    );
  }

  Widget _buildErrorState(SalonUiTheme ui) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'Connection Problem',
              style: TextStyle(
                color: ui.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your internet connection and try again.',
              style: TextStyle(color: Colors.orange, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSalonProfile,
              icon: const Icon(Icons.refresh),
              label: Text(AppTranslations.getString(context, 'retry')),
              style: ElevatedButton.styleFrom(
                backgroundColor: ui.primaryButtonBg,
                foregroundColor: ui.primaryButtonFg,
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
    );
  }

  void _showReportBottomSheet(BuildContext context) {
    // Light sheet + black text keeps labels readable on the blue header.
    final ui = SalonUiTheme.from(Brightness.light);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        final bottomSafe = MediaQuery.paddingOf(sheetContext).bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.9,
            ),
            decoration: BoxDecoration(
              color: ui.bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 180,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: ui.sheetHeaderGradient,
                        stops: const [0.0, 0.35, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 28, 20, 18 + bottomSafe),
                  child: BlocProvider(
                    create: (_) => SalonReportBloc(),
                    child: BlocConsumer<SalonReportBloc, SalonReportState>(
                      listener: (context, state) {
                        if (state is SalonReportSuccess) {
                          Navigator.of(sheetContext).pop();
                          _reportController.clear();
                          TopNotificationService.showSuccess(
                            context: this.context,
                            message: AppTranslations.getString(
                              this.context,
                              'report_submitted_successfully',
                            ),
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
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.getString(context, 'report'),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              AppTranslations.getString(
                                context,
                                'report_subtitle',
                              ),
                              style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.75),
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Flexible(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppTranslations.getString(
                                        context,
                                        'report',
                                      ),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _reportController,
                                      maxLines: 6,
                                      maxLength: 100,
                                      enabled: !isLoading,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      cursorColor: Colors.black,
                                      decoration: InputDecoration(
                                        hintText: AppTranslations.getString(
                                          context,
                                          'describe_your_problem',
                                        ),
                                        hintStyle: TextStyle(
                                          color: Colors.black
                                              .withValues(alpha: 0.4),
                                          fontSize: 15,
                                        ),
                                        counterStyle: TextStyle(
                                          color: Colors.black
                                              .withValues(alpha: 0.5),
                                          fontSize: 12,
                                        ),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        contentPadding:
                                            const EdgeInsets.all(14),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            _SalonProfileUi.radius,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.black,
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            _SalonProfileUi.radius,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.black,
                                            width: 1.2,
                                          ),
                                        ),
                                        disabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            _SalonProfileUi.radius,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.black
                                                .withValues(alpha: 0.35),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        final text =
                                            _reportController.text.trim();
                                        if (text.isEmpty) {
                                          TopNotificationService.showInfo(
                                            context: this.context,
                                            message: AppTranslations.getString(
                                              this.context,
                                              'no_comment',
                                            ),
                                          );
                                          return;
                                        }
                                        context.read<SalonReportBloc>().add(
                                              SubmitSalonReport(text),
                                            );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  disabledBackgroundColor: Colors.white70,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      _SalonProfileUi.radius,
                                    ),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : Text(
                                        AppTranslations.getString(
                                          this.context,
                                          'submit',
                                        ),
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: isLoading
                                    ? null
                                    : () => Navigator.of(sheetContext).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  side: const BorderSide(
                                    color: Colors.black,
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      _SalonProfileUi.radius,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  AppTranslations.getString(context, 'cancel'),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showLogoutConfirmation(BuildContext context) {
    // Light sheet + black text keeps labels readable on the blue header.
    final ui = SalonUiTheme.from(Brightness.light);
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final bottomSafe = MediaQuery.paddingOf(sheetContext).bottom;

        return Container(
          decoration: BoxDecoration(
            color: ui.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 160,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: ui.sheetHeaderGradient,
                      stops: const [0.0, 0.35, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 28, 20, 18 + bottomSafe),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.getString(
                        sheetContext,
                        'are_you_sure_logout',
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              _SalonProfileUi.radius,
                            ),
                          ),
                        ),
                        child: Text(
                          AppTranslations.getString(
                            sheetContext,
                            'yes_logout',
                          ),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Colors.black, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              _SalonProfileUi.radius,
                            ),
                          ),
                        ),
                        child: Text(
                          AppTranslations.getString(sheetContext, 'cancel'),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF22C55E)),
        ),
      );

      await SalonAuthService.logout();
      await TokenStorageService.clearAuthData();

      if (context.mounted) {
        context.read<AuthBloc>().add(Logout());
        Navigator.of(context).pop();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      try {
        await TokenStorageService.clearAuthData();
        if (context.mounted) {
          context.read<AuthBloc>().add(Logout());
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (_) => false,
          );
        }
      } catch (localError) {
        if (context.mounted) {
          TopNotificationService.showError(
            context: context,
            message: 'Logout failed: ${localError.toString()}',
          );
        }
      }
    }
  }

  Widget _buildShimmerContent(SalonUiTheme ui) {
    final baseColor = ui.isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final highlightColor = ui.isDark ? Colors.grey[700]! : Colors.grey[100]!;
    final placeholderColor =
        ui.isDark ? Colors.white24 : Colors.black.withValues(alpha: 0.08);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: placeholderColor,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: placeholderColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  height: 22,
                  width: 160,
                  decoration: BoxDecoration(
                    color: placeholderColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            ...List.generate(
              6,
              (index) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 56,
                decoration: BoxDecoration(
                  color: placeholderColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountDeletionDialog(BuildContext context) {
    AccountDeletionDialog.show(context, userType: 'salon');
  }
}
