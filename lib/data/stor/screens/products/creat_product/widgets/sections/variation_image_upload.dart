import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/common/widgets/containers/rounded_container.dart';
import 'package:stors_admin_panel/common/widgets/images/image_uploader.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_variation_image_controller.dart';
import 'package:stors_admin_panel/data/stor/models/product_variation_model.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/constants/image_strings.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';
import 'package:stors_admin_panel/utils/device/device_utility.dart';

class VariationImageUpload extends StatelessWidget {
  const VariationImageUpload({super.key, required this.variation});

  final ProductVariationModel variation;

  @override
  Widget build(BuildContext context) {
    final imageController = Get.put(ProductVariationImageController());
    final bool isDesktop = TDeviceUtils.isDesktopScreen(context);

    return Obx(() {
      final imageBytes = imageController.getImageBytes(variation.id);
      final bool hasLocalImage = imageBytes != null;
      final bool hasNetworkImage = variation.image.isNotEmpty && !hasLocalImage;

      return TRoundedContainer(
        width: 120,
        height: 120,
        backgroundColor: TColors.primaryBackground,
        // إزالة أي padding لضمان وصول الصورة للحواف
        child: ClipRRect(
          // لضمان قص الصورة مع زوايا الحاوية
          borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
          child: Stack(
            children: [
              // 1. DropZone Layer (Desktop)
              if (isDesktop)
                Positioned.fill(
                  child: DropzoneView(
                    onCreated: (controller) =>
                        imageController.dropzoneControllers[variation.id] =
                            controller,
                    onDropFile: (event) async => await imageController
                        .handleDroppedFile(event, variation),
                  ),
                ),

              // 2. Image Content
              Positioned.fill(
                child: GestureDetector(
                  onTap: () =>
                      imageController.selectVariationImage(context, variation),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: TColors.borderPrimary.withAlpha(
                          (0.5 * 255).round(),
                        ),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(
                        TSizes.borderRadiusMd,
                      ),
                    ),
                    child: _buildImageContent(
                      hasLocalImage,
                      hasNetworkImage,
                      imageBytes,
                      imageController,
                      context,
                    ),
                  ),
                ),
              ),

              // 3. Loading Overlay
              if (imageController.variationImageLoading[variation.id] ?? false)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withAlpha((0.3 * 255).round()),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  // دالة فرعية لتنظيف الكود وعرض الصورة أو الأيقونة
  Widget _buildImageContent(
    bool hasLocalImage,
    bool hasNetworkImage,
    Uint8List? imageBytes,
    ProductVariationImageController imageController,
    BuildContext context,
  ) {
    if (hasLocalImage || hasNetworkImage) {
      return TImageUploader(
        borderRadius: TSizes.borderRadiusMd,
        imageType: hasLocalImage ? ImageType.memory : ImageType.network,
        image: hasNetworkImage ? variation.image : TImages.defaultImage,
        memoryImage: imageBytes,
        width: 120,
        height: 120,
        // تأكد أن TImageUploader يستخدم BoxFit.cover داخلياً
      );
    } else {
      return const Icon(Iconsax.cloud_add, color: TColors.primary, size: 28);
    }
  }
}
