import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

const supplierMissingValue = '\u2014';

String supplierCurrency(Object? value) {
  if (value == null) return supplierMissingValue;
  final raw = value.toString().trim();
  if (raw.isEmpty || raw == supplierMissingValue) return supplierMissingValue;
  final numeric = double.tryParse(
    raw.replaceAll(RegExp(r'[^0-9.\-]'), ''),
  );
  if (numeric == null) return supplierMissingValue;
  return '\u20B9${numeric.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+\.)'),
        (match) => '${match.group(1)},',
      )}';
}

class SupplierDesign {
  static ThemeData theme(BuildContext context) {
    final base = Theme.of(context);
    final text = GoogleFonts.libreBaskervilleTextTheme(base.textTheme).copyWith(
      bodyLarge: const TextStyle(fontSize: 18, height: 1.4, color: DailyColors.charcoal),
      bodyMedium: const TextStyle(fontSize: 18, height: 1.35, color: DailyColors.charcoal),
      labelLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DailyColors.charcoal),
      titleMedium: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: DailyColors.charcoal),
      titleLarge: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: DailyColors.charcoal),
    );
    return base.copyWith(
      textTheme: text,
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        labelStyle: const TextStyle(fontSize: 16, color: DailyColors.gray),
        hintStyle: const TextStyle(fontSize: 16, color: DailyColors.gray),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          backgroundColor: DailyColors.burgundy,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          foregroundColor: DailyColors.charcoal,
          side: const BorderSide(color: DailyColors.divider),
          shape: const RoundedRectangleBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          foregroundColor: DailyColors.burgundy,
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        titleTextStyle: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: DailyColors.charcoal),
        contentTextStyle: const TextStyle(fontSize: 18, height: 1.4, color: DailyColors.charcoal),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        minVerticalPadding: 12,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        titleTextStyle: const TextStyle(fontSize: 18, color: DailyColors.charcoal),
      ),
    );
  }
}


