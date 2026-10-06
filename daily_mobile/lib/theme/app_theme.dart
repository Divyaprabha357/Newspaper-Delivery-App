import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DailyColors {
  static const cream = Color(0xFFF5ECE0);
  static const charcoal = Color(0xFF2B2A28);
  static const burgundy = Color(0xFF7A1F1F);
  static const olive = Color(0xFF6B7A4F);
  static const oliveDark = Color(0xFF4B5A2F);
  static const tan = Color(0xFFE6D6C8);
  static const divider = Color(0xFFC1B6A8);
  static const gray = Color(0xFF8A8A8A);
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFC96A2A);
  static const white = Color(0xFFFCF9F4);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: DailyColors.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: DailyColors.burgundy,
        surface: DailyColors.cream,
      ),
      textTheme: GoogleFonts.libreBaskervilleTextTheme(
        const TextTheme(
          bodyLarge: TextStyle(color: DailyColors.charcoal),
          bodyMedium: TextStyle(color: DailyColors.charcoal),
          titleLarge: TextStyle(color: DailyColors.charcoal),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: DailyColors.white,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: DailyColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: DailyColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: DailyColors.burgundy, width: 1.4),
        ),
      ),
    );
  }
}
