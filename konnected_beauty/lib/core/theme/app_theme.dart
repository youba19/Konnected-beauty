import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF1F1E1E);
  static const Color secondaryColor = Color(0xFF3B3B3B);
  static const Color border2 = Color(0xFF646464);

  static const Color accentColor = Colors.white;
  static const Color textPrimaryColor = Color.fromRGBO(255, 255, 255, 1);
  static const Color textSecondaryColor = Color(0xffD6D1D1);
  static const Color borderColor = Color.fromARGB(255, 255, 255, 255);
  static const Color navBarColor = Color(0xff1F1E1E);
  static const Color navBartextColor = Color(0xff949494);

  static const Color transparentBackground = Colors.transparent;
  static const Color scaffoldBackground = Color(0xFF2A2A2A);
  
  // Success and Error Colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color successLightColor = Color(0xFFE8F5E8);
  static const Color errorColor = Color(0xFFF44336);
  static const Color errorLightColor = Color(0xFFFFEBEE);

  // Font Family
  static const String fontFamily = 'Poppins';

  // Google Fonts Poppins
  static TextStyle get poppinsFont => GoogleFonts.poppins();

  // Global font override - automatically applies Poppins to any TextStyle
  static TextStyle applyPoppins(TextStyle style) {
    return GoogleFonts.poppins().merge(style);
  }

  // Text Styles with comprehensive font weights and sizes
  static TextStyle get headingStyle => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      );

  static TextStyle get subtitleStyle => TextStyle(
        fontSize: 16,
        color: textSecondaryColor,
        height: 1.4,
      );

  static TextStyle get buttonTextStyle => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      );

  static TextStyle get loginButtonTextStyle => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimaryColor,
      );

  static TextStyle get dividerTextStyle => TextStyle(
        fontSize: 14,
        color: textSecondaryColor,
      );

  // Additional font weight and size variations
  static TextStyle getTextStyle({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? textPrimaryColor,
      height: height,
      decoration: decoration,
    );
  }

  // Predefined font weight variations
  static TextStyle get light => getTextStyle(fontWeight: FontWeight.w300);
  static TextStyle get regular => getTextStyle(fontWeight: FontWeight.w400);
  static TextStyle get medium => getTextStyle(fontWeight: FontWeight.w500);
  static TextStyle get semiBold => getTextStyle(fontWeight: FontWeight.w600);
  static TextStyle get bold => getTextStyle(fontWeight: FontWeight.w700);
  static TextStyle get extraBold => getTextStyle(fontWeight: FontWeight.w800);

  // Predefined font size variations
  static TextStyle get caption => getTextStyle(fontSize: 12);
  static TextStyle get small => getTextStyle(fontSize: 14);
  static TextStyle get normal => getTextStyle(fontSize: 16);
  static TextStyle get large => getTextStyle(fontSize: 18);
  static TextStyle get title => getTextStyle(fontSize: 20);
  static TextStyle get headline => getTextStyle(fontSize: 24);
  static TextStyle get display => getTextStyle(fontSize: 32);

  // Common text styles with specific combinations
  static TextStyle get heading =>
      getTextStyle(fontSize: 28, fontWeight: FontWeight.bold);
  static TextStyle get subtitle =>
      getTextStyle(fontSize: 16, fontWeight: FontWeight.normal, height: 1.4);
  static TextStyle get buttonText =>
      getTextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  static TextStyle get captionText =>
      getTextStyle(fontSize: 14, fontWeight: FontWeight.normal);
  static TextStyle get labelText =>
      getTextStyle(fontSize: 14, fontWeight: FontWeight.w600);

  // Font override system - forces all text to use Poppins
  static TextStyle forceFont(TextStyle style) {
    return style.copyWith(fontFamily: fontFamily);
  }

  // Global text style that overrides everything
  static TextStyle get globalText => TextStyle(
        fontSize: 16,
        color: textPrimaryColor,
      );

  // Custom Text widget that always uses Poppins
  static Widget text(
    String data, {
    TextStyle? style,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return Text(
      data,
      style: TextStyle(
        fontSize: fontSize ?? style?.fontSize ?? 16,
        fontWeight: fontWeight ?? style?.fontWeight,
        color: color ?? style?.color ?? textPrimaryColor,
      ).merge(style),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  // Force font override for any TextStyle
  static TextStyle forceMontserrat(TextStyle style) {
    return style.copyWith(fontFamily: fontFamily);
  }

  // Create a TextStyle with guaranteed Montserrat font
  static TextStyle createStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize ?? 16,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ?? textPrimaryColor,
      height: height,
      decoration: decoration,
    );
  }

  // Global font override - use this to force Montserrat anywhere
  static TextStyle overrideFont(TextStyle? style) {
    if (style == null) {
      return TextStyle(fontFamily: fontFamily);
    }
    return style.copyWith(fontFamily: fontFamily);
  }

  // Theme Data
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: primaryColor,
      fontFamily: fontFamily, // Global font
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        secondary: secondaryColor,
        surface: primaryColor,
      ),
      textTheme: TextTheme(
        // Display styles
        displayLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textPrimaryColor,
        ),
        displayMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimaryColor,
        ),
        displaySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),

        // Headline styles
        headlineLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimaryColor,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        headlineSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
        ),

        // Title styles
        titleLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        titleMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
        ),
        titleSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
        ),

        // Body styles
        bodyLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textSecondaryColor,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondaryColor,
        ),
        bodySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondaryColor,
        ),

        // Label styles
        labelLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
        labelMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
        labelSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
      ),
    );
  }
}
