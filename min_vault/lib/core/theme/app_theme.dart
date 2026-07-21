import 'package:flutter/material.dart';

abstract final class AppTheme {
  static Brightness _brightness = Brightness.light;

  /// Called by [ThemeCubit] on every toggle so the getters below
  /// return the right palette on the next build.
  static void applyBrightness(Brightness brightness) {
    _brightness = brightness;
  }

  static bool get _isDark => _brightness == Brightness.dark;

  // Brand colors — fixed across modes.
  static const Color accentColor = Color(0xFF4361EE);
  static const Color accentLightColor = Color(0xFFEEF2FF);
  static const Color dangerColor = Color(0xFFEF4444);
  static const Color dangerLightColor = Color(0xFFFEF2F2);
  static const Color successColor = Color(0xFF10B981);

  // Light palette
  static const Color _primaryLight = Color(0xFF1A1F36);
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _backgroundLight = Color(0xFFF4F6FA);
  static const Color _textPrimaryLight = Color(0xFF1A1F36);
  static const Color _textSecondaryLight = Color(0xFF6B7280);
  static const Color _borderLight = Color(0xFFE5E7EB);
  static const Color _dividerLight = Color(0xFFF3F4F6);

  // Dark palette
  static const Color _primaryDark = Color(0xFF0B0D14);
  static const Color _surfaceDark = Color(0xFF1E2233);
  static const Color _backgroundDark = Color(0xFF14161F);
  static const Color _textPrimaryDark = Color(0xFFF1F2F6);
  static const Color _textSecondaryDark = Color(0xFF9CA3AF);
  static const Color _borderDark = Color(0xFF2E3346);
  static const Color _dividerDark = Color(0xFF262B3D);

  // Mode-aware getters — SAME call sites as before (AppTheme.xxxColor)
  static Color get primaryColor => _isDark ? _primaryDark : _primaryLight;
  static Color get surfaceColor => _isDark ? _surfaceDark : _surfaceLight;
  static Color get backgroundColour =>
      _isDark ? _backgroundDark : _backgroundLight;
  static Color get textPrimaryColor =>
      _isDark ? _textPrimaryDark : _textPrimaryLight;
  static Color get textSecondaryColor =>
      _isDark ? _textSecondaryDark : _textSecondaryLight;
  static Color get borderColor => _isDark ? _borderDark : _borderLight;
  static Color get dividerColor => _isDark ? _dividerDark : _dividerLight;

  // Spacing
  static const double spXS = 4;
  static const double spS = 8;
  static const double spM = 16;
  static const double spL = 24;
  static const double spXL = 32;
  static const double spXXL = 48;

  // Radien
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 24;

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: _primaryDark,
            onPrimary: Colors.white,
            secondary: accentColor,
            onSecondary: Colors.white,
            surface: _surfaceDark,
            onSurface: _textPrimaryDark,
            error: dangerColor,
            onError: Colors.white,
          )
        : const ColorScheme.light(
            primary: _primaryLight,
            onPrimary: Colors.white,
            secondary: accentColor,
            onSecondary: Colors.white,
            surface: _surfaceLight,
            onSurface: _textPrimaryLight,
            error: dangerColor,
            onError: Colors.white,
          );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? _backgroundDark : _backgroundLight,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? _primaryDark : _primaryLight,
        foregroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }
}
