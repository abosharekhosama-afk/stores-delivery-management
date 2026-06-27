import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/sizes.dart';
import 'package:google_fonts/google_fonts.dart';

class TAppBarTheme {
  TAppBarTheme._();

  static final lightAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false, // مظهر عصري أكثر (خاصة في أندرويد و iOS الحديث)
    scrolledUnderElevation: 0,
    backgroundColor: Colors.transparent, // لجعل الواجهة تبدو قطعة واحدة
    surfaceTintColor: Colors.transparent,
    iconTheme: const IconThemeData(
      color: TColors.iconPrimary,
      size: TSizes.iconMd,
    ),
    actionsIconTheme: const IconThemeData(
      color: TColors.iconPrimary,
      size: TSizes.iconMd,
    ),

    // تحسين العنوان
    titleTextStyle: GoogleFonts.tajawal(
      fontSize: 18.0,
      fontWeight: FontWeight.w700, // وزن أثقل قليلاً للبروز
      color: TColors.black,
    ),
  );

  static final darkAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,

    // تصحيح لون الأيقونات في الوضع الليلي
    iconTheme: const IconThemeData(color: TColors.white, size: TSizes.iconMd),
    actionsIconTheme: const IconThemeData(
      color: TColors.white,
      size: TSizes.iconMd,
    ),

    titleTextStyle: GoogleFonts.tajawal(
      fontSize: 18.0,
      fontWeight: FontWeight.w700,
      color: TColors.white,
    ),
  );
}













/*
class TAppBarTheme {
  TAppBarTheme._();

  static const lightAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    iconTheme: IconThemeData(color: TColors.iconPrimary, size: TSizes.iconMd),
    actionsIconTheme: IconThemeData(
      color: TColors.iconPrimary,
      size: TSizes.iconMd,
    ),
    titleTextStyle: TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      color: TColors.black,
    ),
  );
  static const darkAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: TColors.dark,
    surfaceTintColor: TColors.dark,
    iconTheme: IconThemeData(color: TColors.black, size: TSizes.iconMd),
    actionsIconTheme: IconThemeData(color: TColors.white, size: TSizes.iconMd),
    titleTextStyle: TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      color: TColors.white,
    ),
  );
}
*/