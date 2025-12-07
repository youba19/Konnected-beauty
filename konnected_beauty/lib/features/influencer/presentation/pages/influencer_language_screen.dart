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
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: AppTheme.getScaffoldBackground(brightness),
      body: Stack(
        children: [
          // TOP GREEN GLOW
          Positioned(
            top: -120,
            left: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  // soft radial green halo like the screenshot
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 0.8,
                    colors: [
                      AppTheme.greenPrimary.withOpacity(0.35),
                      brightness == Brightness.dark
                          ? AppTheme.transparentBackground
                          : AppTheme.textWhite54,
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
                        SizedBox(height: 24),

                        // Language Selection Field
                        _buildLanguageField(),

                        SizedBox(height: 24),

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
            child: Icon(
              Icons.arrow_back_ios,
              color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              size: 20,
            ),
          ),

          SizedBox(height: 20),

          // Title Row
          Row(
            children: [
              // Language Icon
              Icon(
                LucideIcons.languages,
                color:
                    AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
                size: 28,
              ),

              SizedBox(width: 12),

              // Title
              Text(
                AppTranslations.getString(context, 'language'),
                style: TextStyle(
                  color: AppTheme.getTextPrimaryColor(
                      Theme.of(context).brightness),
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
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.transparentBackground
            : AppTheme.textWhite54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness)
              .withOpacity(0.3),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLanguage,
          isExpanded: true,
          dropdownColor:
              AppTheme.getSecondaryColor(Theme.of(context).brightness),
          style: TextStyle(
            color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
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
                    Icon(
                      LucideIcons.languages,
                      color: AppTheme.getTextPrimaryColor(
                          Theme.of(context).brightness),
                      size: 22,
                    ),
                    SizedBox(width: 12),
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
                    Icon(
                      LucideIcons.languages,
                      color: AppTheme.getTextPrimaryColor(
                          Theme.of(context).brightness),
                      size: 22,
                    ),
                    SizedBox(width: 12),
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
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.transparentBackground
            : AppTheme.textWhite54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness)
              .withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.transparentBackground
            : AppTheme.textWhite54,
        child: InkWell(
          onTap: _selectedLanguage != null ? _saveLanguage : null,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              AppTranslations.getString(context, 'save_changes'),
              style: TextStyle(
                color:
                    AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
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
