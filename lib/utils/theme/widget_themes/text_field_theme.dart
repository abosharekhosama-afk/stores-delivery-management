import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../../constants/sizes.dart';

class TTextFormFieldTheme {
  TTextFormFieldTheme._();

  static InputDecorationTheme lightInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 3,
    prefixIconColor: TColors.primary, // تغيير للون الهوية ليعطي لمسة جمالية
    suffixIconColor: TColors.darkGrey,
    filled: true,
    fillColor: TColors.light.withAlpha((0.5 * 255).round()), // خلفية خفيفة جداً
    contentPadding: const EdgeInsets.symmetric(
      vertical: 16,
      horizontal: 20,
    ), // حشو داخلي مريح

    labelStyle: GoogleFonts.tajawal(
      fontSize: TSizes.fontSizeMd,
      color: TColors.textPrimary,
    ),
    hintStyle: GoogleFonts.tajawal(
      fontSize: TSizes.fontSizeSm,
      color: TColors.textSecondary.withAlpha((0.6 * 255).round()),
    ),
    errorStyle: GoogleFonts.tajawal(
      fontStyle: FontStyle.normal,
      color: TColors.error,
    ),
    floatingLabelStyle: GoogleFonts.tajawal(
      color: TColors.primary,
      fontWeight: FontWeight.w600,
    ),

    // الإطار العادي (غير محدد)
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14), // حواف أكثر نعومة
      borderSide: const BorderSide(width: 1, color: TColors.borderLight),
    ),

    // الإطار عند الضغط والكتابة (Focus)
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1.5, color: TColors.primary),
    ),

    // إطار الخطأ
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: TColors.error),
    ),

    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 2, color: TColors.error),
    ),
  );

  static InputDecorationTheme darkInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 2,
    prefixIconColor: TColors.primary,
    suffixIconColor: TColors.darkGrey,
    filled: true,
    fillColor: TColors.darkerGrey.withAlpha((0.3 * 255).round()),
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),

    labelStyle: GoogleFonts.tajawal(
      fontSize: TSizes.fontSizeMd,
      color: TColors.white,
    ),
    hintStyle: GoogleFonts.tajawal(
      fontSize: TSizes.fontSizeSm,
      color: TColors.white.withAlpha((0.5 * 255).round()),
    ),
    floatingLabelStyle: GoogleFonts.tajawal(
      color: TColors.primary,
      fontWeight: FontWeight.w600,
    ),

    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: TColors.darkGrey),
    ),

    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1.5, color: TColors.primary),
    ),

    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: TColors.error),
    ),

    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 2, color: TColors.error),
    ),
  );
}















/*
class TTextFormFieldTheme {
  TTextFormFieldTheme._();

  static InputDecorationTheme lightInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 3,
    prefixIconColor: TColors.darkGrey,
    suffixIconColor: TColors.darkGrey,
    // constraints: const BoxConstraints.expand(height: TSizes.inputFieldHeight),
    labelStyle: const TextStyle().copyWith(
      fontSize: TSizes.fontSizeMd,
      color: TColors.textPrimary,
      fontFamily: GoogleFonts.tajawal().fontFamily,
    ),
    hintStyle: const TextStyle().copyWith(
      fontSize: TSizes.fontSizeSm,
      color: TColors.textSecondary,
      fontFamily: GoogleFonts.tajawal().fontFamily,
    ),
    errorStyle: const TextStyle().copyWith(fontStyle: FontStyle.normal),
    floatingLabelStyle: const TextStyle().copyWith(
      color: TColors.textSecondary,
      fontFamily: GoogleFonts.tajawal().fontFamily,
    ),
    border: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1, color: TColors.borderPrimary),
    ),
    enabledBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1, color: TColors.borderPrimary),
    ),
    focusedBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1, color: TColors.darkerGrey),
    ),
    errorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1, color: TColors.error),
    ),
    focusedErrorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
      borderSide: const BorderSide(width: 2, color: TColors.error),
    ),
  );

  static InputDecorationTheme darkInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 2,
    prefixIconColor: TColors.darkGrey,
    suffixIconColor: TColors.darkGrey,
    // constraints: const BoxConstraints.expand(height: TSizes.inputFieldHeight),
    labelStyle: const TextStyle().copyWith(
      fontSize: TSizes.fontSizeMd,
      color: TColors.white,
      fontFamily: GoogleFonts.tajawal().fontFamily,
    ),
    hintStyle: const TextStyle().copyWith(
      fontSize: TSizes.fontSizeSm,
      color: TColors.white,
      fontFamily: GoogleFonts.tajawal().fontFamily,
    ),
    floatingLabelStyle: const TextStyle().copyWith(
      color: TColors.white.withAlpha((0.8 * 255).round()),
      fontFamily: GoogleFonts.tajawal().fontFamily,
    ),
    border: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1, color: TColors.darkGrey),
    ),
    enabledBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1, color: TColors.darkGrey),
    ),
    focusedBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1, color: TColors.white),
    ),
    errorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1, color: TColors.error),
    ),
    focusedErrorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
      borderSide: const BorderSide(width: 2, color: TColors.error),
    ),
  );
}
*/

