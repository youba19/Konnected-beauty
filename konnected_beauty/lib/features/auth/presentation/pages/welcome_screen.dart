import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/bloc/welcome/welcome_bloc.dart';
import '../../../../core/bloc/saloon_registration/saloon_registration_bloc.dart'
    as salon;
import '../../../../core/bloc/influencer_registration/influencer_registration_bloc.dart'
    as influencer;
import '../../../../core/translations/app_translations.dart';
import '../../../../widgets/common/animated_logo.dart';
import '../../../../widgets/common/language_selector.dart';
import '../../../../widgets/common/signup_button.dart';
import '../../../../widgets/common/login_button.dart';
import 'saloon_registration_screen.dart';
import 'influencer_registration_screen.dart';
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
    // Check if we're coming back from another screen
    final currentState = context.read<WelcomeBloc>().state;
    if (!currentState.skipAnimation) {
      // Only start logo animation if not skipping
      context.read<WelcomeBloc>().add(StartLogoAnimation());
    }
  }

  void _onSignupSaloon() {
    // Dismiss keyboard before navigation
    FocusScope.of(context).unfocus();

    print('🎯 Attempting to navigate to salon registration...');

    try {
      // Check if bloc is available
      final bloc = context.read<salon.SaloonRegistrationBloc>();
      print('✅ SaloonRegistrationBloc found: $bloc');

      // Reset registration state and navigate
      bloc.add(salon.ResetRegistration());
      print('✅ ResetRegistration event added');

      bloc.add(salon.GoToStep(0));
      print('✅ GoToStep(0) event added');

      // Navigate to salon registration screen
      print('🚀 Navigating to SaloonRegistrationScreen...');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const SaloonRegistrationScreen(),
        ),
      );
      print('✅ Navigation completed successfully');
    } catch (e) {
      print('❌ Error navigating to salon registration: $e');
      print('🔍 Error type: ${e.runtimeType}');
      print('🔍 Error details: $e');

      // Fallback navigation
      print('🔄 Attempting fallback navigation...');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const SaloonRegistrationScreen(),
        ),
      );
    }
  }

  void _onSignupInfluencer() {
    // Dismiss keyboard before navigation
    FocusScope.of(context).unfocus();

    print('🎯 Attempting to navigate to influencer registration...');

    try {
      // Check if bloc is available
      final bloc = context.read<influencer.InfluencerRegistrationBloc>();
      print('✅ InfluencerRegistrationBloc found: $bloc');

      // Reset registration state and navigate
      bloc.add(influencer.ResetRegistration());
      print('✅ ResetRegistration event added');

      bloc.add(influencer.GoToStep(0));
      print('✅ GoToStep(0) event added');

      // Navigate to influencer registration screen
      print('🚀 Navigating to InfluencerRegistrationScreen...');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const InfluencerRegistrationScreen(),
        ),
      );
      print('✅ Navigation completed successfully');
    } catch (e) {
      print('❌ Error navigating to influencer registration: $e');
      print('🔍 Error type: ${e.runtimeType}');
      print('🔍 Error details: $e');

      // Fallback navigation
      print('🔄 Attempting fallback navigation...');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const InfluencerRegistrationScreen(),
        ),
      );
    }
  }

  void _onLogin() {
    // Navigate to login screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
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
            Color(0xFF1F1E1E), // Top color (lighter)
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              // Content (appears after logo animation)
              BlocBuilder<WelcomeBloc, WelcomeState>(
                builder: (context, state) {
                  // Show content if logo animation is complete OR if we're skipping animation
                  final shouldShowContent =
                      state.showContent || state.skipAnimation;
                  return AnimatedOpacity(
                    opacity: shouldShowContent ? 1.0 : 0.0,
                    duration: const Duration(
                        milliseconds: 800), // Slower, more dramatic fade
                    curve: Curves.easeInOut, // Smooth fade in curve
                    child: shouldShowContent
                        ? _buildContent()
                        : const SizedBox.shrink(),
                  );
                },
              ),

              // Animated Logo (first layer - on top)
              AnimatedLogo(
                onAnimationComplete: () {
                  // This will be called when logo animation is truly complete
                  // and logo is positioned in top-left corner
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return DefaultTextStyle(
      style: AppTheme.globalText, // Poppins font via Google Fonts
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Spacer for logo - increased to avoid overlap with animated logo
                const SizedBox(
                  height: 80,
                ),
                // Welcome Section
                _buildWelcomeSection(),

                const SizedBox(height: 15), // Increased spacing

                // Language Section
                _buildLanguageSection(),

                const SizedBox(height: 10), // Increased spacing
              ],
            ),
            const Spacer(),
            Column(
              children: [
                // Signup Section
                _buildSignupSection(),

                const SizedBox(height: 10), // Increased spacing

                // Login Section
                _buildLoginSection(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 10,
        ),
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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LanguageSelector(),
      ],
    );
  }

  Widget _buildSignupSection() {
    return Column(
      children: [
        SignupButton(
          text: AppTranslations.getString(context, 'signup_saloon'),
          icon: LucideIcons.building2, // Building/shop icon like in the image
          onPressed: _onSignupSaloon,
        ),
        const SizedBox(height: 12),
        SignupButton(
          text: AppTranslations.getString(context, 'signup_influencer'),
          icon: LucideIcons.user, // Person icon like in the image
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
