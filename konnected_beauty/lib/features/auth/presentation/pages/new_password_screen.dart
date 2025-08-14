import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../widgets/forms/custom_text_field.dart';
import '../../../../widgets/forms/custom_button.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/reset_password/reset_password_bloc.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'login_screen.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;
  final String role;
  final String otp;
  final String? resetToken;

  const NewPasswordScreen({
    super.key,
    required this.email,
    required this.role,
    required this.otp,
    this.resetToken,
  });

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormFieldState> passwordFormKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> confirmPasswordFormKey =
      GlobalKey<FormFieldState>();
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _onResetPassword() {
    if (_validateFields()) {
      // Call API to reset password
      context.read<ResetPasswordBloc>().add(
            ResetPassword(
              newPassword: passwordController.text,
              confirmPassword: confirmPasswordController.text,
              resetToken: widget.resetToken,
              email: widget.email,
            ),
          );
    }
  }

  bool _validateFields() {
    final passwordValid = passwordFormKey.currentState?.validate() ?? false;
    final confirmPasswordValid =
        confirmPasswordFormKey.currentState?.validate() ?? false;

    if (passwordValid && confirmPasswordValid) {
      if (passwordController.text != confirmPasswordController.text) {
        TopNotificationService.showError(
          context: context,
          message: AppTranslations.getString(context, 'passwords_do_not_match'),
        );
        return false;
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ResetPasswordBloc, ResetPasswordState>(
      listener: (context, state) {
        if (state is ResetPasswordSuccess) {
          TopNotificationService.showSuccess(
            context: context,
            message: state.message,
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
            (route) => false,
          );
        } else if (state is ResetPasswordError) {
          TopNotificationService.showError(
            context: context,
            message: state.message,
          );
        }
      },
      child: BlocBuilder<LanguageBloc, LanguageState>(
        builder: (context, languageState) {
          return Scaffold(
            backgroundColor: AppTheme.primaryColor,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Back Button
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: AppTheme.textPrimaryColor,
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              const SizedBox(height: 32),

                              // Title
                              Text(
                                AppTranslations.getString(
                                    context, 'new_password_title'),
                                style: AppTheme.headingStyle,
                              ),
                              const SizedBox(height: 8),

                              // Subtitle
                              Text(
                                AppTranslations.getString(
                                    context, 'new_password_subtitle'),
                                style: const TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 16,
                                ),
                              ),

                              const Spacer(),

                              // Email Verification Section with Avatar

                              Text(
                                AppTranslations.getString(
                                    context, 'reset_password'),
                                style: const TextStyle(
                                  color: AppTheme.textPrimaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                AppTranslations.getString(context, 'password'),
                                style: const TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 14,
                                ),
                              ),

                              // New Password Field
                              CustomTextField(
                                label: '',
                                placeholder: AppTranslations.getString(
                                    context, 'password_placeholder'),
                                controller: passwordController,
                                isPassword: true,
                                isPasswordVisible: isPasswordVisible,
                                validator: (value) =>
                                    Validators.validatePassword(value, context),
                                autovalidateMode: true,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    isPasswordVisible
                                        ? LucideIcons.eyeOff
                                        : LucideIcons.eye,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isPasswordVisible = !isPasswordVisible;
                                    });
                                  },
                                ),
                                formFieldKey: passwordFormKey,
                              ),
                              const SizedBox(height: 20),

                              Text(
                                AppTranslations.getString(
                                    context, 'confirm_password'),
                                style: const TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 14,
                                ),
                              ),

                              // Confirm Password Field
                              CustomTextField(
                                label: '',
                                placeholder: AppTranslations.getString(
                                    context, 'confirm_password_placeholder'),
                                controller: confirmPasswordController,
                                isPassword: true,
                                isPasswordVisible: isConfirmPasswordVisible,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return AppTranslations.getString(
                                        context, 'please_confirm_password');
                                  }
                                  if (value != passwordController.text) {
                                    return AppTranslations.getString(
                                        context, 'passwords_do_not_match');
                                  }
                                  return null;
                                },
                                autovalidateMode: true,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    isConfirmPasswordVisible
                                        ? LucideIcons.eyeOff
                                        : LucideIcons.eye,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isConfirmPasswordVisible =
                                          !isConfirmPasswordVisible;
                                    });
                                  },
                                ),
                                formFieldKey: confirmPasswordFormKey,
                              ),

                              const SizedBox(height: 40),

                              // Reset Password Button
                              BlocBuilder<ResetPasswordBloc,
                                  ResetPasswordState>(
                                builder: (context, resetState) {
                                  return CustomButton(
                                    text: AppTranslations.getString(
                                        context, 'reset_password_button'),
                                    onPressed:
                                        resetState is ResetPasswordLoading
                                            ? () {}
                                            : _onResetPassword,
                                    isLoading:
                                        resetState is ResetPasswordLoading,
                                  );
                                },
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
