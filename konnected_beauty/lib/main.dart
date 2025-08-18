import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/bloc/app_bloc_observer.dart';
import 'core/bloc/language/language_bloc.dart';
import 'core/bloc/welcome/welcome_bloc.dart';
import 'core/bloc/saloon_registration/saloon_registration_bloc.dart';
import 'core/bloc/influencer_registration/influencer_registration_bloc.dart';
import 'core/bloc/login/login_bloc.dart';
import 'core/bloc/reset_password/reset_password_bloc.dart';
import 'core/bloc/auth/auth_bloc.dart';
import 'core/bloc/salon_services/salon_services_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/translations/app_translations.dart';
import 'features/auth/presentation/pages/welcome_screen.dart';
import 'features/company/presentation/pages/salon_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = AppBlocObserver();

  // Debug: Print font loading
  print('🎨 === MAIN DEBUG ===');
  print('🎨 AppTheme.fontFamily: ${AppTheme.fontFamily}');

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
        BlocProvider<InfluencerRegistrationBloc>(
          create: (context) => InfluencerRegistrationBloc(),
        ),
        BlocProvider<LoginBloc>(
          create: (context) => LoginBloc(),
        ),
        BlocProvider<ResetPasswordBloc>(
          create: (context) => ResetPasswordBloc(),
        ),
        BlocProvider<AuthBloc>(
          create: (context) {
            print('🏗️ === CREATING AUTH BLOC ===');
            print('🏗️ Adding CheckProfileStatus event');
            return AuthBloc()..add(CheckProfileStatus());
          },
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
                theme: ThemeData(
                  // Inherit from AppTheme.darkTheme
                  brightness: Brightness.dark,
                  primaryColor: AppTheme.primaryColor,
                  scaffoldBackgroundColor: AppTheme.transparentBackground,
                  fontFamily: AppTheme.fontFamily,
                  // Force all text to use Poppins with aggressive override using Google Fonts
                  textTheme:
                      GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme)
                          .apply(
                    bodyColor: AppTheme.textPrimaryColor,
                    displayColor: AppTheme.textPrimaryColor,
                  ),

                  // Apply font family to other theme elements
                  appBarTheme: AppTheme.darkTheme.appBarTheme.copyWith(
                    titleTextStyle: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),

                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      textStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      textStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  outlinedButtonTheme: OutlinedButtonThemeData(
                    style: OutlinedButton.styleFrom(
                      textStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  inputDecorationTheme: InputDecorationTheme(
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    errorStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                locale: languageState.locale,
                supportedLocales: AppTranslations.supportedLocales,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: _buildHomeScreen(authState),
                builder: (context, child) {
                  return FontOverrideWidget(
                    child: child!,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHomeScreen(AuthState authState) {
    if (authState is AuthLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryColor,
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.textPrimaryColor,
          ),
        ),
      );
    } else if (authState is AuthAuthenticated) {
      if (authState.role == 'saloon') {
        return const SalonHomeScreen();
      } else {
        return const WelcomeScreen();
      }
    } else {
      // User is not authenticated or profile is incomplete
      // Show welcome screen which will handle navigation to appropriate registration
      return const WelcomeScreen();
    }
  }
}

// Custom widget that forces ALL text to use Poppins font
class FontOverrideWidget extends StatelessWidget {
  final Widget child;

  const FontOverrideWidget({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: AppTheme.textPrimaryColor,
      ),
      child: Builder(
        builder: (context) {
          return DefaultTextStyle(
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppTheme.textPrimaryColor,
            ),
            child: child,
          );
        },
      ),
    );
  }
}

// Extension to force Poppins on all TextStyle objects
extension TextStyleExtension on TextStyle {
  TextStyle get poppins => GoogleFonts.poppins().merge(this);
}

//   Widget _buildHomeScreen(AuthState authState) {
//     print('🏠 === BUILDING HOME SCREEN ===');
//     print('🏠 Auth State Type: ${authState.runtimeType}');

//     // TEMPORARY: Force navigate to specific screen for testing
//     // Uncomment the line below and change the screen you want to test
//     // return const SaloonRegistrationScreen(); // Test registration
//     // return const LoginScreen(); // Test login
//     // return const SalonHomeScreen(); // Test salon home
//     // return const WelcomeScreen(); // Test welcome screen

//     if (authState is AuthLoading) {
//       print('🏠 Showing splash screen with logo animation');
//       return const SplashScreen();
//     } else if (authState is AuthAuthenticated) {
//       print('🏠 User is authenticated');
//       print('🏠 Role: ${authState.role}');
//       print('🏠 Email: ${authState.email}');

//       // Navigate to appropriate home screen based on role
//       if (authState.role == 'saloon') {
//         print('🏠 Navigating to SalonHomeScreen');
//         return const SalonHomeScreen();
//       } else {
//         print('🏠 Navigating to WelcomeScreen (non-salon role)');
//         // For influencer or other roles, show welcome screen for now
//         return const WelcomeScreen();
//       }
//     } else {
//       print('🏠 User is not authenticated, showing WelcomeScreen');
//       // AuthUnauthenticated or AuthError → show Welcome screen
//       // TEMPORARY: Navigate directly to salon profile step for testing
//       return const SaloonRegistrationScreen();
//     }
//   }
// }

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [
//             Color(0xFF1F1E1E), // Top color
//             Color(0xFF3B3B3B), // Bottom color
//           ],
//         ),
//       ),
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         body: AnimatedLogo(
//           onAnimationComplete: () {
//             // After logo animation completes, navigate to WelcomeScreen
//             Navigator.of(context).pushReplacement(
//               MaterialPageRoute(builder: (context) => const WelcomeScreen()),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
