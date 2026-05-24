import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FilbyColors {
  static const bg = Color(0xFF0E0703);
  static const bgDeep = Color(0xFF08040A);
  static const surface = Color(0xFF1A0F0A);
  static const surface2 = Color(0xFF251812);
  static const surface3 = Color(0xFF2F1F17);
  static const primary = Color(0xFFE8854A);
  static const primarySoft = Color(0xFFF5A574);
  static const primaryDeep = Color(0xFFC26835);
  static const cream = Color(0xFFF5E6D3);
  static const creamWarm = Color(0xFFEFD9BF);
  static const textPrimary = Color(0xFFFFFAF3);
  static const textSecondary = Color(0xAAFFFAF3);
  static const textMuted = Color(0x66FFFAF3);
  static const success = Color(0xFF6EE7A7);
  static const successBg = Color(0x1F6EE7A7);
  static const warningBg = Color(0x1AE8854A);
  static const border = Color(0x12FFE6C8);
  static const borderStrong = Color(0x24FFE6C8);
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
      backgroundColor: Color(0xEB0E0703),
      selectedItemColor: FilbyColors.primary,
      unselectedItemColor: FilbyColors.textMuted,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 10),
    ),
  );
}
