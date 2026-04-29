import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TerminalColors {
  static const Color background = Color(0xFF000000);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color amber = Color(0xFFFFBF00);
  static const Color amberDim = Color(0x4DFFBF00);
  static const Color surface = Color(0xFF0A0A0A);
  static const Color border = Color(0xFF1A1A1A);
  static const Color textMuted = Color(0xFF555555);
}

class TerminalTheme {
  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.jetBrainsMono(
        color: TerminalColors.textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: GoogleFonts.jetBrainsMono(
        color: TerminalColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.jetBrainsMono(
        color: TerminalColors.textPrimary,
        fontSize: 16,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.jetBrainsMono(
        color: TerminalColors.textPrimary,
        fontSize: 14,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.jetBrainsMono(
        color: TerminalColors.textMuted,
        fontSize: 12,
      ),
      labelLarge: GoogleFonts.jetBrainsMono(
        color: TerminalColors.amber,
        fontSize: 12,
        letterSpacing: 2.0,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static ThemeData build() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: TerminalColors.background,
      colorScheme: const ColorScheme.dark(
        surface: TerminalColors.background,
        primary: TerminalColors.amber,
        onPrimary: TerminalColors.background,
        secondary: TerminalColors.textPrimary,
        onSecondary: TerminalColors.background,
        onSurface: TerminalColors.textPrimary,
      ),
      textTheme: _buildTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: TerminalColors.background,
        elevation: 0,
        titleTextStyle: GoogleFonts.jetBrainsMono(
          color: TerminalColors.amber,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 3.0,
        ),
        iconTheme: const IconThemeData(color: TerminalColors.amber),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: TerminalColors.amber,
        foregroundColor: TerminalColors.background,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: TerminalColors.amber,
        inactiveTrackColor: TerminalColors.border,
        thumbColor: TerminalColors.amber,
        overlayColor: TerminalColors.amberDim,
        valueIndicatorColor: TerminalColors.amber,
        valueIndicatorTextStyle: GoogleFonts.jetBrainsMono(
          color: TerminalColors.background,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? TerminalColors.amber
              : TerminalColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? TerminalColors.amberDim
              : TerminalColors.border,
        ),
      ),
      dividerColor: TerminalColors.border,
      cardColor: TerminalColors.surface,
    );
  }
}
