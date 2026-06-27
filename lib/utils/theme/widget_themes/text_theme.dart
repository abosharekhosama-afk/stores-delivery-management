import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';

/// Custom Class for Light & Dark Text Themes
class TTextTheme {
  TTextTheme._(); // To avoid creating instances

  /// Customizable Light Text Theme
  static TextTheme lightTextTheme = TextTheme(
    headlineLarge: GoogleFonts.tajawal().copyWith(
      fontSize: 24.0,
      fontWeight: FontWeight.bold,
      color: TColors.textPrimary,
    ),
    headlineMedium: GoogleFonts.tajawal().copyWith(
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
      color: TColors.textPrimary,
    ),
    headlineSmall: GoogleFonts.tajawal().copyWith(
      fontSize: 16.0,
      fontWeight: FontWeight.bold,
      color: TColors.textPrimary,
    ),

    titleLarge: GoogleFonts.tajawal().copyWith(
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
      color: TColors.textPrimary,
    ),
    titleMedium: GoogleFonts.tajawal().copyWith(
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
      color: TColors.textSecondary,
    ),
    titleSmall: GoogleFonts.tajawal().copyWith(
      fontSize: 16.0,
      fontWeight: FontWeight.w400,
      color: TColors.textSecondary,
    ),

    bodyLarge: GoogleFonts.tajawal().copyWith(
      fontSize: 14.0,
      fontWeight: FontWeight.w600,
      color: TColors.textPrimary,
    ),
    bodyMedium: GoogleFonts.tajawal().copyWith(
      fontSize: 14.0,
      fontWeight: FontWeight.normal,
      color: TColors.textPrimary,
    ),
    bodySmall: GoogleFonts.tajawal().copyWith(
      fontSize: 14.0,
      fontWeight: FontWeight.normal,
      color: TColors.textSecondary,
    ),

    labelLarge: GoogleFonts.tajawal().copyWith(
      fontSize: 12.0,
      fontWeight: FontWeight.normal,
      color: TColors.textPrimary,
    ),
    labelMedium: GoogleFonts.tajawal().copyWith(
      fontSize: 12.0,
      fontWeight: FontWeight.normal,
      color: TColors.textSecondary,
    ),
  );

  /// Customizable Dark Text Theme
  static TextTheme darkTextTheme = TextTheme(
    headlineLarge: GoogleFonts.tajawal().copyWith(
      fontSize: 24.0,
      fontWeight: FontWeight.bold,
      color: TColors.light,
    ),
    headlineMedium: GoogleFonts.tajawal().copyWith(
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
      color: TColors.light,
    ),
    headlineSmall: GoogleFonts.tajawal().copyWith(
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
      color: TColors.light,
    ),

    titleLarge: GoogleFonts.tajawal().copyWith(
      fontSize: 16.0,
      fontWeight: FontWeight.bold,
      color: TColors.light,
    ),
    titleMedium: GoogleFonts.tajawal().copyWith(
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
      color: TColors.light,
    ),
    titleSmall: GoogleFonts.tajawal().copyWith(
      fontSize: 16.0,
      fontWeight: FontWeight.w400,
      color: TColors.light,
    ),

    bodyLarge: GoogleFonts.tajawal().copyWith(
      fontSize: 14.0,
      fontWeight: FontWeight.w600,
      color: TColors.light,
    ),
    bodyMedium: GoogleFonts.tajawal().copyWith(
      fontSize: 14.0,
      fontWeight: FontWeight.normal,
      color: TColors.light,
    ),
    bodySmall: GoogleFonts.tajawal().copyWith(
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
      color: TColors.light.withAlpha((0.5 * 255).round()),
    ),

    labelLarge: GoogleFonts.tajawal().copyWith(
      fontSize: 12.0,
      fontWeight: FontWeight.normal,
      color: TColors.light,
    ),
    labelMedium: GoogleFonts.tajawal().copyWith(
      fontSize: 12.0,
      fontWeight: FontWeight.normal,
      color: TColors.light.withAlpha((0.5 * 255).round()),
    ),
  );
}


