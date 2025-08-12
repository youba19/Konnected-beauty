import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF1A1A1A);
  static const Color secondaryColor = Color(0xFF2D2D2D);
  static const Color accentColor = Colors.white;
  static const Color textPrimaryColor = Colors.white;
  static const Color textSecondaryColor = Color(0xFFB0B0B0);
  static const Color borderColor = Color(0xFF404040);

  // Font Family
  static const String fontFamily = 'Montserrat';

  // Text Styles using Google Fonts
  static TextStyle get headingStyle => GoogleFonts.montserrat(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      );

  static TextStyle get subtitleStyle => GoogleFonts.montserrat(
        fontSize: 16,
        color: textSecondaryColor,
        height: 1.4,
      );

  static TextStyle get buttonTextStyle => GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      );

  static TextStyle get loginButtonTextStyle => GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimaryColor,
      );

  static TextStyle get dividerTextStyle => GoogleFonts.montserrat(
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
      textTheme: GoogleFonts.montserratTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        headlineLarge: headingStyle,
        headlineMedium: headingStyle.copyWith(fontSize: 24),
        headlineSmall: headingStyle.copyWith(fontSize: 20),
        bodyLarge: subtitleStyle,
        bodyMedium: subtitleStyle.copyWith(fontSize: 14),
        bodySmall: subtitleStyle.copyWith(fontSize: 12),
        labelLarge: buttonTextStyle,
        labelMedium: buttonTextStyle.copyWith(fontSize: 14),
        labelSmall: buttonTextStyle.copyWith(fontSize: 12),
      ),
    );
  }
}
