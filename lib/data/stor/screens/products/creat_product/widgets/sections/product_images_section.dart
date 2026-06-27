import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/common/widgets/containers/rounded_container.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_image_controller.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_addition_controller.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

/// ProductImagesSection - قسم إدارة صور المنتج
/// يتيح رفع الصورة الرئيسية وصور إضافية للمنتج
class ProductImagesSection extends StatelessWidget {
  const ProductImagesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProductAdditionController.instance;
    Get.put(ProductImageController());

    return TRoundedContainer(
      child: Form(
        key: controller.imagesFormKey,
        child: Builder(
          builder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: TColors.primary.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(
                        TSizes.borderRadiusMd,
                      ),
                    ),
                    child: Icon(
                      Iconsax.image,
                      color: TColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Text(
                    "صور المنتج",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: TColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: TSizes.spaceBtwItems),
              const Divider(),
              const SizedBox(height: TSizes.spaceBtwItems),

              // Main Image Section
              _buildMainImageSection(context),
              const SizedBox(height: TSizes.spaceBtwSections),

              // Additional Images Section
              _buildAdditionalImagesSection(context),

              // Images Tips
              const SizedBox(height: TSizes.spaceBtwItems),
              _buildImagesTips(),

              // Validation Status
              const SizedBox(height: TSizes.spaceBtwItems),
              Obx(() => _buildValidationStatus()),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء قسم الصورة الرئيسية
  Widget _buildMainImageSection(BuildContext context) {
    final controller = ProductAdditionController.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "الصورة الرئيسية",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: TColors.textPrimary,
              ),
            ),
            Text(
              " *",
              style: TextStyle(
                color: TColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwItems),

        Obx(() {
          final mainImageUrl = controller.mainImageUrl.value;
          final mainImageBytes = controller.imageController.getMainImageBytes();
          final isLoading = controller.mainImageLoading.value;

          return Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: TColors.lightGrey,
              borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
              border: Border.all(
                color: (mainImageUrl != null || mainImageBytes != null)
                    ? TColors.primary
                    : TColors.grey.withAlpha((0.3 * 255).round()),
                width: (mainImageUrl != null || mainImageBytes != null) ? 2 : 1,
              ),
            ),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : (mainImageUrl != null || mainImageBytes != null)
                ? _buildImagePreview(
                    mainImageUrl,
                    mainImageBytes,
                    isMain: true,
                    context: context,
                  )
                : _buildImageUploadPlaceholder(context, isMain: true),
          );
        }),
      ],
    );
  }

  /// بناء قسم الصور الإضافية
  Widget _buildAdditionalImagesSection(BuildContext context) {
    final controller =
        ProductImageController.instance; // تأكد من استخدام الكنترولر الصحيح

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "الصور الإضافية",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            TextButton.icon(
              onPressed: () => ProductAdditionController.instance
                  .addAdditionalImages(context),
              icon: const Icon(Iconsax.add, size: 14),
              label: const Text("إضافة المزيد"),
            ),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        Obx(() {
          final urls = controller.additionalImageUrls;
          final bytes = controller.additionalImageBytes;
          final totalCount = urls.length + bytes.length;

          return SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              // أضفنا 1 ليكون هناك دائماً زر "إضافة" في نهاية القائمة
              itemCount: totalCount + 1,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: TSizes.spaceBtwItems),
              itemBuilder: (context, index) {
                if (index == totalCount) {
                  // آخر عنصر هو دائماً زر الإضافة الصغير
                  return _buildAddMoreButton(context);
                }

                if (index < urls.length) {
                  return _buildAdditionalImageItem(urls[index], null, index);
                } else {
                  return _buildAdditionalImageItem(
                    null,
                    bytes[index - urls.length],
                    index,
                  );
                }
              },
            ),
          );
        }),
      ],
    );
  }

  /// زر إضافة صغير داخل القائمة العرضية
  Widget _buildAddMoreButton(BuildContext context) {
    return InkWell(
      onTap: () =>
          ProductAdditionController.instance.addAdditionalImages(context),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
          border: Border.all(
            color: TColors.grey.withAlpha(50),
            style: BorderStyle.solid,
          ),
        ),
        child: const Icon(Iconsax.add_square, color: TColors.grey),
      ),
    );
  }

  /*Widget _buildAdditionalImagesSection(BuildContext context) {
    final controller = ProductAdditionController.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "الصور الإضافية",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: TColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () => controller.addAdditionalImages(context),
              icon: Icon(Iconsax.add, size: 14),
              label: const Text("إضافة صور"),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        Obx(() {
          final additionalImageUrls =
              controller.imageController.additionalImageUrls;
          final additionalImageBytes =
              controller.imageController.additionalImageBytes;

          // إجمالي الصور الحقيقي هو مجموع القائمتين فعلياً
          final totalImages =
              additionalImageUrls.length + additionalImageBytes.length;

          if (totalImages == 0) {
            return Container(/* ... الكود الحالي للـ placeholder ... */);
          }

          return SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: totalImages,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: TSizes.spaceBtwItems),
              itemBuilder: (context, index) {
                // إذا كان الـ index أصغر من طول قائمة الـ URLs، فهو يتبع لـ URLs
                if (index < additionalImageUrls.length) {
                  return _buildAdditionalImageItem(
                    additionalImageUrls[index],
                    null,
                    index,
                  );
                } else {
                  // إذا كان أكبر، نطرح منه طول الـ URLs لنحصل على الـ index الصحيح في قائمة الـ Bytes
                  final byteIndex = index - additionalImageUrls.length;
                  return _buildAdditionalImageItem(
                    null,
                    additionalImageBytes[byteIndex],
                    index, // نرسل الـ index الكلي للدالة
                  );
                }
              },
            ),
          );
        }),

        /*Obx(() {
          final additionalImageUrls =
              controller.imageController.additionalImageUrls;
          final additionalImageBytes =
              controller.imageController.additionalImageBytes;

          // Combine URLs and bytes for display
          final totalImages =
              additionalImageUrls.length + additionalImageBytes.length;

          if (totalImages == 0) {
            return Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: TColors.lightGrey,
                borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
                border: Border.all(color: TColors.grey.withAlpha((0.3 * 255).round())),
              ),
              child: _buildImageUploadPlaceholder(context, isMain: false),
            );
          }

          return SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: totalImages,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: TSizes.spaceBtwItems),
              itemBuilder: (context, index) {
                if (index < additionalImageUrls.length) {
                  return _buildAdditionalImageItem(
                    additionalImageUrls[index],
                    null,
                    index,
                  );
                } else {
                  final byteIndex = index - additionalImageUrls.length;
                  return _buildAdditionalImageItem(
                    null,
                    additionalImageBytes[byteIndex],
                    index,
                  );
                }
              },
            ),
          );
        }),*/
      ],
    );
  }
