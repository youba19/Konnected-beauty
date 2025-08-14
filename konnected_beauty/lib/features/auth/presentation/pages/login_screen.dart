import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/bloc/login/login_bloc.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/auth/auth_bloc.dart';
import '../../../../core/bloc/welcome/welcome_bloc.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'forgot_password_screen.dart';
import '../../../company/presentation/pages/salon_home_screen.dart';
import 'saloon_registration_screen.dart';
import '../../../../core/bloc/saloon_registration/saloon_registration_bloc.dart';
import 'welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  bool isPasswordVisible = false;
  bool _isLocalLoading = false; // Local loading state for immediate UI feedback
  bool _isLoginSuccessful = false; // Track if login was successful

  // Form keys for validation
  final GlobalKey<FormFieldState> emailFormKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> passwordFormKey = GlobalKey<FormFieldState>();

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();

    // Add listeners to sync with Bloc state
    emailController.addListener(() {
      context.read<LoginBloc>().add(UpdateEmail(emailController.text));
      // Trigger validation for real-time error display
      if (emailFormKey.currentState != null) {
        emailFormKey.currentState!.validate();
        setState(() {}); // Update UI to show validation errors
      }
    });

    passwordController.addListener(() {
      context.read<LoginBloc>().add(UpdatePassword(passwordController.text));
      // Trigger validation for real-time error display
      if (passwordFormKey.currentState != null) {
        passwordFormKey.currentState!.validate();
        setState(() {}); // Update UI to show validation errors
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _validateFields() {
    emailFormKey.currentState?.validate();
    passwordFormKey.currentState?.validate();
  }

  void _navigateToHomeScreen(LoginRole role) {
    // Add a small delay to show the success notification
    Future.delayed(const Duration(seconds: 2), () {
      if (role == LoginRole.saloon) {
        // Navigate to salon home screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const SalonHomeScreen(),
          ),
          (route) => false, // Remove all previous routes
        );
      } else {
        // TODO: Navigate to influencer home screen when implemented
        // For now, show a localized message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTranslations.getString(
                context, 'influencer_home_not_implemented')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  void _navigateToHomeScreenImmediately(LoginRole role) {
    // Trigger AuthBloc to check authentication status
    // This will automatically navigate to the appropriate screen based on auth state
    context.read<AuthBloc>().add(CheckAuthStatus());
  }

  void _navigateBasedOnUserStatus(LoginRole role, String userStatus) {
    print('🧭 === NAVIGATION LOGIC ===');
    print('👤 Role: ${role.name}');
    print('📊 Status from API: $userStatus');
    print('🔍 Status length: ${userStatus.length}');
    print('🔍 Status bytes: ${userStatus.codeUnits}');
    print('🔍 Status trimmed: "${userStatus.trim()}"');
    print('🔍 Status type: ${userStatus.runtimeType}');

    if (role == LoginRole.saloon) {
      final normalizedStatus = userStatus.toLowerCase().trim();
      print('🔍 Normalized status: "$normalizedStatus"');
      print('🔍 Normalized status length: ${normalizedStatus.length}');
      print('🔍 Normalized status bytes: ${normalizedStatus.codeUnits}');

      // Direct comparison with expected values
      print('🔍 === DIRECT COMPARISON ===');
      print('🔍 Is "email-verified"? ${normalizedStatus == "email-verified"}');
      print(
          '🔍 Is "salon-info-added"? ${normalizedStatus == "salon-info-added"}');
      print('🔍 Is "otp"? ${normalizedStatus == "otp"}');
      print('🔍 === END COMPARISON ===');

      // Debug: Print each character of the normalized status
      print('🔍 === DETAILED STATUS ANALYSIS ===');
      print('🔍 Normalized status: "$normalizedStatus"');
      for (int i = 0; i < normalizedStatus.length; i++) {
        print(
            '🔍 Character $i: "${normalizedStatus[i]}" (code: ${normalizedStatus.codeUnitAt(i)})');
      }
      print('🔍 Expected "email-verified": "email-verified"');
      for (int i = 0; i < "email-verified".length; i++) {
        print(
            '🔍 Expected char $i: "${"email-verified"[i]}" (code: ${"email-verified".codeUnitAt(i)})');
      }
      print('🔍 === END ANALYSIS ===');

      switch (normalizedStatus) {
        case 'email-verified':
          print('✅ MATCHED: email-verified case');
          print('📍 Navigating to: Add Salon Info (Registration)');
          _navigateToSalonInfoScreen();
          break;

        case 'otp':
          print('✅ MATCHED: otp case');
          print('📍 Navigating to: Add Salon Info (Registration) - OTP status');
          _navigateToSalonInfoScreen();
          break;

        case 'salon-info-added':
          print('✅ MATCHED: salon-info-added case');
          print('📍 Navigating to: Add Salon Profile (Registration)');
          _navigateToSalonProfileScreen();
          break;

        default:
          print('❌ NO MATCH: default case');
          print('📍 Navigating to: Salon Home Screen (default case)');
          print('🔍 Status did not match any case: "$normalizedStatus"');
          print('🔍 Comparing with:');
          print(
              '   - "email-verified": ${normalizedStatus == "email-verified"}');
          print('   - "otp": ${normalizedStatus == "otp"}');
          print(
              '   - "salon-info-added": ${normalizedStatus == "salon-info-added"}');
          // Navigate to salon home screen for other statuses
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const SalonHomeScreen(),
            ),
            (route) => false, // Remove all previous routes
          );
          break;
      }
    } else {
      // Handle influencer navigation
      print('📍 Navigating to: Influencer Home Screen');
      // TODO: Navigate to influencer home screen when implemented
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTranslations.getString(
              context, 'influencer_home_not_implemented')),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _navigateToSalonInfoScreen() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const SaloonRegistrationScreen(),
      ),
      (route) => false, // Remove all previous routes
    );
    // Set the step directly to 2 (Salon Information)
    context.read<SaloonRegistrationBloc>().add(GoToStep(2));
  }

  void _navigateToSalonProfileScreen() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const SaloonRegistrationScreen(),
      ),
      (route) => false, // Remove all previous routes
    );
    // Set the step directly to 3 (Salon Profile)
    context.read<SaloonRegistrationBloc>().add(GoToStep(3));
  }

  void _showTopNotification(String message, bool isError) {
    if (isError) {
      TopNotificationService.showError(
        context: context,
        message: message,
      );
    } else {
      TopNotificationService.showSuccess(
        context: context,
        message: message,
      );
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
        body: SafeArea(
          child: BlocListener<LoginBloc, LoginState>(
            listener: (context, state) {
              if (state is LoginSuccess) {
                // Reset local loading state
                setState(() {
                  _isLocalLoading = false;
                  _isLoginSuccessful = true;
                });

                // Show success notification
                TopNotificationService.showSuccess(
                  context: context,
                  message: AppTranslations.getString(context, 'login_success'),
                );

                // Navigate based on user status
                _navigateBasedOnUserStatus(
                    state.selectedRole, state.userStatus);
              } else if (state is LoginError) {
                // Reset local loading state
                setState(() {
                  _isLocalLoading = false;
                  _isLoginSuccessful = false;
                });

                // Show error notification
                TopNotificationService.showError(
                  context: context,
                  message: state.errorMessage ??
                      AppTranslations.getString(context, 'login_failed'),
                );
              }
            },
            child: Column(
              children: [
                // Top Section: Header + User Type Selection
                _buildTopSection(),

                // Spacer to push form to bottom
                const Spacer(),

                // Bottom Section: Form Elements
                _buildBottomSection(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeSelection() {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return Row(
          children: [
            // Influencer Button
            Expanded(
              child: GestureDetector(
                onTap: () {
                  context
                      .read<LoginBloc>()
                      .add(SelectRole(LoginRole.influencer));
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: state.selectedRole == LoginRole.influencer
                        ? AppTheme.textPrimaryColor
                        : Colors.transparent,
                    border: Border.all(
                      color: AppTheme.textPrimaryColor,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.user,
                        color: state.selectedRole == LoginRole.influencer
                            ? AppTheme.primaryColor
                            : AppTheme.textPrimaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppTranslations.getString(context, 'influencer'),
                        style: TextStyle(
                          color: state.selectedRole == LoginRole.influencer
                              ? AppTheme.primaryColor
                              : AppTheme.textPrimaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Saloon Button
            Expanded(
              child: GestureDetector(
                onTap: () {
                  context.read<LoginBloc>().add(SelectRole(LoginRole.saloon));
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: state.selectedRole == LoginRole.saloon
                        ? AppTheme.textPrimaryColor
                        : Colors.transparent,
                    border: Border.all(
                      color: AppTheme.textPrimaryColor,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.building2,
                        color: state.selectedRole == LoginRole.saloon
                            ? AppTheme.primaryColor
                            : AppTheme.textPrimaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppTranslations.getString(context, 'saloon'),
                        style: TextStyle(
                          color: state.selectedRole == LoginRole.saloon
                              ? AppTheme.primaryColor
                              : AppTheme.textPrimaryColor,
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
        );
      },
    );
  }

  Widget _buildEmailInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email Label
        Text(
          AppTranslations.getString(context, 'email'),
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 12),

        // Email Input Field
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.textPrimaryColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !(_isLocalLoading || _isLoginSuccessful),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: AppTranslations.getString(context, 'enter_email'),
              hintStyle: TextStyle(
                color: AppTheme.textPrimaryColor.withOpacity(0.6),
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: (value) => Validators.validateEmail(value, context),
          ),
        ),

        // Email Error Message
        if (emailFormKey.currentState?.hasError == true)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              Validators.validateEmail(emailController.text, context) ??
                  'Invalid email',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ),

        const SizedBox(height: 24),

        // Password Label
        Text(
          AppTranslations.getString(context, 'password'),
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 12),

        // Password Input Field
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.textPrimaryColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            controller: passwordController,
            obscureText: !isPasswordVisible,
            enabled: !(_isLocalLoading || _isLoginSuccessful),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: AppTranslations.getString(context, 'enter_password'),
              hintStyle: TextStyle(
                color: AppTheme.textPrimaryColor.withOpacity(0.6),
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: GestureDetector(
                onTap: () {
                  setState(() {
                    isPasswordVisible = !isPasswordVisible;
                  });
                },
                child: Icon(
                  isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                  color: AppTheme.textPrimaryColor,
                  size: 20,
                ),
              ),
            ),
            validator: (value) => Validators.validatePassword(value, context),
          ),
        ),

        // Password Error Message
        if (passwordFormKey.currentState?.hasError == true)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              Validators.validatePassword(passwordController.text, context) ??
                  'Invalid password',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ),

        const SizedBox(height: 20),

        // Forgot Password Link
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ForgotPasswordScreen(),
                ),
              );
            },
            child: Text(
              AppTranslations.getString(context, 'forgot_password'),
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // First trigger validation to show inline errors
          _validateFields();

          // Check if button should be enabled
          final shouldEnable = emailController.text.isNotEmpty &&
              !_isLocalLoading &&
              !_isLoginSuccessful;

          if (shouldEnable) {
            final currentState = context.read<LoginBloc>().state;

            setState(() {
              _isLocalLoading = true;
            });

            context.read<LoginBloc>().add(Login(
                  email: emailController.text,
                  password: passwordController.text,
                  role: currentState.selectedRole,
                ));
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.textPrimaryColor,
          foregroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: _isLocalLoading || _isLoginSuccessful
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              )
            : Text(
                AppTranslations.getString(context, 'login_to_account'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button only (no logo in top bar)
          GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              context.read<WelcomeBloc>().add(SkipLogoAnimation());
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const WelcomeScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                LucideIcons.arrowLeft,
                color: AppTheme.textPrimaryColor,
                size: 24,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Logo below back button
          SvgPicture.asset(
            'assets/images/Konected beauty - Logo white.svg',
            height: 82,
            colorFilter: const ColorFilter.mode(
              AppTheme.textPrimaryColor,
              BlendMode.srcIn,
            ),
          ),

          const SizedBox(height: 20),

          // Title below logo
          Text(
            AppTranslations.getString(context, 'welcome_back'),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // User Type Selection
          _buildUserTypeSelection(),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Email Input Section
          _buildEmailInput(),

          const SizedBox(height: 40),

          // Login Button
          _buildLoginButton(),
        ],
      ),
    );
  }
}
