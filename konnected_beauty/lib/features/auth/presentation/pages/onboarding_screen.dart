import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/translations/app_translations.dart';
import 'welcome_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/onboarding.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Dark overlay for better text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  // Logo and Welcome Text Section
                  _buildLogoSection(context),
                  const SizedBox(height: 20),
                  // Language Selector
                  _buildLanguageSelector(context),
                  const SizedBox(height: 20),
                  // Get Started Button
                  _buildGetStartedButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo - using the white PNG logo
        Image.asset(
          'assets/images/Konected beauty - Logo white.png',
          width: 100,
          height: 100,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
        // Welcome Text
        Text(
          AppTranslations.getString(context, 'welcome_title'),
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, state) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.1, sigmaY: 20.1),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(
                    0x33FFFFFF), // #FFFFFF33 - white with 20% opacity
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () => _showLanguageDialog(context),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.languages,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getLanguageDisplayText(state.locale),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(
                      LucideIcons.chevronDown,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGetStartedButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () async {
          // Mark onboarding as seen
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('has_seen_onboarding', true);
          print('✅ Onboarding marked as seen');

          // Navigate to welcome screen
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const WelcomeScreen(),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          _getGetStartedText(context),
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  String _getLanguageDisplayText(Locale locale) {
    switch (locale.languageCode) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      default:
        return 'English';
    }
  }

  String _getGetStartedText(BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'fr') {
      return 'Commencer';
    }
    return 'Get started';
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          AppTranslations.getString(context, 'choose_language'),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Français',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              onTap: () {
                context
                    .read<LanguageBloc>()
                    .add(ChangeLanguage(const Locale('fr')));
                Navigator.pop(context);
              },
            ),
            const Divider(color: Color(0xFF3A3A3A)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'English',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              onTap: () {
                context
                    .read<LanguageBloc>()
                    .add(ChangeLanguage(const Locale('en')));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
