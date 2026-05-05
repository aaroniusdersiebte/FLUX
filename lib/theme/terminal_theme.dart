import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color textPrimary;
  final Color amber;
  final Color amberDim;
  final Color surface;
  final Color border;
  final Color textMuted;
  final String fontFamily;
  final bool isDark;

  const AppColors({
    required this.background,
    required this.textPrimary,
    required this.amber,
    required this.amberDim,
    required this.surface,
    required this.border,
    required this.textMuted,
    this.fontFamily = 'jetbrains_mono',
    this.isDark = true,
  });

  static const dark = AppColors(
    background: Color(0xFF000000),
    textPrimary: Color(0xFFFFFFFF),
    amber: Color(0xFFFFBF00),
    amberDim: Color(0x4DFFBF00),
    surface: Color(0xFF0A0A0A),
    border: Color(0xFF1A1A1A),
    textMuted: Color(0xFF555555),
    isDark: true,
  );

  static const light = AppColors(
    background: Color(0xFFF2F2F2),
    textPrimary: Color(0xFF0D0D0D),
    amber: Color(0xFFFFBF00),
    amberDim: Color(0x4DFFBF00),
    surface: Color(0xFFE5E5E5),
    border: Color(0xFFC0C0C0),
    textMuted: Color(0xFF777777),
    isDark: false,
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? textPrimary,
    Color? amber,
    Color? amberDim,
    Color? surface,
    Color? border,
    Color? textMuted,
    String? fontFamily,
    bool? isDark,
  }) {
    return AppColors(
      background: background ?? this.background,
      textPrimary: textPrimary ?? this.textPrimary,
      amber: amber ?? this.amber,
      amberDim: amberDim ?? this.amberDim,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      textMuted: textMuted ?? this.textMuted,
      fontFamily: fontFamily ?? this.fontFamily,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      amberDim: Color.lerp(amberDim, other.amberDim, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      fontFamily: t < 1.0 ? fontFamily : other.fontFamily,
      isDark: t < 1.0 ? isDark : other.isDark,
    );
  }
}

// Keep TerminalColors as static aliases to AppColors.dark for any
// remaining const contexts (e.g. library_screen boot animation).
class TerminalColors {
  static const Color background = Color(0xFF000000);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color amber = Color(0xFFFFBF00);
  static const Color amberDim = Color(0x4DFFBF00);
  static const Color surface = Color(0xFF0A0A0A);
  static const Color border = Color(0xFF1A1A1A);
  static const Color textMuted = Color(0xFF555555);
}

class AppFont {
  static TextStyle get(
    String key, {
    required Color color,
    required double fontSize,
    FontWeight? weight,
    double? height,
    double? letterSpacing,
  }) {
    switch (key) {
      case 'roboto_mono':
        return GoogleFonts.robotoMono(
            color: color,
            fontSize: fontSize,
            fontWeight: weight,
            height: height,
            letterSpacing: letterSpacing);
      case 'source_code_pro':
        return GoogleFonts.sourceCodePro(
            color: color,
            fontSize: fontSize,
            fontWeight: weight,
            height: height,
            letterSpacing: letterSpacing);
      case 'space_mono':
        return GoogleFonts.spaceMono(
            color: color,
            fontSize: fontSize,
            fontWeight: weight,
            height: height,
            letterSpacing: letterSpacing);
      case 'fira_code':
        return GoogleFonts.firaCode(
            color: color,
            fontSize: fontSize,
            fontWeight: weight,
            height: height,
            letterSpacing: letterSpacing);
      case 'ibm_plex_mono':
        return GoogleFonts.ibmPlexMono(
            color: color,
            fontSize: fontSize,
            fontWeight: weight,
            height: height,
            letterSpacing: letterSpacing);
      case 'inconsolata':
        return GoogleFonts.inconsolata(
            color: color,
            fontSize: fontSize,
            fontWeight: weight,
            height: height,
            letterSpacing: letterSpacing);
      case 'anonymous_pro':
        return GoogleFonts.anonymousPro(
            color: color,
            fontSize: fontSize,
            fontWeight: weight,
            height: height,
            letterSpacing: letterSpacing);
      case 'share_tech_mono':
        return GoogleFonts.shareTechMono(
            color: color,
            fontSize: fontSize,
            fontWeight: weight,
            height: height,
            letterSpacing: letterSpacing);
      case 'overpass_mono':
        return GoogleFonts.overpassMono(
            color: color,
            fontSize: fontSize,
            fontWeight: weight,
            height: height,
            letterSpacing: letterSpacing);
      default: // jetbrains_mono
        return GoogleFonts.jetBrainsMono(
            color: color,
            fontSize: fontSize,
            fontWeight: weight,
            height: height,
            letterSpacing: letterSpacing);
    }
  }
}

class TerminalTheme {
  static ThemeData build(AppColors colors) {
    final f = colors.fontFamily;

    final textTheme = TextTheme(
      displayLarge: AppFont.get(f,
          color: colors.textPrimary, fontSize: 32, weight: FontWeight.w700),
      displayMedium: AppFont.get(f,
          color: colors.textPrimary, fontSize: 24, weight: FontWeight.w600),
      bodyLarge: AppFont.get(f,
          color: colors.textPrimary, fontSize: 16, height: 1.6),
      bodyMedium: AppFont.get(f,
          color: colors.textPrimary, fontSize: 14, height: 1.5),
      bodySmall:
          AppFont.get(f, color: colors.textMuted, fontSize: 12),
      labelLarge: AppFont.get(f,
          color: colors.amber,
          fontSize: 12,
          letterSpacing: 2.0,
          weight: FontWeight.w600),
    );

    return ThemeData(
      brightness: colors.isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: colors.background,
      extensions: [colors],
      colorScheme: ColorScheme(
        brightness: colors.isDark ? Brightness.dark : Brightness.light,
        surface: colors.background,
        primary: colors.amber,
        onPrimary: colors.background,
        secondary: colors.textPrimary,
        onSecondary: colors.background,
        onSurface: colors.textPrimary,
        error: Colors.red,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        titleTextStyle: AppFont.get(f,
            color: colors.amber,
            fontSize: 14,
            weight: FontWeight.w700,
            letterSpacing: 3.0),
        iconTheme: IconThemeData(color: colors.amber),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.amber,
        foregroundColor: colors.background,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.amber,
        inactiveTrackColor: colors.border,
        thumbColor: colors.amber,
        overlayColor: colors.amberDim,
        valueIndicatorColor: colors.amber,
        valueIndicatorTextStyle: AppFont.get(f,
            color: colors.background,
            fontSize: 12,
            weight: FontWeight.w700),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.amber
              : colors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.amberDim
              : colors.border,
        ),
      ),
      dividerColor: colors.border,
      cardColor: colors.surface,
    );
  }
}
