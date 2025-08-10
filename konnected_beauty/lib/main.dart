import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/bloc/app_bloc_observer.dart';
import 'core/bloc/language/language_bloc.dart';
import 'core/bloc/welcome/welcome_bloc.dart';
import 'core/bloc/saloon_registration/saloon_registration_bloc.dart';
import 'core/bloc/login/login_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/translations/app_translations.dart';
import 'features/auth/presentation/pages/welcome_screen.dart';

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
      ],
      child: BlocBuilder<LanguageBloc, LanguageState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'Konnected Beauty',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            locale: state.locale,
            supportedLocales: AppTranslations.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const WelcomeScreen(),
          );
        },
      ),
    );
  }
}
