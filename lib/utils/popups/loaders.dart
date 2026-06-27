import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class TLoaders {
  static hideSnackBar() =>
      ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();

  static customToast({required message}) {
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        width: 500,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.transparent,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10,
              sigmaY: 10,
            ), // ضبابية محصورة في التوست فقط
            child: Container(
              padding: const EdgeInsets.all(12.0),
              margin: const EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.black.withOpacity(0.6),
              ),
              child: Center(
                child: Text(
                  message,
                  style: Theme.of(
                    Get.context!,
                  ).textTheme.labelLarge?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static successSnackBar({required title, message = '', duration = 3}) {
    // 🌟 قمنا بإزالة الـ overlayBlur تماماً واستبدلناه بـ BackdropFilter مدمج داخل كائن السناك بار
    Get.rawSnackbar(
      maxWidth: 600,
      duration: Duration(seconds: duration),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      backgroundColor: Colors
          .transparent, // جعل الخلفية الأصلية شفافة لكي يظهر الفلتر الزجاجي الخاص بنا
      //elevation: 0,
      isDismissible: true,

      // هنا نصنع التصميم الزجاجي المحصور بالحواف فقط
      messageText: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10,
            sigmaY: 10,
          ), // ضبابية الخلفية المباشرة للسناك بار فقط
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(
                0.5,
              ), // الشفافية البيضاء الفاتحة للنجاح
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.green.withOpacity(0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Iconsax.copy_success, color: Colors.green, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 15,
                        ),
                      ),
                      if (message.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static errorSnackBar({required title, message = ''}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.rawSnackbar(
        maxWidth: 600,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        backgroundColor: Colors.transparent,

        //elevation: 0,
        messageText: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(
                  0.12,
                ), // طبقة حمراء خفيفة جداً زجاجية
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.red.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.warning_2, color: Colors.red, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 15,
                          ),
                        ),
                        if (message.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  static warningSnackBar({required title, message = ''}) {
    Get.rawSnackbar(
      maxWidth: 600,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      backgroundColor: Colors.transparent,

      //elevation: 0,
      messageText: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(
                0.15,
              ), // طبقة برتقالية خفيفة زجاجية
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.02),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Iconsax.warning_2, color: Colors.orange, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          fontSize: 15,
                        ),
                      ),
                      if (message.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}







/*
class TLoaders {
  static hideSnackBar() =>
      ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();

  static customToast({required message}) {
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        width: 500,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.all(12.0),
          margin: const EdgeInsets.symmetric(horizontal: 30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: THelperFunctions.isDarkMode(Get.context!)
                ? TColors.darkerGrey.withAlpha((0.9 * 255).round())
                : TColors.grey.withAlpha((0.9 * 255).round()),
          ),
          child: Center(
            child: Text(
              message,
              style: Theme.of(Get.context!).textTheme.labelLarge,
            ),
          ),
        ),
      ),
    );
  }

  static successSnackBar({required title, message = '', duration = 3}) {
    Get.snackbar(
      title,
      message,
      maxWidth: 600,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: Colors.black87, // نص داكن قليلاً ليتناسب مع الزجاج الفاتح
      // --- اللمسة الزجاجية ---
      backgroundColor: Colors.white.withOpacity(0.4), // شفافية عالية
      overlayBlur: 3.0, // ضبابية خفيفة للمحتوى خلف السناك بار

      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      borderRadius: 20,

      // إضافة حافة ملونة خفيفة لتعبر عن الحالة
      borderWidth: 1,
      borderColor: Colors.green.withOpacity(0.3),

      icon: const Icon(Iconsax.copy_success, color: Colors.green, size: 28),

      // ستايل النص ليكون أكثر احترافية
      titleText: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
      messageText: Text(message, style: const TextStyle(color: Colors.black87)),

      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ],
    );
  }

  static errorSnackBar({required title, message = ''}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.snackbar(
        title,
        message,
        maxWidth: 600,
        colorText: Colors.red.shade900,

        // --- اللمسة الزجاجية ---
        backgroundColor: Colors.red.withOpacity(0.1), // لون أحمر خفيف جداً
        overlayBlur: 2.0,

        snackPosition: SnackPosition.BOTTOM,
        borderRadius: 20,
        borderWidth: 1,
        borderColor: Colors.red.withOpacity(0.2),

        icon: const Icon(Iconsax.warning_2, color: Colors.red, size: 28),

        titleText: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        messageText: Text(message, style: const TextStyle(color: Colors.red)),

        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      );
    });
  }

  static warningSnackBar({required title, message = ''}) {
    Get.snackbar(
      title,
      message,
      maxWidth: 600,
      isDismissible: true,
      shouldIconPulse: true,

      // --- التصميم الزجاجي (Glassmorphism) ---
      backgroundColor: Colors.orange.withOpacity(
        0.15,
      ), // لون برتقالي خفيف جداً خلف الزجاج
      overlayBlur: 3.0, // ضبابية للمحتوى الخلفي

      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      borderRadius: 20,

      // حافة برتقالية رفيعة تعطي انطباع العمق
      borderWidth: 1,
      borderColor: Colors.orange.withOpacity(0.3),

      // الأيقونة بلون برتقالي قوي للفت الانتباه
      icon: const Icon(Iconsax.warning_2, color: Colors.orange, size: 28),

      // تخصيص النصوص لتتناسب مع الطابع الزجاجي
      titleText: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.orange,
          fontSize: 16,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color:
              Colors.black87, // أو استخدم TColors.white إذا كنت في الوضع الليلي
          fontSize: 14,
        ),
      ),

      // ظل ناعم جداً لتبدو طافية
      boxShadows: [
        BoxShadow(
          color: Colors.orange.withOpacity(0.05),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }

  /*
  static successSnackBar({required title, message = '', duration = 3}) {
    Get.snackbar(
      title,
      message,
      maxWidth: 600,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: Colors.white,
      backgroundColor: TColors.primary,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(10),
      icon: const Icon(Iconsax.check, color: TColors.white),
    );
  }

  static warningSnackBar({required title, message = ''}) {
    Get.snackbar(
      title,
      message,
      maxWidth: 600,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: TColors.white,
      backgroundColor: Colors.orange,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(20),
      icon: const Icon(Iconsax.warning_2, color: TColors.white),
    );
  }

  static errorSnackBar({required title, message = ''}) {
    // ننتظر حتى ينتهي الفريم الحالي
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.snackbar(
        title,
        message,
        // باقي الإعدادات كما هي...
        maxWidth: 600,
        isDismissible: true,
        shouldIconPulse: true,
        colorText: TColors.white,
        backgroundColor: Colors.red.shade600,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(20),
        icon: const Icon(Iconsax.warning_2, color: TColors.white),
      );
    });
  }

*/
}
*/