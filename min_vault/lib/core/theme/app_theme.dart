import 'package:flutter/material.dart';

abstract final class AppTheme {
  // Interne Farbdefinitionen (nicht direkt von Screens verwenden)
  static const Color _primary = Color(0xFF1A1F36);
  static const Color _accent = Color(0xFF4361EE);
  static const Color _accentLight = Color(0xFFEEF2FF);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _dangerLight = Color(0xFFFEF2F2);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _background = Color(0xFFF4F6FA);
  static const Color _textPrimary = Color(0xFF1A1F36);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _divider = Color(0xFFF3F4F6);
  static const Color _success = Color(0xFF10B981);

  // Öffentliche Farbdefinitionen (für Screens verwenden)
  static const Color primaryColor = _primary;
  static const Color accentColor = _accent;
  static const Color accentLightColor = _accentLight;
  static const Color dangerColor = _danger;
  static const Color dangerLightColor = _dangerLight;
  static const Color surfaceColor = _surface;
  static const Color backgroundColour = _background;
  static const Color textPrimaryColor = _textPrimary;
  static const Color textSecondaryColor = _textSecondary;
  static const Color borderColor = _border;
  static const Color dividerColor = _divider;
  static const Color successColor = _success;

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

  // Standard Theme
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: _primary,
      onPrimary: Colors.white,
      secondary: _accent,
      onSecondary: Colors.white,
      surface: _surface,
      onSurface: _textPrimary,
      error: _danger,
      onError: Colors.white,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _background,
      fontFamily: 'Roboto',

      appBarTheme: const AppBarTheme(
        backgroundColor: _primary,
        foregroundColor: _surface,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: _surface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: _surface),
      ),
    );
  }

  // Dark Theme könnte in Zukunft erweitert werden, hier aber erstmal identisch zum Light Theme
  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: _primary,
      onPrimary: Colors.white,
      secondary: _accent,
      onSecondary: Colors.white,
      surface: _surface,
      onSurface: _textPrimary,
      error: _danger,
      onError: Colors.white,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _background,
      fontFamily: 'Roboto',

      appBarTheme: const AppBarTheme(
        backgroundColor: _primary,
        foregroundColor: _surface,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: _surface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: _surface),
      ),
    );
  }
}
