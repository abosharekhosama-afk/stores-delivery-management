import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class TPriceUpdateDialog extends StatelessWidget {
  const TPriceUpdateDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.confirmText = "تطبيق على الكل",
    this.cancelText = "إلغاء",
  });

  final String title, content, confirmText, cancelText;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // أيقونة تحذيرية جذابة
            Container(
              padding: const EdgeInsets.all(TSizes.md),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.info_circle,
                color: Colors.orange,
                size: 40,
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            // العنوان
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TSizes.spaceBtwItems / 2),

            // المحتوى
            Text(
              content,
              style: Theme.of(
                context,
              ).textTheme.labelLarge!.copyWith(color: TColors.darkGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TSizes.spaceBtwSections),

            // الأزرار
            Row(
              children: [
                // زر الإلغاء
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                      side: const BorderSide(color: TColors.grey),
                    ),
                    child: Text(
                      cancelText,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems),

                // زر التأكيد
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.primary,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                    ),
                    child: Text(confirmText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
