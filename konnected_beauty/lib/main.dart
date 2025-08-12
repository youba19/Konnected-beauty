import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/bloc/app_bloc_observer.dart';
import 'core/bloc/language/language_bloc.dart';
import 'core/bloc/welcome/welcome_bloc.dart';
import 'core/bloc/saloon_registration/saloon_registration_bloc.dart';
import 'core/bloc/login/login_bloc.dart';
import 'core/bloc/reset_password/reset_password_bloc.dart';
import 'core/bloc/auth/auth_bloc.dart';
import 'core/bloc/salon_services/salon_services_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/translations/app_translations.dart';
import 'features/auth/presentation/pages/welcome_screen.dart';
import 'features/company/presentation/pages/salon_home_screen.dart';

void main() {
  Bloc.observer = AppBlocObserver();
  runApp(const KonnectedBeautyApp());
}

class KonnectedBeautyApp extends StatelessWidget {
  const KonnectedBeautyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LanguageBloc>(
          create: (context) => LanguageBloc()..add(LoadLanguage()),
        ),
        BlocProvider<WelcomeBloc>(
          create: (context) => WelcomeBloc(),
        ),
        BlocProvider<SaloonRegistrationBloc>(
          create: (context) => SaloonRegistrationBloc(),
        ),
        BlocProvider<LoginBloc>(
          create: (context) => LoginBloc(),
        ),
        BlocProvider<ResetPasswordBloc>(
          create: (context) => ResetPasswordBloc(),
        ),
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc()..add(CheckAuthStatus()),
        ),
        BlocProvider<SalonServicesBloc>(
          create: (context) => SalonServicesBloc(),
        ),
      ],
      child: BlocBuilder<LanguageBloc, LanguageState>(
        builder: (context, languageState) {
          return BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              return MaterialApp(
                title: 'Konnected Beauty',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.darkTheme,
                locale: languageState.locale,
                supportedLocales: AppTranslations.supportedLocales,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: _buildHomeScreen(authState),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHomeScreen(AuthState authState) {
    print('🏠 === BUILDING HOME SCREEN ===');
    print('🏠 Auth State Type: ${authState.runtimeType}');

    if (authState is AuthLoading) {
      print('🏠 Showing loading screen');
      return const Scaffold(
        backgroundColor: AppTheme.primaryColor,
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.textPrimaryColor,
          ),
        ),
      );
    } else if (authState is AuthAuthenticated) {
      print('🏠 User is authenticated');
      print('🏠 Role: ${authState.role}');
      print('🏠 Email: ${authState.email}');

      // Navigate to appropriate home screen based on role
      if (authState.role == 'saloon') {
        print('🏠 Navigating to SalonHomeScreen');
        return const SalonHomeScreen();
      } else {
        print('🏠 Navigating to WelcomeScreen (non-salon role)');
        // For influencer or other roles, show welcome screen for now
        return const WelcomeScreen();
      }
    } else {
      print('🏠 User is not authenticated, showing WelcomeScreen');
      // AuthUnauthenticated or AuthError
      return const WelcomeScreen();
    }
  }
}
