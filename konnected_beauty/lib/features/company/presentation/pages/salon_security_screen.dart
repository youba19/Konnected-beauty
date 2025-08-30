import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konnected_beauty/core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/salon_password/salon_password_bloc.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'package:lucide_icons/lucide_icons.dart';

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

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: BlocConsumer<SalonPasswordBloc, SalonPasswordState>(
            listener: (context, state) {
              if (state is SalonPasswordChanged) {
                TopNotificationService.showSuccess(
                  context: context,
                  message: state.message,
                );

                // Clear the form after successful password change
                _currentPasswordController.clear();
                _newPasswordController.clear();
                _confirmPasswordController.clear();
                setState(() {
                  _showCurrentPassword = false;
                  _showNewPassword = false;
                  _showConfirmPassword = false;
                });

                // Navigate back to settings screen after successful password change
                Navigator.of(context).pop();
              } else if (state is SalonPasswordError) {
                TopNotificationService.showError(
                  context: context,
                  message: state.error,
                );
              }
            },
            builder: (context, state) {
              return Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPasswordSection(),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              LucideIcons.arrowLeft,
              color: AppTheme.textPrimaryColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                LucideIcons.shield,
                color: AppTheme.textPrimaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                AppTranslations.getString(context, 'security'),
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current Password
        _buildPasswordField(
          label: AppTranslations.getString(context, 'current_password'),
          controller: _currentPasswordController,
          hintText:
              AppTranslations.getString(context, 'enter_current_password'),
          showPassword: _showCurrentPassword,
          onTogglePassword: () {
            setState(() {
              _showCurrentPassword = !_showCurrentPassword;
            });
          },
        ),
        const SizedBox(height: 24),

        // New Password
        _buildPasswordField(
          label: AppTranslations.getString(context, 'new_password'),
          controller: _newPasswordController,
          hintText: AppTranslations.getString(context, 'set_new_password'),
          showPassword: _showNewPassword,
          onTogglePassword: () {
            setState(() {
              _showNewPassword = !_showNewPassword;
            });
          },
        ),
        const SizedBox(height: 24),

        // Confirm New Password
        _buildPasswordField(
          label: AppTranslations.getString(context, 'confirm_new_password'),
          controller: _confirmPasswordController,
          hintText: AppTranslations.getString(context, 'confirm_new_password'),
          showPassword: _showConfirmPassword,
          onTogglePassword: () {
            setState(() {
              _showConfirmPassword = !_showConfirmPassword;
            });
          },
        ),
        const SizedBox(height: 32),

        // Save Changes Button
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required bool showPassword,
    required VoidCallback onTogglePassword,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.textPrimaryColor,
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: !showPassword,
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 16,
              ),
              prefixIcon: Icon(
                LucideIcons.lock,
                color: AppTheme.textSecondaryColor,
                size: 20,
              ),
              suffixIcon: IconButton(
                onPressed: onTogglePassword,
                icon: Icon(
                  showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  color: AppTheme.textPrimaryColor,
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

  Widget _buildSaveButton() {
    return BlocBuilder<SalonPasswordBloc, SalonPasswordState>(
      builder: (context, state) {
        final isLoading = state is SalonPasswordChanging;

        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _savePasswordChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.transparentBackground,
              foregroundColor: AppTheme.textSecondaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: AppTheme.secondaryColor,
                  width: 1,
                ),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.border2),
                    ),
                  )
                : Text(
                    AppTranslations.getString(context, 'save_changes'),
                    style: TextStyle(
                      color: AppTheme.border2,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      },
    );
  }

  void _savePasswordChanges() {
    // Validate inputs
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

    // Use BLoC to change password
    context.read<SalonPasswordBloc>().add(ChangeSalonPassword(
          oldPassword: _currentPasswordController.text.trim(),
          newPassword: _newPasswordController.text.trim(),
          confirmPassword: _confirmPasswordController.text.trim(),
        ));
  }
}
