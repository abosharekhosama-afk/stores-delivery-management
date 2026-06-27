import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/loaders/animation_loader.dart';
import 'package:stors_admin_panel/common/widgets/loaders/circular_loader.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_addition_controller.dart';
import '../constants/colors.dart';
import '../helpers/helper_functions.dart';

/// A utility class for managing a full-screen loading dialog.
class TFullScreenLoader {
  /// Open a full-screen loading dialog with a given text and animation.
  /// This method doesn't return anything.
  ///
  /// Parameters:
  ///   - text: The text to be displayed in the loading dialog.
  ///   - animation: The Lottie animation to be shown.
  /*static void openLoadingDialog(String text, String animation) {
    showDialog(
      context: Get.overlayContext!,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Container(
          color: THelperFunctions.isDarkMode(Get.context!)
              ? TColors.dark
              : TColors.white,
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: [
              const SizedBox(height: 250),
              TAnimationLoaderWidget(text: text, animation: animation),
            ],
          ),
        ),
      ),
    );
  }*/

  static void openLoadingDialogForProduct(String text, String animation) {
    // استخدام find آمن هنا لأن الواجهة تعتمد على الكنترولر أصلاً
    final controller = Get.find<ProductAdditionController>();

    showDialog(
      context: Get.overlayContext!,
      barrierDismissible: false, // مهم جداً: منع الإغلاق العشوائي
      builder: (_) => PopScope(
        canPop: false, // منع زر العودة في أندرويد
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                // دعم الوضع الليلي في اللودر
                color: THelperFunctions.isDarkMode(Get.context!)
                    ? TColors.dark.withOpacity(0.8)
                    : TColors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Obx(
                          () => CircularProgressIndicator(
                            value: controller.uploadProgress.value,
                            strokeWidth: 8,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.pinkAccent,
                            ),
                          ),
                        ),
                      ),
                      Obx(
                        () => Text(
                          "${(controller.uploadProgress.value * 100).toInt()}%",
                          style: Theme.of(Get.context!).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    text, // استخدم النص الممرر للدالة ليكون متغيراً
                    textAlign: TextAlign.center,
                    style: Theme.of(Get.context!).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void openLoadingDialog(String text, String animation) {
    showDialog(
      context: Get.overlayContext!,
      barrierDismissible: false, // منع إغلاق الدايالوج عند الضغط خارجه
      builder: (_) => PopScope(
        canPop: false, // منع العودة للخلف بالزر المادي للهاتف
        child: Scaffold(
          // استخدام Scaffold بخصائص شفافة يجعل التعامل مع الألوان أسهل
          backgroundColor: Colors.transparent,
          body: Container(
            // جعل الخلفية شبه شفافة مع لون يتناسب مع الوضع الليلي/العادي
            color: THelperFunctions.isDarkMode(Get.context!)
                ? TColors.dark.withOpacity(0.8)
                : TColors.white.withOpacity(0.8),
            width: double.infinity,
            height: double.infinity,
            child: Center(
              // استخدام Center بدلاً من المسافات الثابتة
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // الأنيميشن والنص
                    TAnimationLoaderWidget(text: text, animation: animation),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void popUpCircular() {
    Get.defaultDialog(
      title: '',
      onWillPop: () async => false,
      content: const TCircularLoader(),
      backgroundColor: Colors.transparent,
    );
  }

  /// Stop the currently open loading dialog.
  /// This method doesn't return anything.
  static stopLoadingcopy() {
    try {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      } else if (Get.overlayContext != null &&
          Navigator.canPop(Get.overlayContext!)) {
        Navigator.of(Get.overlayContext!).pop();
      }
    } catch (e) {
      // Ignore errors if dialog is already closed or context is invalid
    }
  }

  static stopLoading() {
    Navigator.of(
      Get.overlayContext!,
    ).pop(); // Close the dialog using the Navigator
  }
}
