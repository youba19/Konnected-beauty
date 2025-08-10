import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/welcome/welcome_bloc.dart';
import '../../../../core/bloc/saloon_registration/saloon_registration_bloc.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../widgets/common/animated_logo.dart';
import '../../../../widgets/common/language_selector.dart';
import '../../../../widgets/common/signup_button.dart';
import '../../../../widgets/common/login_button.dart';
import 'saloon_registration_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    // Start logo animation when screen loads
    context.read<WelcomeBloc>().add(StartLogoAnimation());
  }

  void _onLogoAnimationComplete() {
    context.read<WelcomeBloc>().add(CompleteLogoAnimation());
  }

  void _onSignupSaloon() {
    // Dismiss keyboard before navigation
    FocusScope.of(context).unfocus();
    // Reset registration state and navigate
    context.read<SaloonRegistrationBloc>().add(ResetRegistration());
    context.read<SaloonRegistrationBloc>().add(GoToStep(0));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SaloonRegistrationScreen()),
    );
  }

  void _onSignupInfluencer() {
    // TODO: Navigate to influencer signup
    print('Signup as Influencer');
  }

  void _onLogin() {
    // Navigate to login screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Content (appears after logo animation)
            BlocBuilder<WelcomeBloc, WelcomeState>(
              builder: (context, state) {
                return AnimatedOpacity(
                  opacity: state.showContent ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: state.showContent
                      ? _buildContent()
                      : const SizedBox.shrink(),
                );
              },
            ),

            // Animated Logo (first layer - on top)
            AnimatedLogo(
              onAnimationComplete: _onLogoAnimationComplete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Spacer for logo
              const SizedBox(height: 80),

              // Welcome Section
              _buildWelcomeSection(),

              const SizedBox(height: 48), // Increased spacing

              // Language Section
              _buildLanguageSection(),

              const SizedBox(height: 48), // Increased spacing
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Signup Section
              _buildSignupSection(),

              const SizedBox(height: 48), // Increased spacing

              // Login Section
              _buildLoginSection(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.getString(context, 'welcome_title'),
          style: AppTheme.headingStyle,
        ),
        const SizedBox(height: 16),
        Text(
          AppTranslations.getString(context, 'welcome_subtitle'),
          style: AppTheme.subtitleStyle,
        ),
      ],
    );
  }

  Widget _buildLanguageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LanguageSelector(),
      ],
    );
  }

  Widget _buildSignupSection() {
    return Column(
      children: [
        SignupButton(
          text: AppTranslations.getString(context, 'signup_saloon'),
          icon: Icons.business,
          onPressed: _onSignupSaloon,
        ),
        const SizedBox(height: 12),
        SignupButton(
          text: AppTranslations.getString(context, 'signup_influencer'),
          icon: Icons.person_outline,
          onPressed: _onSignupInfluencer,
        ),
      ],
    );
  }

  Widget _buildLoginSection() {
    return Column(
      children: [
        // Divider
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: AppTheme.borderColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppTranslations.getString(context, 'already_have_account'),
                style: AppTheme.dividerTextStyle,
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: AppTheme.borderColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Login Button
        LoginButton(
          onPressed: _onLogin,
        ),
      ],
    );
  }
}
