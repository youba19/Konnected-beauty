import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF1F1E1E);
  static const Color secondaryColor = Color(0xFF3B3B3B);
  static const Color border2 = Color(0xFF646464);

  static const Color accentColor = Colors.white;
  static const Color textPrimaryColor = Colors.white;
  static const Color textSecondaryColor = Color.fromARGB(255, 235, 233, 233);
  static const Color borderColor = Color.fromARGB(255, 255, 255, 255);
  static const Color navBarColor = Color.fromARGB(255, 40, 40, 40);
  static const Color transparentBackground = Colors.transparent;
  static const Color scaffoldBackground =
      Color(0xFF2A2A2A); // Solid color that matches gradient

  // Font Family
  static const String fontFamily = 'Montserrat-Regular';

  // Text Styles using local Montserrat font files
  static TextStyle get headingStyle => const TextStyle(
        fontFamily: 'Montserrat-Regular',
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      );

  static TextStyle get subtitleStyle => const TextStyle(
        fontFamily: 'Montserrat-Regular',
        fontSize: 16,
        color: textSecondaryColor,
        height: 1.4,
      );

  static TextStyle get buttonTextStyle => const TextStyle(
        fontFamily: 'Montserrat-Regular',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      );

  static TextStyle get loginButtonTextStyle => const TextStyle(
        fontFamily: 'Montserrat-Regular',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimaryColor,
      );

  static TextStyle get dividerTextStyle => const TextStyle(
        fontFamily: 'Montserrat-Regular',
        fontSize: 14,
        color: textSecondaryColor,
      );

  // Theme Data
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        secondary: secondaryColor,
        surface: primaryColor,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontFamily: 'Montserrat-Regular',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textPrimaryColor),
        headlineMedium: TextStyle(
            fontFamily: 'Montserrat-Regular',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textPrimaryColor),
        headlineSmall: TextStyle(
            fontFamily: 'Montserrat-Regular',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimaryColor),
        bodyLarge: TextStyle(
            fontFamily: 'Montserrat-Regular',
            fontSize: 16,
            color: textSecondaryColor),
        bodyMedium: TextStyle(
            fontFamily: 'Montserrat-Regular',
            fontSize: 14,
            color: textSecondaryColor),
        bodySmall: TextStyle(
            fontFamily: 'Montserrat-Regular',
            fontSize: 12,
            color: textSecondaryColor),
        labelLarge: TextStyle(
            fontFamily: 'Montserrat-Regular',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: primaryColor),
        labelMedium: TextStyle(
            fontFamily: 'Montserrat-Regular',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: primaryColor),
        labelSmall: TextStyle(
            fontFamily: 'Montserrat-Regular',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: primaryColor),
      ),
    );
  }
}
