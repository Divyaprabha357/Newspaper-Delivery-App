import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_theme.dart';

/// Centralized typography system for the DAILY mobile application.
/// Standardized against the Customer experience and applied to Delivery Partner.
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Libre Baskerville';

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

  // ============================================================
  // LOGO
  // ============================================================

  static TextStyle logo({
    double fontSize = 42,
    Color color = DailyColors.charcoal,
  }) => _style(
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    color: color,
    height: 1,
  );

  // ============================================================
  // PAGE TITLES & HEADERS
  // ============================================================

  /// Primary screen / page title (24px bold)
  static TextStyle pageTitle = _style(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: DailyColors.charcoal,
    height: 1.25,
  );

  /// Page title inverted for dark containers
  static TextStyle pageTitleLight = _style(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    height: 1.25,
  );

  /// Subtitle beneath page title (14px regular)
  static TextStyle pageSubtitle = _style(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: DailyColors.gray,
    height: 1.45,
  );

  /// Compact subtitle beneath page title (12px regular)
  static TextStyle pageSubtitleSmall = _style(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: DailyColors.gray,
    height: 1.4,
  );

  /// Top app bar / header title (14px bold, uppercase, tracked)
  static TextStyle headerTitle = _style(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: DailyColors.charcoal,
  );

  /// Header / screen overline tag (11px bold, uppercase, tracked, burgundy)
  static TextStyle headerOverline = _style(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.4,
    color: DailyColors.burgundy,
  );

  // ============================================================
  // SECTION HEADINGS & OVERLINES
  // ============================================================

  /// Standard section overline label (11px bold, uppercase, letterSpacing 1.4)
  static TextStyle sectionHeader = _style(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.4,
    color: DailyColors.gray,
  );

  /// Accent section overline label in burgundy (11px bold, uppercase, letterSpacing 1.4)
  static TextStyle sectionHeaderAccent = _style(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.4,
    color: DailyColors.burgundy,
  );

  /// Dark section overline label in tan for dark card backgrounds
  static TextStyle sectionHeaderDark = _style(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.4,
    color: DailyColors.tan,
  );

  // ============================================================
  // CARD & LIST HEADINGS
  // ============================================================

  /// Card / list item title (16px bold)
  static TextStyle cardTitle = _style(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: DailyColors.charcoal,
    height: 1.3,
  );

  /// Prominent card / modal title (18-20px bold)
  static TextStyle cardTitleLarge = _style(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: DailyColors.charcoal,
    height: 1.25,
  );

  /// Card title inverted for dark cards
  static TextStyle cardTitleDark = _style(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    height: 1.25,
  );

  /// Card secondary description / details (13-14px)
  static TextStyle cardSubtitle = _style(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: DailyColors.gray,
    height: 1.4,
  );

  // ============================================================
  // BODY TEXT
  // ============================================================

  /// Standard body copy (14px regular)
  static TextStyle body = _style(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: DailyColors.charcoal,
    height: 1.45,
  );

  /// Medium body copy (15px regular)
  static TextStyle bodyMedium = _style(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: DailyColors.charcoal,
    height: 1.45,
  );

  /// Bold body copy (14px bold)
  static TextStyle bodyBold = _style(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: DailyColors.charcoal,
    height: 1.4,
  );

  /// Small body copy (13px regular)
  static TextStyle bodySmall = _style(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: DailyColors.charcoal,
    height: 1.4,
  );

  // ============================================================
  // SECONDARY TEXT & METADATA
  // ============================================================

  /// Captions and helper text (12px regular)
  static TextStyle caption = _style(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: DailyColors.gray,
    height: 1.35,
  );

  /// Micro-metadata and timestamps (11px tracked)
  static TextStyle metadata = _style(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.3,
    color: DailyColors.gray,
  );

  /// Status tags / indicators (12px bold)
  static TextStyle status = _style(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
    color: DailyColors.charcoal,
  );

  // ============================================================
  // BUTTON LABELS
  // ============================================================

  /// Standard button label (14px bold, uppercase, tracked)
  static TextStyle button = _style(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.8,
    color: Colors.white,
  );

  /// Compact primary button label (11px bold, uppercase, tracked)
  static TextStyle buttonSmall = _style(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.7,
    color: Colors.white,
  );

  // ============================================================
  // FORM & INPUT STYLES
  // ============================================================

  /// Form field label (12px bold, uppercase, tracked)
  static TextStyle formLabel = _style(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.1,
    color: DailyColors.gray,
  );

  /// Form input text (14px regular)
  static TextStyle formInput = _style(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: DailyColors.charcoal,
  );

  /// Form placeholder / hint text (14px regular)
  static TextStyle formHint = _style(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: DailyColors.gray,
  );

  // ============================================================
  // METRICS & STATS
  // ============================================================

  /// Dashboard metric numerical value (24px bold)
  static TextStyle metricValue = _style(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: DailyColors.charcoal,
  );

  /// Prominent billing / amount value (32px bold)
  static TextStyle metricValueLarge = _style(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: DailyColors.charcoal,
  );

  /// Metric upper label (12px tracked)
  static TextStyle metricLabel = _style(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 1.2,
    color: DailyColors.gray,
  );

  // ============================================================
  // BACKWARD-COMPATIBLE ALIASES
  // ============================================================

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
}
