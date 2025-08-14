import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../widgets/forms/custom_text_field.dart';
import '../../../../widgets/forms/custom_button.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/reset_password/reset_password_bloc.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'login_screen.dart';
import 'otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormFieldState> emailFormKey = GlobalKey<FormFieldState>();
  String selectedRole = 'influencer'; // Default to influencer

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void _onResetPassword() {
    if (_validateFields()) {
      context.read<ResetPasswordBloc>().add(
            RequestPasswordReset(emailController.text),
          );
    }
  }

  bool _validateFields() {
    final emailValid = emailFormKey.currentState?.validate() ?? false;
    return emailValid;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ResetPasswordBloc, ResetPasswordState>(
      listener: (context, state) {
        if (state is RequestPasswordResetSuccess) {
          TopNotificationService.showSuccess(
            context: context,
            message: state.message,
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                email: emailController.text,
                role: selectedRole,
              ),
            ),
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
            body: Container(
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
              child: SafeArea(
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
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginScreen(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 32),

                                // Logo
                                SvgPicture.asset(
                                  'assets/images/Konected beauty - Logo white.svg',
                                  width: 80,
                                  height: 80,
                                  allowDrawingOutsideViewBox: true,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Title
                                Text(
                                  AppTranslations.getString(
                                      context, 'reset_password'),
                                  style: AppTheme.headingStyle,
                                ),

                                const SizedBox(height: 32),

                                // Role Selection
                                _buildRoleSelection(),
                                const Spacer(),

                                // Email Field
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppTranslations.getString(
                                          context, 'email'),
                                      style: TextStyle(
                                        color: AppTheme.textPrimaryColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    CustomTextField(
                                      label: '',
                                      placeholder: AppTranslations.getString(
                                          context, 'email_placeholder'),
                                      controller: emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) =>
                                          Validators.validateEmail(
                                              value, context),
                                      autovalidateMode: true,
                                      formFieldKey: emailFormKey,
                                    ),
                                  ],
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedRole = 'influencer';
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: selectedRole == 'influencer'
                    ? Colors.grey[300]
                    : Colors.transparent,
                border: Border.all(
                  color: AppTheme.textPrimaryColor,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person,
                    color: selectedRole == 'influencer'
                        ? AppTheme.primaryColor
                        : AppTheme.textPrimaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppTranslations.getString(context, 'influencer'),
                    style: TextStyle(
                      color: selectedRole == 'influencer'
                          ? AppTheme.primaryColor
                          : AppTheme.textPrimaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedRole = 'salon';
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: selectedRole == 'salon'
                    ? Colors.grey[300]
                    : Colors.transparent,
                border: Border.all(
                  color: AppTheme.textPrimaryColor,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business,
                    color: selectedRole == 'salon'
                        ? AppTheme.primaryColor
                        : AppTheme.textPrimaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppTranslations.getString(context, 'salon'),
                    style: TextStyle(
                      color: selectedRole == 'salon'
                          ? AppTheme.primaryColor
                          : AppTheme.textPrimaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
