import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/salon_password/salon_password_bloc.dart';
import '../../../../core/bloc/theme/theme_bloc.dart';
import '../../../../core/theme/salon_ui_theme.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'package:lucide_icons/lucide_icons.dart';

abstract final class _SalonSecurityUi {
  static const double radius = 16;
  static const double buttonSize = 48;
  static const double buttonRadius = 14;
}

class SalonSecurityScreen extends StatefulWidget {
  const SalonSecurityScreen({super.key});

  @override
  State<SalonSecurityScreen> createState() => _SalonSecurityScreenState();
}

class _SalonSecurityScreenState extends State<SalonSecurityScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  bool _hasCurrentPassword = false;
  bool _hasNewPassword = false;
  bool _hasConfirmPassword = false;

  @override
  void initState() {
    super.initState();

    _currentPasswordController.addListener(() {
      setState(() {
        _hasCurrentPassword = _currentPasswordController.text.isNotEmpty;
      });
    });

    _newPasswordController.addListener(() {
      setState(() {
        _hasNewPassword = _newPasswordController.text.isNotEmpty;
      });
    });

    _confirmPasswordController.addListener(() {
      setState(() {
        _hasConfirmPassword = _confirmPasswordController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
                  child: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: BlocConsumer<SalonPasswordBloc, SalonPasswordState>(
                      listener: (context, state) {
                        if (state is SalonPasswordChanged) {
                          TopNotificationService.showSuccess(
                            context: context,
                            message: state.message,
                          );

                          _currentPasswordController.clear();
                          _newPasswordController.clear();
                          _confirmPasswordController.clear();
                          setState(() {
                            _showCurrentPassword = false;
                            _showNewPassword = false;
                            _showConfirmPassword = false;
                          });

                          Navigator.of(context).pop();
                        } else if (state is SalonPasswordError) {
                          TopNotificationService.showError(
                            context: context,
                            message: state.error,
                          );
                        }
                      },
                      builder: (context, state) {
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(
                            left: 20,
                            top: 8,
                            right: 20,
                            bottom:
                                MediaQuery.viewInsetsOf(context).bottom + 28,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(ui),
                              const SizedBox(height: 22),
                              _buildPasswordSection(ui),
                            ],
                          ),
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

  Widget _buildHeader(SalonUiTheme ui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBackButton(ui),
        const SizedBox(height: 18),
        Row(
          children: [
            Icon(
              LucideIcons.shield,
              color: ui.textPrimary,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              AppTranslations.getString(context, 'security'),
              style: TextStyle(
                color: ui.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackButton(SalonUiTheme ui) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: _SalonSecurityUi.buttonSize,
        height: _SalonSecurityUi.buttonSize,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ui.buttonFillTop,
              ui.buttonFillBottom,
            ],
          ),
          borderRadius: BorderRadius.circular(_SalonSecurityUi.buttonRadius),
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

  Widget _buildPasswordSection(SalonUiTheme ui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPasswordField(
          ui: ui,
          label: AppTranslations.getString(context, 'current_password'),
          controller: _currentPasswordController,
          hintText:
              AppTranslations.getString(context, 'enter_current_password'),
          showPassword: _showCurrentPassword,
          hasText: _hasCurrentPassword,
          onTogglePassword: () {
            setState(() {
              _showCurrentPassword = !_showCurrentPassword;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildPasswordField(
          ui: ui,
          label: AppTranslations.getString(context, 'new_password'),
          controller: _newPasswordController,
          hintText: AppTranslations.getString(context, 'set_new_password'),
          showPassword: _showNewPassword,
          hasText: _hasNewPassword,
          onTogglePassword: () {
            setState(() {
              _showNewPassword = !_showNewPassword;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildPasswordField(
          ui: ui,
          label: AppTranslations.getString(context, 'confirm_new_password'),
          controller: _confirmPasswordController,
          hintText: AppTranslations.getString(context, 'confirm_new_password'),
          showPassword: _showConfirmPassword,
          hasText: _hasConfirmPassword,
          onTogglePassword: () {
            setState(() {
              _showConfirmPassword = !_showConfirmPassword;
            });
          },
        ),
        const SizedBox(height: 32),
        _buildSaveButton(ui),
      ],
    );
  }

  Widget _buildPasswordField({
    required SalonUiTheme ui,
    required String label,
    required TextEditingController controller,
    required String hintText,
    required bool showPassword,
    required bool hasText,
    required VoidCallback onTogglePassword,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: ui.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: ui.card,
            borderRadius: BorderRadius.circular(_SalonSecurityUi.radius),
            border: Border.all(color: ui.cardBorder, width: 1),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: !showPassword,
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: hasText ? ui.textSecondary : ui.textMuted,
                fontSize: 16,
              ),
              prefixIcon: Icon(
                LucideIcons.lock,
                color: ui.textSecondary,
                size: 20,
              ),
              suffixIcon: IconButton(
                onPressed: onTogglePassword,
                icon: Icon(
                  showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  color: ui.textPrimary,
                  size: 20,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(SalonUiTheme ui) {
    return BlocBuilder<SalonPasswordBloc, SalonPasswordState>(
      builder: (context, state) {
        final isLoading = state is SalonPasswordChanging;

        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : _savePasswordChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: ui.primaryButtonBg,
              disabledBackgroundColor: ui.primaryButtonBg.withValues(alpha: 0.7),
              foregroundColor: ui.primaryButtonFg,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_SalonSecurityUi.radius),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ui.primaryButtonFg,
                    ),
                  )
                : Text(
                    AppTranslations.getString(context, 'save_changes'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        );
      },
    );
  }

  void _savePasswordChanges() {
    if (_currentPasswordController.text.isEmpty) {
      TopNotificationService.showError(
        context: context,
        message:
            AppTranslations.getString(context, 'current_password_required'),
      );
      return;
    }

    if (_newPasswordController.text.isEmpty) {
      TopNotificationService.showError(
        context: context,
        message: AppTranslations.getString(context, 'new_password_required'),
      );
      return;
    }

    if (_confirmPasswordController.text.isEmpty) {
      TopNotificationService.showError(
        context: context,
        message:
            AppTranslations.getString(context, 'confirm_password_required'),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      TopNotificationService.showError(
        context: context,
        message: AppTranslations.getString(context, 'passwords_not_match'),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      TopNotificationService.showError(
        context: context,
        message: AppTranslations.getString(context, 'new_password_too_short'),
      );
      return;
    }

    context.read<SalonPasswordBloc>().add(ChangeSalonPassword(
          oldPassword: _currentPasswordController.text.trim(),
          newPassword: _newPasswordController.text.trim(),
          confirmPassword: _confirmPasswordController.text.trim(),
        ));
  }
}
