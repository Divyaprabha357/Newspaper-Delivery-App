import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _style({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.libreBaskerville(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle logo({
    double fontSize = 42,
    Color color = AppColors.nearBlack,
  }) => _style(
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    color: color,
    height: 1,
  );

  static TextStyle displayLarge = _style(
    fontSize: 42,
    fontWeight: FontWeight.w600,
    color: AppColors.nearBlack,
    height: 1.1,
  );
  static TextStyle displayMedium = _style(
    fontSize: 34,
    fontWeight: FontWeight.w600,
    color: AppColors.nearBlack,
    height: 1.15,
  );
  static TextStyle displaySmall = _style(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.nearBlack,
    height: 1.2,
  );
  static TextStyle headingLarge = _style(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.nearBlack,
    height: 1.2,
  );
  static TextStyle headingMedium = _style(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.nearBlack,
    height: 1.25,
  );
  static TextStyle headingSmall = _style(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.nearBlack,
    height: 1.3,
  );

  static TextStyle bodyLarge = _style(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.darkCharcoal,
    height: 1.45,
  );
  static TextStyle bodyMedium = _style(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: AppColors.darkCharcoal,
    height: 1.45,
  );
  static TextStyle bodySmall = _style(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.warmGray,
    height: 1.4,
  );

  static TextStyle uiLarge = _style(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.nearBlack,
  );
  static TextStyle uiMedium = _style(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.nearBlack,
  );
  static TextStyle uiSmall = _style(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.warmGray,
  );
  static TextStyle buttonLarge = _style(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.offWhite,
  );
  static TextStyle buttonMedium = _style(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.offWhite,
  );
  static TextStyle metadata = _style(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: .3,
    color: AppColors.warmGray,
  );
  static TextStyle status = _style(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.nearBlack,
  );
}
