import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FilbyColors {
  // Vibrant Amber + Deep Navy — Filby Coffee
  static const bg = Color(0xFF0C1018);
  static const bgDeep = Color(0xFF080C12);
  static const surface = Color(0xFF141C2A);
  static const surface2 = Color(0xFF1C2840);
  static const surface3 = Color(0xFF243556);
  static const primary = Color(0xFFFF9500);       // Vivid amber-orange
  static const primarySoft = Color(0xFFFFB340);
  static const primaryDeep = Color(0xFFCC7700);
  static const navy = Color(0xFF1C2E50);
  static const navySoft = Color(0xFF263F6E);
  static const cream = Color(0xFFFFF8EE);
  static const creamWarm = Color(0xFFFFF0D8);
  static const textPrimary = Color(0xFFFFF8F0);
  static const textSecondary = Color(0xCCFFF8F0);
  static const textMuted = Color(0x77FFF8F0);
  static const success = Color(0xFF00E676);
  static const successBg = Color(0x2200E676);
  static const warningBg = Color(0x22FF9500);
  static const border = Color(0x22FF9500);
  static const borderStrong = Color(0x44FF9500);
}

// Use these style helpers everywhere instead of fontFamily strings
class FilbyText {
  static TextStyle display({double size = 28, Color color = FilbyColors.textPrimary}) =>
      GoogleFonts.notoSerifLao(fontSize: size, fontWeight: FontWeight.w700, color: color);

  static TextStyle heading({double size = 22, Color color = FilbyColors.textPrimary}) =>
      GoogleFonts.notoSerifLao(fontSize: size, fontWeight: FontWeight.w700, color: color);

  static TextStyle body({double size = 14, Color color = FilbyColors.textPrimary, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.notoSansLao(fontSize: size, fontWeight: weight, color: color);

  static TextStyle mono({double size = 14, Color color = FilbyColors.textPrimary, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);
}

ThemeData filbyTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: FilbyColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: FilbyColors.primary,
      secondary: FilbyColors.primarySoft,
      surface: FilbyColors.surface,
      onPrimary: Colors.white,
      onSurface: FilbyColors.textPrimary,
    ),
    textTheme: GoogleFonts.notoSansLaoTextTheme(
      const TextTheme(
        displayLarge: TextStyle(color: FilbyColors.textPrimary),
        headlineLarge: TextStyle(color: FilbyColors.textPrimary),
        bodyLarge: TextStyle(color: FilbyColors.textPrimary),
        bodyMedium: TextStyle(color: FilbyColors.textSecondary),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: FilbyColors.bg,
      elevation: 0,
      titleTextStyle: GoogleFonts.notoSerifLao(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: FilbyColors.textPrimary,
      ),
      iconTheme: const IconThemeData(color: FilbyColors.textPrimary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xEB070B14),
      selectedItemColor: FilbyColors.primary,
      unselectedItemColor: FilbyColors.textMuted,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 10),
    ),
  );
}
