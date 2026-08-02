import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FilbyColors {
  // Filby Coffee — deep navy + gold on light (from company logo)
  static const bg = Color(0xFFF2F4F7);            // app background (light)
  static const bgDeep = Color(0xFFE7EAEF);
  static const surface = Color(0xFFFFFFFF);        // cards
  static const surface2 = Color(0xFFEEF1F5);
  static const surface3 = Color(0xFFE2E6EC);
  static const primary = Color(0xFF24457E);        // navy-blue accent (white text OK)
  static const primarySoft = Color(0xFF3560A0);
  static const primaryDeep = Color(0xFF17233F);    // logo navy
  static const navy = Color(0xFF17233F);
  static const navySoft = Color(0xFF2A4272);
  static const gold = Color(0xFFC9A24B);           // logo gold (highlight)
  static const goldSoft = Color(0xFFE6C877);
  // "cream" now doubles as the active-pill / hero color = navy (light text sits on it)
  static const cream = Color(0xFF17233F);
  static const creamWarm = Color(0xFF2A4272);
  static const textPrimary = Color(0xFF17233F);    // dark navy text
  static const textSecondary = Color(0xFF5A6474);
  static const textMuted = Color(0xFF99A0AD);
  static const success = Color(0xFF14B36A);
  static const successBg = Color(0x1A14B36A);
  static const warningBg = Color(0x1AC9A24B);
  static const border = Color(0x14172333);
  static const borderStrong = Color(0x33172333);
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
    brightness: Brightness.light,
    scaffoldBackgroundColor: FilbyColors.bg,
    colorScheme: const ColorScheme.light(
      primary: FilbyColors.primary,
      secondary: FilbyColors.gold,
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
      backgroundColor: Colors.white,
      selectedItemColor: FilbyColors.primary,
      unselectedItemColor: FilbyColors.textMuted,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 10),
    ),
  );
}
