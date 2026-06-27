import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/containers/rounded_container.dart';
import 'package:stors_admin_panel/common/widgets/images/t_rounded_image.dart';
import 'package:stors_admin_panel/features/media/controller/media_controller.dart';
import 'package:stors_admin_panel/features/media/models/image_model.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class ImageGalleryWidget extends StatelessWidget {
  const ImageGalleryWidget({
    super.key,
    required this.onImageSelected,
    this.allowMultipleSelection = false,
    this.selectedImages = const [],
    this.category = MediaCategory.products,
  });

  final Function(List<ImageModel>) onImageSelected;
  final bool allowMultipleSelection;
  final List<ImageModel> selectedImages;
  final MediaCategory category;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MediaController());
    controller.selectPath.value = category;

    if (controller.alProductImages.isEmpty) {
      controller.getMediaImages();
    }

    return Obx(
      () => TRoundedContainer(
        height: 400,
        child: Column(
          children: [
            // Header with category selector and upload button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "معرض الصور",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                ElevatedButton.icon(
                  onPressed: () => controller.selectedLocalImages(),
                  icon: const Icon(Icons.upload),
                  label: const Text("رفع صور جديدة"),
                ),
              ],
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Images Grid
            Expanded(
              child: controller.loading.value
                  ? const Center(child: CircularProgressIndicator())
                  : _buildImagesGrid(controller),
            ),

            // Selected Images Preview
            if (selectedImages.isNotEmpty)
              Container(
                height: 80,
                margin: const EdgeInsets.only(top: TSizes.spaceBtwItems),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedImages.length,
                  itemBuilder: (context, index) {
                    final image = selectedImages[index];
                    return Container(
                      margin: const EdgeInsets.only(
                        right: TSizes.spaceBtwItems / 2,
                      ),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: TColors.primary),
                        borderRadius: BorderRadius.circular(
                          TSizes.borderRadiusMd,
                        ),
                      ),
                      child: Stack(
                        children: [
                          TRoundedImage(
                            imageType: ImageType.network,
                            image: image.url,
                            width: 80,
                            height: 80,
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              onPressed: () {
                                final newSelected = List<ImageModel>.from(
                                  selectedImages,
                                );
                                newSelected.removeAt(index);
                                onImageSelected(newSelected);
                              },
                              icon: const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesGrid(MediaController controller) {
    final images = _getImagesForCategory(controller);

    if (images.isEmpty) {
      return const Center(child: Text("لا توجد صور في هذا المجلد"));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: TSizes.spaceBtwItems,
        mainAxisSpacing: TSizes.spaceBtwItems,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        final isSelected = selectedImages.contains(image);

        return GestureDetector(
          onTap: () {
            if (allowMultipleSelection) {
              final newSelected = List<ImageModel>.from(selectedImages);
              if (isSelected) {
                newSelected.remove(image);
              } else {
                newSelected.add(image);
              }
              onImageSelected(newSelected);
            } else {
              onImageSelected([image]);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? TColors.primary : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
            ),
            child: Stack(
              children: [
                TRoundedImage(
                  imageType: ImageType.network,
                  image: image.url,
                  width: double.infinity,
                  height: double.infinity,
                ),
                if (isSelected)
                  const Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(Icons.check_circle, color: TColors.primary),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<ImageModel> _getImagesForCategory(MediaController controller) {
    switch (category) {
      case MediaCategory.banners:
        return controller.alBannerImages;
      case MediaCategory.brands:
        return controller.alBrandImages;
      case MediaCategory.products:
        return controller.alProductImages;
      case MediaCategory.categories:
        return controller.alCategoryImages;
      case MediaCategory.users:
        return controller.alUserImages;
      default:
        return controller.alImages;
    }
  }
}
