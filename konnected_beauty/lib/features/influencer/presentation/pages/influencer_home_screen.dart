import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';

class InfluencerHomeScreen extends StatelessWidget {
  const InfluencerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          AppTranslations.getString(context, 'influencer_home'),
          style: AppTheme.headingStyle,
        ),
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.getString(context, 'welcome_influencer'),
                style: AppTheme.headingStyle,
              ),
              const SizedBox(height: 16),
              Text(
                AppTranslations.getString(
                    context, 'influencer_home_description'),
                style: AppTheme.subtitleStyle,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.accentColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppTranslations.getString(
                              context, 'registration_complete'),
                          style: TextStyle(
                            color: AppTheme.accentColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppTranslations.getString(
                          context, 'registration_complete_message'),
                      style: AppTheme.subtitleStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
