import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/bloc/language/language_bloc.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, state) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showLanguageDialog(context),
            child: Row(
              children: [
                const Icon(
                  Icons.language,
                  color: AppTheme.textPrimaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getLanguageDisplayText(state.locale),
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppTheme.textPrimaryColor,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getLanguageDisplayText(Locale locale) {
    switch (locale.languageCode) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      default:
        return 'Français';
    }
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryColor,
        title: Text(
          'Choisir la langue',
          style: TextStyle(color: AppTheme.textPrimaryColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'Français',
                style: TextStyle(color: AppTheme.textPrimaryColor),
              ),
              onTap: () {
                context
                    .read<LanguageBloc>()
                    .add(ChangeLanguage(const Locale('fr')));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(
                'English',
                style: TextStyle(color: AppTheme.textPrimaryColor),
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
