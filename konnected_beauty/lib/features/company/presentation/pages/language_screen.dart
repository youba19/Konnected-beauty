import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/theme/theme_bloc.dart';
import '../../../../core/theme/salon_ui_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

abstract final class _LanguageUi {
  static const double radius = 16;
  static const double buttonSize = 48;
  static const double buttonRadius = 14;
}

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
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
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final ui = SalonUiTheme.from(themeState.brightness);
        final topInset = MediaQuery.paddingOf(context).top;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: ui.systemOverlay,
          child: Scaffold(
            backgroundColor: ui.bg,
            body: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: topInset + 220,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: ui.fullSheetGradient,
                        stops: ui.fullSheetStops,
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(ui),
                        const SizedBox(height: 22),
                        _buildLanguageField(ui),
                        const SizedBox(height: 18),
                        _buildSaveButton(ui),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(SalonUiTheme ui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: _LanguageUi.buttonSize,
            height: _LanguageUi.buttonSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ui.buttonFillTop,
                  ui.buttonFillBottom,
                ],
              ),
              borderRadius: BorderRadius.circular(_LanguageUi.buttonRadius),
              border: ui.isDark
                  ? null
                  : Border.all(color: ui.cardBorder, width: 1),
            ),
            alignment: Alignment.center,
            child: Icon(
              LucideIcons.arrowLeft,
              color: ui.buttonIcon,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Icon(
              LucideIcons.languages,
              color: ui.textPrimary,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              AppTranslations.getString(context, 'language'),
              style: TextStyle(
                color: ui.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageField(SalonUiTheme ui) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ui.card,
        borderRadius: BorderRadius.circular(_LanguageUi.radius),
        border: Border.all(
          color: ui.cardBorder,
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLanguage,
          isExpanded: true,
          dropdownColor: ui.card,
          style: TextStyle(
            color: ui.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: ui.textPrimary,
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
                      color: ui.textPrimary,
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
                    Icon(
                      LucideIcons.languages,
                      color: ui.textPrimary,
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

  Widget _buildSaveButton(SalonUiTheme ui) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: ui.primaryButtonBg,
        borderRadius: BorderRadius.circular(_LanguageUi.radius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _selectedLanguage != null ? _saveLanguage : null,
          borderRadius: BorderRadius.circular(_LanguageUi.radius),
          child: Center(
            child: Text(
              AppTranslations.getString(context, 'save_changes'),
              style: TextStyle(
                color: ui.primaryButtonFg,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
