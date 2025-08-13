import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/bloc/login/login_bloc.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../widgets/forms/custom_text_field.dart';
import '../../../../widgets/forms/custom_button.dart';
// import 'welcome_screen.dart';
// import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/auth/auth_bloc.dart';
import 'forgot_password_screen.dart';
import '../../../company/presentation/pages/salon_home_screen.dart';
import 'saloon_registration_screen.dart';
import '../../../../core/bloc/saloon_registration/saloon_registration_bloc.dart';

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
    });

    passwordController.addListener(() {
      context.read<LoginBloc>().add(UpdatePassword(passwordController.text));
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
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isError ? Colors.red : Colors.green,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isError ? Icons.error : Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    overlayEntry.remove();
                  },
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-remove after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.primaryColor,
        body: BlocListener<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LoginSuccess) {
              // Reset local loading state
              setState(() {
                _isLocalLoading = false;
                _isLoginSuccessful = true;
              });

              // Show success notification
              _showTopNotification(
                AppTranslations.getString(context, 'login_success'),
                false,
              );

              // Navigate based on user status
              _navigateBasedOnUserStatus(state.selectedRole, state.userStatus);
            } else if (state is LoginError) {
              // Reset local loading state
              setState(() {
                _isLocalLoading = false;
                _isLoginSuccessful = false;
              });

              // Show error notification
              _showTopNotification(
                state.errorMessage ??
                    AppTranslations.getString(context, 'login_failed'),
                true,
              );
            }
          },
          child: SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Back Navigation
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.arrow_back,
                                color: AppTheme.textPrimaryColor,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Logo and Welcome Message
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo
                              SvgPicture.asset(
                                'assets/images/Konected beauty - Logo white.svg',
                                height: 80,
                                colorFilter: const ColorFilter.mode(
                                  AppTheme.textPrimaryColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Welcome Message
                              Text(
                                AppTranslations.getString(
                                    context, 'welcome_back'),
                                style: const TextStyle(
                                  color: AppTheme.textPrimaryColor,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Role Selection
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: BlocBuilder<LoginBloc, LoginState>(
                          builder: (context, state) {
                            return Row(
                              children: [
                                // Influencer Button
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      context.read<LoginBloc>().add(
                                          SelectRole(LoginRole.influencer));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: state.selectedRole ==
                                                LoginRole.influencer
                                            ? AppTheme.textPrimaryColor
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: AppTheme.textPrimaryColor,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.person,
                                            color: state.selectedRole ==
                                                    LoginRole.influencer
                                                ? AppTheme.primaryColor
                                                : AppTheme.textPrimaryColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            AppTranslations.getString(
                                                context, 'influencer'),
                                            style: TextStyle(
                                              color: state.selectedRole ==
                                                      LoginRole.influencer
                                                  ? AppTheme.primaryColor
                                                  : AppTheme.textPrimaryColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: 'Montserrat',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Saloon Button
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      context
                                          .read<LoginBloc>()
                                          .add(SelectRole(LoginRole.saloon));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: state.selectedRole ==
                                                LoginRole.saloon
                                            ? AppTheme.textPrimaryColor
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: AppTheme.textPrimaryColor,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.store,
                                            color: state.selectedRole ==
                                                    LoginRole.saloon
                                                ? AppTheme.primaryColor
                                                : AppTheme.textPrimaryColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            AppTranslations.getString(
                                                context, 'saloon'),
                                            style: TextStyle(
                                              color: state.selectedRole ==
                                                      LoginRole.saloon
                                                  ? AppTheme.primaryColor
                                                  : AppTheme.textPrimaryColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: 'Montserrat',
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
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Login Form
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            // Email Field
                            CustomTextField(
                              controller: emailController,
                              label:
                                  AppTranslations.getString(context, 'email'),
                              placeholder: AppTranslations.getString(
                                  context, 'enter_email'),
                              keyboardType: TextInputType.emailAddress,
                              formFieldKey: emailFormKey,
                              enabled: !(_isLocalLoading || _isLoginSuccessful),
                              validator: (value) =>
                                  Validators.validateEmail(value, context),
                            ),
                            const SizedBox(height: 16),
                            // Password Field
                            CustomTextField(
                              controller: passwordController,
                              label: AppTranslations.getString(
                                  context, 'password'),
                              placeholder: AppTranslations.getString(
                                  context, 'enter_password'),
                              isPassword: !isPasswordVisible,
                              enabled: !(_isLocalLoading || _isLoginSuccessful),
                              suffixIcon: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isPasswordVisible = !isPasswordVisible;
                                  });
                                },
                                child: Icon(
                                  isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              formFieldKey: passwordFormKey,
                              validator: (value) =>
                                  Validators.validatePassword(value, context),
                            ),
                            const SizedBox(height: 16),
                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  AppTranslations.getString(
                                      context, 'forgot_password'),
                                  style: const TextStyle(
                                    color: AppTheme.textPrimaryColor,
                                    fontSize: 14,
                                    fontFamily: 'Montserrat',
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              child: CustomButton(
                                text: AppTranslations.getString(
                                    context, 'login_to_account'),
                                onPressed: () {
                                  // Validate fields
                                  Validators.validateEmail(
                                      emailController.text, context);
                                  Validators.validatePassword(
                                      passwordController.text, context);

                                  // Check if button should be enabled
                                  final shouldEnable =
                                      emailController.text.isNotEmpty &&
                                          passwordController.text.isNotEmpty &&
                                          !_isLocalLoading &&
                                          !_isLoginSuccessful;

                                  if (shouldEnable) {
                                    _validateFields();
                                    final currentState =
                                        context.read<LoginBloc>().state;

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
                                isLoading:
                                    _isLocalLoading || _isLoginSuccessful,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}
