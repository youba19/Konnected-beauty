import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api/influencer_auth_service.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/utils/validators.dart';
import '../../../../widgets/forms/custom_text_field.dart';
import '../../../../widgets/forms/custom_button.dart';
import '../../../../widgets/common/top_notification_banner.dart';

class InfluencerOtpScreen extends StatefulWidget {
  final String email;
  final String phoneNumber;

  const InfluencerOtpScreen({
    super.key,
    required this.email,
    required this.phoneNumber,
  });

  @override
  State<InfluencerOtpScreen> createState() => _InfluencerOtpScreenState();
}

class _InfluencerOtpScreenState extends State<InfluencerOtpScreen> {
  final _otpController = TextEditingController();
  bool _isResending = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _showSuccessNotification(String message) {
    TopNotificationService.showSuccess(
      context: context,
      message: message,
    );
  }

  void _showErrorNotification(String message) {
    TopNotificationService.showError(
      context: context,
      message: message,
    );
  }

  void _onVerifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      _showErrorNotification('Please enter OTP');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await InfluencerAuthService.validateOtp(
        email: widget.email,
        otp: _otpController.text.trim(),
      );

      if (mounted) {
        _showSuccessNotification('OTP verified successfully!');
        // TODO: Navigate to next step (profile setup)
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showErrorNotification('OTP verification failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onResendOtp() async {
    setState(() {
      _isResending = true;
    });

    try {
      await InfluencerAuthService.resendOtp(email: widget.email);
      if (mounted) {
        _showSuccessNotification('OTP resent successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorNotification('Failed to resend OTP: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
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
            Color(0xFF3B3B3B),
            Color(0xFF1F1E1E),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon
                Row(
                  children: [
                    const Icon(
                      LucideIcons.shield,
                      color: AppTheme.textPrimaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppTranslations.getString(context, 'phone_verification'),
                      style: const TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Success message for signup
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        LucideIcons.checkCircle,
                        color: Colors.green,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Account created successfully! Please check your phone for the verification code.',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // OTP Field
                CustomTextField(
                  label:
                      AppTranslations.getString(context, 'verification_code'),
                  placeholder:
                      AppTranslations.getString(context, 'otp_placeholder'),
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) => Validators.validateOtp(value, context),
                ),
                const SizedBox(height: 16),

                // Resend code link
                GestureDetector(
                  onTap: _isResending ? null : _onResendOtp,
                  child: Text(
                    _isResending
                        ? 'Resending...'
                        : AppTranslations.getString(context, 'resend_code'),
                    style: TextStyle(
                      color: _isResending
                          ? AppTheme.textSecondaryColor
                          : AppTheme.accentColor,
                      fontSize: 16,
                      decoration:
                          _isResending ? null : TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: AppTranslations.getString(context, 'continue'),
                    onPressed: _isLoading ? () {} : _onVerifyOtp,
                    isLoading: _isLoading,
                    trailingIcon: LucideIcons.arrowRight,
                  ),
                ),

                // Add extra space for keyboard
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