*/
  /// بناء معاينة الصورة
  Widget _buildImagePreview(
    String? imageUrl,
    Uint8List? imageBytes, {
    required bool isMain,
    required BuildContext context,
  }) {
    final controller = ProductAdditionController.instance;
    return Stack(
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
          child: imageBytes != null
              ? Image.memory(
                  imageBytes,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: TColors.grey.withAlpha((0.3 * 255).round()),
                      child: Icon(Iconsax.image, color: TColors.grey, size: 48),
                    );
                  },
                )
              : Image.network(
                  imageUrl!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: TColors.grey.withAlpha((0.3 * 255).round()),
                      child: Icon(Iconsax.image, color: TColors.grey, size: 48),
                    );
                  },
                ),
        ),

        // Overlay with actions
        Positioned.fill(
          bottom: 0.0,
          right: 0.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
              color: Colors.black.withAlpha((0.3 * 255).round()),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Change button
                    _buildImageActionButton(
                      icon: Iconsax.edit,
                      label: "تغيير",
                      onPressed: () {
                        if (isMain) {
                          controller.selectMainImage(context);
                        } else {
                          // TODO: Implement change for additional images
                        }
                      },
                    ),
                    const SizedBox(width: TSizes.spaceBtwItems),

                    // Delete button
                    _buildImageActionButton(
                      icon: Iconsax.trash,
                      label: "حذف",
                      onPressed: () {
                        if (isMain) {
                          controller.removeMainImage();
                        } else {
                          // TODO: Implement delete for additional images
                        }
                      },
                      isDestructive: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Main image indicator
        if (isMain)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: TColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "رئيسية",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// بناء عنصر صورة إضافية
  Widget _buildAdditionalImageItem(
    String? imageUrl,
    Uint8List? imageBytes,
    int index,
  ) {
    final controller = ProductAdditionController.instance;

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
        border: Border.all(color: TColors.grey.withAlpha((0.3 * 255).round())),
      ),
      child: Stack(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
            child: imageBytes != null
                ? Image.memory(
                    imageBytes,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: TColors.grey.withAlpha((0.3 * 255).round()),
                        child: Icon(
                          Iconsax.image,
                          color: TColors.grey,
                          size: 24,
                        ),
                      );
                    },
                  )
                : Image.network(
                    imageUrl!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: TColors.grey.withAlpha((0.3 * 255).round()),
                        child: Icon(
                          Iconsax.image,
                          color: TColors.grey,
                          size: 24,
                        ),
                      );
                    },
                  ),
          ),

          // Actions overlay
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha((0.6 * 255).round()),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => controller.removeProductImage(index),
                icon: Icon(Iconsax.close_circle, color: Colors.white, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              ),
            ),
          ),

          // Set as main image button
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: ElevatedButton(
              onPressed: () => controller.setAsMainImage(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.primary.withAlpha((0.2 * 255).round()),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(double.infinity, 24),
              ),
              child: Text(
                "اجعلها رئيسية",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء زر عمل للصورة
  Widget _buildImageActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 14,
        color: isDestructive ? TColors.white : Colors.white,
      ),
      /*label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isDestructive ? TColors.error : Colors.white,
        ),
      ),*/
      style: ElevatedButton.styleFrom(
        backgroundColor: isDestructive
            ? TColors.error.withAlpha((0.8 * 255).round())
            : TColors.primary.withAlpha((0.8 * 255).round()),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  /// بناء placeholder لرفع الصور
  Widget _buildImageUploadPlaceholder(
    BuildContext context, {
    required bool isMain,
  }) {
    final controller = ProductAdditionController.instance;
    return InkWell(
      onTap: () async {
        if (isMain) {
          await controller.selectMainImage(context);
        } else {
          await controller.addAdditionalImages(context);
        }
      },
      borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TColors.grey.withAlpha((0.2 * 255).round()),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMain ? Iconsax.camera : Iconsax.image,
              color: TColors.grey,
              size: 32,
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Text(
            isMain ? "اختر الصورة الرئيسية" : "أضف صوراً إضافية",
            style: TextStyle(
              color: TColors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "انقر للرفع أو السحب والإفلات",
            style: TextStyle(
              color: TColors.grey.withAlpha((0.7 * 255).round()),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء نصائح الصور
  Widget _buildImagesTips() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TColors.info.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
        border: Border.all(color: TColors.info.withAlpha((0.3 * 255).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.info_circle, color: TColors.info, size: 16),
              const SizedBox(width: 8),
              Text(
                "نصائح الصور",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: TColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "• الصور عالية الجودة تزيد من مبيعات المنتج\n"
            "• استخدم خلفية بيضاء أو شفافة للمنتجات\n"
            "• أضف صور من زوايا مختلفة للمنتج\n"
            "• حجم الصورة المثالي: 800x800 بكسل على الأقل\n"
            "• الصورة الرئيسية ستظهر في قائمة المنتجات",
            style: TextStyle(
              fontSize: 12,
              color: TColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء حالة التحقق
  Widget _buildValidationStatus() {
    final controller = ProductAdditionController.instance;
    final isValid = controller.isImagesComplete.value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isValid
            ? TColors.success.withAlpha((0.1 * 255).round())
            : TColors.warning.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
        border: Border.all(
          color: isValid ? TColors.success : TColors.warning,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Iconsax.tick_circle : Iconsax.warning_2,
            color: isValid ? TColors.success : TColors.warning,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            isValid ? "صور المنتج صحيحة" : "يرجى مراجعة صور المنتج",
            style: TextStyle(
              fontSize: 12,
              color: isValid ? TColors.success : TColors.warning,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
