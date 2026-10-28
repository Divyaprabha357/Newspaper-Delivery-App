import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_text_styles.dart';

class MobileRoleDesign {
  static ThemeData theme(BuildContext context) {
    final base = Theme.of(context);
    final text = GoogleFonts.libreBaskervilleTextTheme(base.textTheme).copyWith(
      headlineLarge: AppTextStyles.pageTitle,
      headlineMedium: AppTextStyles.cardTitleLarge,
      titleLarge: AppTextStyles.pageTitle,
      titleMedium: AppTextStyles.cardTitle,
      titleSmall: AppTextStyles.bodyBold,
      bodyLarge: AppTextStyles.bodyMedium,
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.caption,
      labelLarge: AppTextStyles.button,
      labelMedium: AppTextStyles.buttonSmall,
      labelSmall: AppTextStyles.metadata,
    );
    return base.copyWith(
      textTheme: text,
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        labelStyle: AppTextStyles.formHint,
        hintStyle: AppTextStyles.formHint,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 48),
          textStyle: AppTextStyles.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          textStyle: AppTextStyles.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          textStyle: AppTextStyles.button,
        ),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        labelTextStyle: WidgetStatePropertyAll(
          AppTextStyles.metadata.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
