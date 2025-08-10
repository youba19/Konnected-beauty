import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/bloc/login/login_bloc.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../widgets/forms/custom_text_field.dart';
import '../../../../widgets/forms/custom_button.dart';
import 'welcome_screen.dart';
import '../../../../core/bloc/language/language_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  bool isPasswordVisible = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: BlocBuilder<LanguageBloc, LanguageState>(
          builder: (context, languageState) {
            return BlocBuilder<LoginBloc, LoginState>(
              builder: (context, state) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
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
                                builder: (context) => const WelcomeScreen(),
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

                        // Welcome Back Title
                        Text(
                          AppTranslations.getString(context, 'welcome_back'),
                          style: AppTheme.headingStyle,
                        ),

                        const SizedBox(height: 32),

                        // Role Selection
                        _buildRoleSelection(state),
                        const SizedBox(height: 32),

                        // Error Banner
                        if (state.hasError)
                          _buildErrorBanner(state.errorMessage),
                        if (state.hasError) const SizedBox(height: 16),

                        // Email Field
                        CustomTextField(
                          label: AppTranslations.getString(context, 'email'),
                          placeholder: AppTranslations.getString(
                              context, 'email_placeholder'),
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          isError: state.hasError,
                          validator: (value) =>
                              Validators.validateEmail(value, context),
                          autovalidateMode: true,
                          formFieldKey: emailFormKey,
                        ),
                        const SizedBox(height: 20),

                        // Password Field
                        CustomTextField(
                          label: AppTranslations.getString(context, 'password'),
                          placeholder: AppTranslations.getString(
                              context, 'password_placeholder'),
                          controller: passwordController,
                          isPassword: true,
                          isError: state.hasError,
                          validator: (value) =>
                              Validators.validatePassword(value, context),
                          autovalidateMode: true,
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
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
                        const SizedBox(height: 16),

                        // Forget Password Link
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () {
                              // TODO: Navigate to forget password screen
                            },
                            child: Text(
                              AppTranslations.getString(
                                  context, 'forget_password'),
                              style: TextStyle(
                                color: AppTheme.accentColor,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),

                        // Login Button
                        CustomButton(
                          text: AppTranslations.getString(
                              context, 'login_to_your_account'),
                          onPressed: _onLogin,
                          isLoading: state.isLoading,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoleSelection(LoginState state) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              context.read<LoginBloc>().add(SelectRole(LoginRole.influencer));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: state.selectedRole == LoginRole.influencer
                    ? AppTheme.textPrimaryColor
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
                    color: state.selectedRole == LoginRole.influencer
                        ? AppTheme.primaryColor
                        : AppTheme.textPrimaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
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
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              context.read<LoginBloc>().add(SelectRole(LoginRole.saloon));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: state.selectedRole == LoginRole.saloon
                    ? AppTheme.textPrimaryColor
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
                    color: state.selectedRole == LoginRole.saloon
                        ? AppTheme.primaryColor
                        : AppTheme.textPrimaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
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
  }

  Widget _buildErrorBanner(String? errorMessage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        errorMessage ?? AppTranslations.getString(context, 'wrong_credentials'),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  bool _canLogin(LoginState state) {
    // Check if fields are not empty and valid
    final emailValidation =
        Validators.validateEmail(emailController.text, context);
    final passwordValidation =
        Validators.validatePassword(passwordController.text, context);

    return emailValidation == null &&
        passwordValidation == null &&
        !state.isLoading;
  }

  void _onLogin() {
    _validateFields();
    final currentState = context.read<LoginBloc>().state;
    if (_canLogin(currentState)) {
      context.read<LoginBloc>().add(Login(
            email: emailController.text,
            password: passwordController.text,
            role: currentState.selectedRole,
          ));
    }
  }
}
