import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konnected_beauty/core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import '../../../../widgets/forms/custom_text_field.dart';
import '../../../../core/bloc/influencers/influencer_profile_bloc.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _hasTextInAnyField = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkIfAnyFieldHasText() {
    final hasText = _currentPasswordController.text.trim().isNotEmpty ||
        _newPasswordController.text.trim().isNotEmpty ||
        _confirmPasswordController.text.trim().isNotEmpty;

    if (hasText != _hasTextInAnyField) {
      setState(() {
        _hasTextInAnyField = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InfluencerProfileBloc, InfluencerProfileState>(
      listener: (context, state) {
        if (state is PasswordChanged) {
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
            _hasTextInAnyField = false;
          });

          // Navigate back to profile screen after successful password change
          Navigator.of(context).pop();
        } else if (state is PasswordChangeError) {
          // Show only the clean error message (no API response details)
          TopNotificationService.showError(
            context: context,
            message: state.error,
          );
        }
      },
      builder: (context, state) {
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
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPasswordSection(state),
                          ],
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: Colors.white,
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

  Widget _buildPasswordSection(InfluencerProfileState state) {
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
        _buildSaveButton(state),
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
    return CustomTextField(
      label: label,
      placeholder: hintText,
      controller: controller,
      isPassword: true,
      isPasswordVisible: showPassword,
      onChanged: (value) => _checkIfAnyFieldHasText(),
      suffixIcon: IconButton(
        onPressed: onTogglePassword,
        icon: Icon(
          showPassword ? Icons.visibility : Icons.visibility_off,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSaveButton(InfluencerProfileState state) {
    final isLoading = state is PasswordChanging;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : _savePasswordChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _hasTextInAnyField
                  ? Colors.white
                  : Colors.white.withOpacity(0.3),
              width: _hasTextInAnyField ? 2 : 1,
            ),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppTranslations.getString(context, 'save_changes'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _hasTextInAnyField
                          ? Colors.white
                          : Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _savePasswordChanges() async {
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
    context.read<InfluencerProfileBloc>().add(
          ChangePassword(
            oldPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
            confirmPassword: _confirmPasswordController.text,
          ),
        );
  }
}
