import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

class InfluencerLanguageScreen extends StatefulWidget {
  const InfluencerLanguageScreen({super.key});

  @override
  State<InfluencerLanguageScreen> createState() =>
      _InfluencerLanguageScreenState();
}

class _InfluencerLanguageScreenState extends State<InfluencerLanguageScreen> {
  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    // Get current language from the bloc
    final currentState = context.read<LanguageBloc>().state;
    if (currentState is LanguageLoaded) {
      _selectedLanguage = currentState.locale.languageCode;
    }
  }

  void _saveLanguage() {
    if (_selectedLanguage != null) {
      final locale = Locale(_selectedLanguage!);
      context.read<LanguageBloc>().add(ChangeLanguage(locale));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // TOP GREEN GLOW
          Positioned(
            top: -140,
            left: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  // soft radial green halo like the screenshot
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 0.9,
                    colors: [
                      const Color(0xFF22C55E).withOpacity(0.55),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // CONTENT
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),

                        // Language Selection Field
                        _buildLanguageField(),

                        const SizedBox(height: 24),

                        // Save Changes Button
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(height: 20),

          // Title Row
          Row(
            children: [
              // Language Icon
              const Icon(
                LucideIcons.languages,
                color: Colors.white,
                size: 28,
              ),

              const SizedBox(width: 12),

              // Title
              Text(
                AppTranslations.getString(context, 'language'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageField() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.transparentBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLanguage,
          isExpanded: true,
          dropdownColor: AppTheme.secondaryColor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white,
            size: 22,
          ),
          items: [
            DropdownMenuItem<String>(
              value: 'en',
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.languages,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                        '${AppTranslations.getString(context, 'language')} (English)'),
                  ],
                ),
              ),
            ),
            DropdownMenuItem<String>(
              value: 'fr',
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.languages,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                        '${AppTranslations.getString(context, 'language')} (Français)'),
                  ],
                ),
              ),
            ),
          ],
          onChanged: (String? newValue) {
            setState(() {
              _selectedLanguage = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.transparentBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _selectedLanguage != null ? _saveLanguage : null,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              AppTranslations.getString(context, 'save_changes'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getLanguageName(String? languageCode) {
    switch (languageCode) {
      case 'fr':
        return 'Français';
      case 'en':
      default:
        return 'English';
    }
  }
}
