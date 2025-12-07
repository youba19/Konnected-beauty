import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ============================================
  // DARK THEME COLORS
  // ============================================

  // Background Colors
  static const Color primaryColor = Color(0xFF1F1E1E);
  static const Color secondaryColor = Color(0xFF353535);
  static const Color scaffoldBackground = Color(0xFF1F1E1E);
  static const Color scaffoldBackgroundDark =
      Color(0xFF121212); // Used in many screens
  static const Color scaffoldBackgroundVariant = Color(0xFF1F1F1F);
  static const Color cardBackgroundDark =
      Color(0xFF2A2A2A); // Card/container background
  static const Color placeholderBackground =
      Color(0xFF2C2C2C); // Placeholder/icon background
  static const Color buttonBackgroundDark =
      Color(0xFF3A3A3A); // Button/container background
  static const Color border2 = Color(0xFF4a4949);
  static const Color transparentBackground = Colors.transparent;

  // Text Colors
  static const Color accentColor = Colors.white;
  static const Color textPrimaryColor = Color.fromRGBO(255, 255, 255, 1);
  static const Color textSecondaryColor = Color(0xffD6D1D1);
  static const Color textTertiaryColor = Color(0xFF9CA3AF); // Light gray text
  static const Color textWhite70 = Colors.white70;
  static const Color textWhite54 = Colors.white54;
  static const Color textBlack87 = Colors.black87;

  // Border Colors
  static const Color borderColor = Color.fromARGB(255, 255, 255, 255);
  static const Color borderColorGray = Color(0xFF404040);
  static const Color borderColorLight = Colors.grey;

  // Navigation Bar Colors
  static const Color navBarColor = Color(0xff1F1E1E);
  static const Color navBartextColor = Color(0xff949494);

  // Green Colors (Brand)
  static const Color greenColor = Color(0xFF00D32A);
  static const Color greenPrimary = Color(0xFF22C55E); // Most common green
  static const Color greenDark = Color(0xFF16A34A); // Darker green
  static const Color greenDarkest = Color(0xFF337f2b); // Darkest green

  // Status Colors
  static const Color statusRed = Colors.red;
  static const Color statusOrange = Colors.orange;
  static const Color statusBlue = Colors.blue;
  static const Color statusGreen = Colors.green;

  // Success and Error Colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color successLightColor = Color(0xFFE8F5E8);
  static const Color errorColor = Color(0xFFF44336);
  static const Color errorLightColor = Color(0xFFFFEBEE);

  // Shimmer/Loading Colors
  static const Color shimmerBase = Color(0xFFE0E0E0); // Colors.grey[300]
  static const Color shimmerHighlight = Color(0xFFF5F5F5); // Colors.grey[100]
  static const Color shimmerBaseDark = Color(0xFF424242); // Colors.grey[800]
  static const Color shimmerHighlightDark =
      Color(0xFF616161); // Colors.grey[600]
  static const Color shimmerBaseMedium = Color(0xFF757575); // Colors.grey[600]
  static const Color shimmerBaseMediumDark =
      Color(0xFF616161); // Colors.grey[700]

  // ============================================
  // LIGHT THEME COLORS
  // ============================================

  // Background Colors
  static const Color lightPrimaryColor = Colors.white;
  static const Color lightSecondaryColor = Color(0xFFF5F5F5);
  static const Color lightScaffoldBackground = Colors.white;
  static const Color lightCardBackground = Colors.white;
  static const Color lightPlaceholderBackground =
      Color(0xFFE5E7EB); // Light gray for placeholders
  static const Color lightBannerBackground =
      Color(0xFFEDEDED); // Light gray for banners

  // Text Colors
  static const Color lightTextPrimaryColor = Color(0xFF111827); // Black text
  static const Color lightTextSecondaryColor = Color(0xFF6B7280); // Gray text
  static const Color lightTextTertiaryColor =
      Color(0xFF9CA3AF); // Lighter gray text

  // Border Colors
  static const Color lightBorderColor = Color(0xFFE5E7EB); // Light gray border
  static const Color lightBorderColorDark =
      Color(0xFFD1D5DB); // Darker gray border
  static const Color lightCardBorderColor =
      Color(0xFFEDEDED); // Card border color

  // Navigation Bar Colors
  static const Color lightNavBarColor = Colors.white;
  static const Color lightNavBarTextColor = Color(0xFF949494); // Inactive
  static const Color lightNavBarActiveColor = Color(0xFF16A34A); // Active green

  // ============================================
  // THEME-AWARE COLOR GETTERS
  // ============================================

  // Background Colors
  static Color getScaffoldBackground(Brightness brightness) {
    return brightness == Brightness.dark
        ? scaffoldBackgroundDark
        : lightScaffoldBackground;
  }

  static Color getCardBackground(Brightness brightness) {
    return brightness == Brightness.dark
        ? cardBackgroundDark
        : lightCardBackground;
  }

  static Color getPlaceholderBackground(Brightness brightness) {
    return brightness == Brightness.dark
        ? placeholderBackground
        : lightPlaceholderBackground;
  }

  static Color getButtonBackground(Brightness brightness) {
    return brightness == Brightness.dark
        ? buttonBackgroundDark
        : lightSecondaryColor;
  }

  static Color getSecondaryColor(Brightness brightness) {
    return brightness == Brightness.dark ? secondaryColor : lightSecondaryColor;
  }

  // Text Colors
  static Color getTextPrimaryColor(Brightness brightness) {
    return brightness == Brightness.dark
        ? textPrimaryColor
        : lightTextPrimaryColor;
  }

  static Color getTextSecondaryColor(Brightness brightness) {
    return brightness == Brightness.dark
        ? textSecondaryColor
        : lightTextSecondaryColor;
  }

  static Color getTextTertiaryColor(Brightness brightness) {
    return brightness == Brightness.dark
        ? textTertiaryColor
        : lightTextTertiaryColor;
  }

  // Border Colors
  static Color getBorderColor(Brightness brightness) {
    return brightness == Brightness.dark ? borderColor : lightBorderColor;
  }

  static Color getBorderColorGray(Brightness brightness) {
    return brightness == Brightness.dark
        ? borderColorGray
        : lightBorderColorDark;
  }

  // Navigation Bar Colors
  static Color getNavBarColor(Brightness brightness) {
    return brightness == Brightness.dark ? navBarColor : lightNavBarColor;
  }

  static Color getNavBarTextColor(Brightness brightness) {
    return brightness == Brightness.dark
        ? navBartextColor
        : lightNavBarTextColor;
  }

  static Color getNavBarActiveColor(Brightness brightness) {
    return brightness == Brightness.dark
        ? greenPrimary
        : lightNavBarActiveColor;
  }

  // Shimmer Colors
  static Color getShimmerBase(Brightness brightness) {
    return brightness == Brightness.dark ? shimmerBaseDark : shimmerBase;
  }

  static Color getShimmerHighlight(Brightness brightness) {
    return brightness == Brightness.dark
        ? shimmerHighlightDark
        : shimmerHighlight;
  }

  // Font Family
  static String get fontFamily => GoogleFonts.poppins().fontFamily ?? 'Poppins';

  // Google Fonts Poppins
  static TextStyle get poppinsFont => GoogleFonts.poppins();

  // Global font override - automatically applies Poppins to any TextStyle
  static TextStyle applyPoppins(TextStyle style) {
    return GoogleFonts.poppins().merge(style);
  }

  // Text Styles with comprehensive font weights and sizes
  static TextStyle get headingStyle => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      );

  static TextStyle get subtitleStyle => GoogleFonts.poppins(
        fontSize: 16,
        color: textSecondaryColor,
        height: 1.4,
      );

  static TextStyle get buttonTextStyle => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      );

  static TextStyle get loginButtonTextStyle => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimaryColor,
      );

  static TextStyle get dividerTextStyle => GoogleFonts.poppins(
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
    return GoogleFonts.poppins(
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
  static TextStyle get globalText => GoogleFonts.poppins(
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
      style: GoogleFonts.poppins(
        fontSize: fontSize ?? style?.fontSize ?? 16,
        fontWeight: fontWeight ?? style?.fontWeight,
        color: color ?? style?.color ?? textPrimaryColor,
      ).merge(style),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  // Create a TextStyle with guaranteed Poppins font
  static TextStyle createStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize ?? 16,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ?? textPrimaryColor,
      height: height,
      decoration: decoration,
    );
  }

  // Global font override - use this to force Poppins anywhere
  static TextStyle overrideFont(TextStyle? style) {
    if (style == null) {
      return GoogleFonts.poppins();
    }
    return GoogleFonts.poppins().merge(style);
  }

  // Theme Data
  static ThemeData getThemeData(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }

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

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: lightPrimaryColor,
      scaffoldBackgroundColor: lightScaffoldBackground,
      fontFamily: fontFamily,
      colorScheme: const ColorScheme.light(
        primary: lightTextPrimaryColor,
        secondary: lightSecondaryColor,
        surface: lightCardBackground,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: lightTextPrimaryColor,
        ),
        displayMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: lightTextPrimaryColor,
        ),
        displaySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: lightTextPrimaryColor,
        ),
        headlineLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: lightTextPrimaryColor,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: lightTextPrimaryColor,
        ),
        headlineSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: lightTextPrimaryColor,
        ),
        titleLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: lightTextPrimaryColor,
        ),
        titleMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: lightTextPrimaryColor,
        ),
        titleSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: lightTextPrimaryColor,
        ),
        bodyLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: lightTextPrimaryColor,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: lightTextSecondaryColor,
        ),
        bodySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: lightTextSecondaryColor,
        ),
        labelLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: lightTextPrimaryColor,
        ),
        labelMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: lightTextPrimaryColor,
        ),
        labelSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: lightTextPrimaryColor,
        ),
      ),
    );
  }
}
