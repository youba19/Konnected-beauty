import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../widgets/forms/custom_text_field.dart';
import '../../../../widgets/forms/custom_button.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/reset_password/reset_password_bloc.dart';
import 'new_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String role;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.role,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController otpController = TextEditingController();
  final GlobalKey<FormFieldState> otpFormKey = GlobalKey<FormFieldState>();

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  void _onSubmitOtp() {
    if (_validateFields()) {
      // Call API to verify reset password OTP
      context.read<ResetPasswordBloc>().add(
            VerifyResetPasswordOtp(
              email: widget.email,
              otp: otpController.text,
            ),
          );
    }
  }

  void _onResendCode() {
    // Call API to resend password reset OTP
    context.read<ResetPasswordBloc>().add(
          RequestPasswordReset(widget.email),
        );
  }

  bool _validateFields() {
    final otpValid = otpFormKey.currentState?.validate() ?? false;
    return otpValid;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ResetPasswordBloc, ResetPasswordState>(
      listener: (context, state) {
        if (state is VerifyResetPasswordOtpSuccess) {
          // Show success message and navigate to new password screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NewPasswordScreen(
                email: widget.email,
                role: widget.role,
                otp: otpController.text,
                resetToken: state.resetToken,
              ),
            ),
          );
        } else if (state is RequestPasswordResetSuccess) {
          // Show success message for resend
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is ResetPasswordError) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
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
                                    context, 'otp_verification_title'),
                                style: AppTheme.headingStyle,
                              ),
                              const SizedBox(height: 8),

                              // Subtitle
                              Text(
                                AppTranslations.getString(
                                    context, 'otp_verification_subtitle'),
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 16,
                                ),
                              ),

                              const Spacer(),

                              // Email Verification Section
                              Text(
                                AppTranslations.getString(
                                    context, 'email_verification'),
                                style: TextStyle(
                                  color: AppTheme.textPrimaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),

                              Text(
                                'OTP verification',
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // OTP Field
                              CustomTextField(
                                label: '',
                                placeholder: AppTranslations.getString(
                                    context, 'otp_placeholder'),
                                controller: otpController,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter OTP';
                                  }
                                  if (value.length < 6) {
                                    return 'OTP must be 6 digits';
                                  }
                                  return null;
                                },
                                autovalidateMode: true,
                                formFieldKey: otpFormKey,
                              ),
                              const SizedBox(height: 16),

                              // Resend Code Link
                              GestureDetector(
                                onTap: _onResendCode,
                                child: Text(
                                  AppTranslations.getString(
                                      context, 'resend_code'),
                                  style: TextStyle(
                                    color: AppTheme.textPrimaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Submit Button
                              BlocBuilder<ResetPasswordBloc,
                                  ResetPasswordState>(
                                builder: (context, resetState) {
                                  return CustomButton(
                                    text: AppTranslations.getString(
                                        context, 'submit_and_continue'),
                                    onPressed:
                                        resetState is ResetPasswordLoading
                                            ? () {}
                                            : _onSubmitOtp,
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
