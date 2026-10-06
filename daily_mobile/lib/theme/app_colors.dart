import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ============================================================
  // DAILY PRIMARY COLORS
  // ============================================================

  static const Color warmCream = Color(0xFFEAE0D0);
  static const Color nearBlack = Color(0xFF1E1D1C);
  static const Color burgundy = Color(0xFF652B21);

  // ============================================================
  // DAILY SECONDARY COLORS
  // ============================================================

  static const Color darkCharcoal = Color(0xFF302F2D);
  static const Color mutedBeige = Color(0xFFC8BBA8);
  static const Color offWhite = Color(0xFFF4EEE4);
  static const Color warmGray = Color(0xFF817B73);

  // ============================================================
  // ADDITIONAL UI COLORS
  // Derived only from the DAILY palette.
  // ============================================================

  static const Color border = Color(0xFFD5C8B7);

  static const Color divider = Color(0xFFC8BBA8);

  static const Color disabled = Color(0xFFB5AA9B);

  static const Color overlay = Color(0x661E1D1C);

  static const Color transparent = Colors.transparent;

  // ============================================================
  // STATUS COLORS
  // Kept muted so they do not introduce bright colors.
  // ============================================================

  static const Color success = Color(0xFF536B4F);
  static const Color warning = Color(0xFF8A6A3D);
  static const Color error = Color(0xFF7A3E35);
  static const Color info = Color(0xFF5C625F);

  // ============================================================
  // TEXT COLORS
  // ============================================================

  static const Color primaryText = nearBlack;
  static const Color secondaryText = darkCharcoal;
  static const Color mutedText = warmGray;
  static const Color inverseText = offWhite;

  // ============================================================
  // SURFACE COLORS
  // ============================================================

  static const Color pageBackground = warmCream;
  static const Color cardBackground = offWhite;
  static const Color darkSurface = nearBlack;
}
