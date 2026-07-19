import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared salon (company) visual tokens for dark and light mode.
class SalonUiTheme {
  const SalonUiTheme._(this.brightness);

  final Brightness brightness;

  factory SalonUiTheme.of(BuildContext context) {
    return SalonUiTheme._(Theme.of(context).brightness);
  }

  factory SalonUiTheme.from(Brightness brightness) {
    return SalonUiTheme._(brightness);
  }

  bool get isDark => brightness == Brightness.dark;

  // Brand blues (shared)
  static const Color blueTop = Color(0xFF3B6FD4);
  static const Color blueUpper = Color(0xFF2E5CB8);
  static const Color blueMid = Color(0xFF1A3568);
  static const Color blueLower = Color(0xFF0D1A30);
  static const Color profileBlue = Color(0xFF5B8FD9);
  static const Color accentBlue = Color(0xFF3B6FD4);

  Color get bg => isDark ? const Color(0xFF000000) : const Color(0xFFF7F8FA);

  Color get card => isDark ? const Color(0xFF1C1C1E) : Colors.white;

  Color get cardAlt => isDark ? const Color(0xFF000000) : Colors.white;

  Color get cardBorder =>
      isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E7EB);

  Color get bannerFill =>
      isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEDEDED);

  Color get textPrimary => isDark ? Colors.white : const Color(0xFF111827);

  Color get textSecondary =>
      isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF6B7280);

  Color get textMuted =>
      isDark ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF9CA3AF);

  Color get borderSubtle =>
      isDark ? const Color(0xE6FFFFFF) : const Color(0xFFD1D5DB);

  Color get buttonFillTop =>
      isDark ? const Color(0xFF152A52) : Colors.white;

  Color get buttonFillBottom =>
      isDark ? const Color(0xFF0D1A30) : Colors.white;

  /// Icon on nav/back buttons: white on dark fill, brand blue on white fill.
  Color get buttonIcon => isDark ? Colors.white : accentBlue;

  Color get iconButtonBg =>
      isDark ? Colors.transparent : Colors.white.withValues(alpha: 0.9);

  Color get navBar =>
      isDark ? const Color(0xFF3A3A3C) : Colors.white;

  Color get navSelected => isDark ? Colors.white : const Color(0xFF111827);

  Color get navUnselected =>
      isDark ? const Color(0xFF757575) : const Color(0xFF9CA3AF);

  Color get fabBg => isDark ? Colors.black : Colors.white;

  Color get fabBorder =>
      isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E7EB);

  Color get outlinedButtonBorder =>
      isDark ? Colors.white.withValues(alpha: 0.35) : const Color(0xFFD1D5DB);

  Color get primaryButtonBg => isDark ? Colors.white : const Color(0xFF111827);

  Color get primaryButtonFg => isDark ? Colors.black : Colors.white;

  Color get sheetOverlayButton =>
      isDark ? Colors.black.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.85);

  List<Color> get headerGradient => isDark
      ? const [
          blueTop,
          blueUpper,
          blueMid,
          blueLower,
          Color(0xFF000000),
        ]
      : const [
          Color(0xFF3B6FD4),
          Color(0xFF5B8FD9),
          Color(0xFF8BB0E8),
          Color(0xFFC8D9F5),
          Color(0xFFF7F8FA),
        ];

  List<double> get headerStops => isDark
      ? const [0.0, 0.22, 0.48, 0.74, 1.0]
      : const [0.0, 0.28, 0.52, 0.78, 1.0];

  List<Color> get sheetHeaderGradient => isDark
      ? const [
          blueTop,
          blueUpper,
          blueMid,
          Color(0x00000000),
        ]
      : const [
          Color(0xFF3B6FD4),
          Color(0xFF5B8FD9),
          Color(0xFF9DBCEB),
          Color(0x00F7F8FA),
        ];

  List<Color> get fullSheetGradient => isDark
      ? const [
          blueTop,
          blueUpper,
          blueMid,
          blueLower,
          Color(0xFF000000),
        ]
      : const [
          Color(0xFF3B6FD4),
          Color(0xFF5B8FD9),
          Color(0xFF8BB0E8),
          Color(0xFFC8D9F5),
          Color(0xFFF7F8FA),
        ];

  List<double> get fullSheetStops => isDark
      ? const [0.0, 0.28, 0.55, 0.82, 1.0]
      : const [0.0, 0.30, 0.55, 0.80, 1.0];

  SystemUiOverlayStyle get systemOverlay => isDark
      ? SystemUiOverlayStyle.light
      : SystemUiOverlayStyle.dark;

  String get logoAsset => isDark
      ? 'assets/images/Konected beauty - Logo white.png'
      : 'assets/images/Konected beauty - Logo white.png';
}
