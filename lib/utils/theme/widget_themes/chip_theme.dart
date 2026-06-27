import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'package:google_fonts/google_fonts.dart'; // لضمان تناسق الخطوط

class TChipTheme {
  TChipTheme._();

  static ChipThemeData lightChipTheme = ChipThemeData(
    disabledColor: TColors.grey.withAlpha((0.5 * 255).round()),
    labelStyle: GoogleFonts.tajawal(
      color: TColors.black,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    selectedColor: TColors.primary,
    secondarySelectedColor: TColors.primary.withAlpha((0.1 * 255).round()), // لون خفيف للخلفية عند الاختيار
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
    checkmarkColor: TColors.white,
    backgroundColor: TColors.lightContainer, // لون هادئ في الحالة العادية
    // شكل الحواف الدائري الحديث
    shape: StadiumBorder(
      side: BorderSide(color: TColors.grey.withAlpha((0.2 * 255).round())),
    ),

    // تأثير الضغط
    pressElevation: 0,
    elevation: 0,
  );

  static ChipThemeData darkChipTheme = ChipThemeData(
    disabledColor: TColors.darkerGrey,
    labelStyle: GoogleFonts.tajawal(
      color: TColors.white,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    selectedColor: TColors.primary,
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
    checkmarkColor: TColors.white,
    backgroundColor: TColors.darkerGrey.withAlpha((0.5 * 255).round()),

    shape: const StadiumBorder(side: BorderSide(color: TColors.darkerGrey)),

    pressElevation: 0,
    elevation: 0,
  );
}

/*
class TChipTheme {
  TChipTheme._();

  static ChipThemeData lightChipTheme = ChipThemeData(
    checkmarkColor: TColors.white,
    selectedColor: TColors.primary,
    disabledColor: TColors.grey.withAlpha((0.4 * 255).round()),
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
    labelStyle: const TextStyle(color: TColors.black),
  );

  static ChipThemeData darkChipTheme = const ChipThemeData(
    checkmarkColor: TColors.white,
    selectedColor: TColors.primary,
    disabledColor: TColors.darkerGrey,
    padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
    labelStyle: TextStyle(color: TColors.white),
  );
}*/


