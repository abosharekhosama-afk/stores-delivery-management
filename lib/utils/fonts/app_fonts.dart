import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppFonts - إدارة الخطوط المستخدمة في التطبيق
class AppFonts {
  /// خط Cairo - خط عربي أساسي
  static TextStyle cairo({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.cairo(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
    );
  }

  /// خط Tajawal - خط عربي أنيق للعناوين
  static TextStyle tajawal({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.tajawal(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
    );
  }

  /// خط Amiri - خط عربي كلاسيكي
  static TextStyle amiri({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.amiri(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
    );
  }

  /// خط Noto Sans Arabic - خط عربي شامل
  static TextStyle notoSansArabic({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.notoSansArabic(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
    );
  }

  /// خط Cairo من الملفات المحلية (fallback)
  static const String cairoFamily = 'Cairo';

  /// خط Urbanist من الملفات المحلية
  static const String urbanistFamily = 'Urbanist';

  /// خط Montserrat من الملفات المحلية
  static const String montserratFamily = 'Montserrat';
}

/// Extension لتسهيل استخدام الخطوط
extension TextStyleExtensions on TextStyle {
  /// تطبيق خط Cairo
  TextStyle get cairo => copyWith(fontFamily: AppFonts.cairoFamily);

  /// تطبيق خط Tajawal
  /* TextStyle get tajawal => AppFonts.tajawal(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );

  /// تطبيق خط Amiri
  TextStyle get amiri => AppFonts.amiri(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );

  /// تطبيق خط Noto Sans Arabic
  TextStyle get notoArabic => AppFonts.notoSansArabic(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );*/
}
