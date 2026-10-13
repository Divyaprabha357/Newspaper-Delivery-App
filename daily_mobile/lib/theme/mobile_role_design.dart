import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart';

class MobileRoleDesign {
  static ThemeData theme(BuildContext context) {
    final base = Theme.of(context);
    final text = GoogleFonts.libreBaskervilleTextTheme(base.textTheme).copyWith(
      bodyLarge: const TextStyle(fontSize: 16, height: 1.4, color: DailyColors.charcoal),
      bodyMedium: const TextStyle(fontSize: 16, height: 1.35, color: DailyColors.charcoal),
      labelLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DailyColors.charcoal),
      titleMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DailyColors.charcoal),
      titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: DailyColors.charcoal),
    );
    return base.copyWith(
      textTheme: text,
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        labelStyle: const TextStyle(fontSize: 14, color: DailyColors.gray),
        hintStyle: const TextStyle(fontSize: 14, color: DailyColors.gray),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 48),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
