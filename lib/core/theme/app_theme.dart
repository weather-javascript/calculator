// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceCard = Color(0xFF1A2235);
  static const Color surfaceRaised = Color(0xFF1E2D45);

  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentRed = Color(0xFFEF4444);

  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF475569);

  static const Color borderColor = Color(0xFF1E3A5F);
  static const Color divider = Color(0xFF1E293B);

  static const Color btnNumber = Color(0xFF1A2235);
  static const Color btnOperator = Color(0xFF1E3A5F);
  static const Color btnFunction = Color(0xFF1A2E4A);
  static const Color btnAction = Color(0xFF3B82F6);
  static const Color btnClear = Color(0xFF7F1D1D);
  static const Color btnSpecial = Color(0xFF4C1D95);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: accentCyan,
        secondary: accentBlue,
        tertiary: accentPurple,
        error: accentRed,
        onSurface: textPrimary,
        onPrimary: background,
      ),
      textTheme: GoogleFonts.ibmPlexMonoTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.ibmPlexMono(
            fontSize: 48,
            fontWeight: FontWeight.w300,
            color: textPrimary,
            letterSpacing: -2),
        headlineLarge: GoogleFonts.spaceGrotesk(
            fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: GoogleFonts.ibmPlexMono(fontSize: 16, color: textSecondary),
        labelLarge: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: 0.5),
      ),
      dividerColor: divider,
      cardColor: surfaceCard,
    );
  }
}
