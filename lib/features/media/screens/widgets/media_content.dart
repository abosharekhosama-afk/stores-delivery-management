import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/common/widgets/images/t_rounded_image.dart';
import 'package:stors_admin_panel/common/widgets/loaders/animation_loader.dart';
import 'package:stors_admin_panel/common/widgets/loaders/loader_animation.dart';
import 'package:stors_admin_panel/features/media/controller/media_controller.dart';
import 'package:stors_admin_panel/features/media/models/image_model.dart';
import 'package:stors_admin_panel/features/media/screens/widgets/folder_dropdown.dart';
import 'package:stors_admin_panel/features/media/screens/widgets/view_image_details.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/constants/image_strings.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class MediaContent extends StatelessWidget {
  const MediaContent({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = MediaController.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("اختر مجلد", style: Theme.of(context).textTheme.headlineSmall),
            FolderDropdown(
              onChanged: (MediaCategory? newVal) {
                if (newVal != null) {
                  controller.selectPath.value = newVal;
                  controller.getMediaImages();
                }
              },
            ),
          ],
        ),

        const SizedBox(height: TSizes.spaceBtwSections),
        Obx(() {
          List<ImageModel> images = _getSelectedFolderImages(controller);
          if (controller.loading.value && images.isEmpty) {
            return const TLoaderAnimation();
          }
          if (images.isEmpty) return _buildEmptyAnimationWidget(context);
          return Column(
            children: [
              Wrap(
                alignment: WrapAlignment.start,
                spacing: TSizes.spaceBtwItems / 2,
                runSpacing: TSizes.spaceBtwItems / 2,
                children: images
                    .map(
                      (image) => GestureDetector(
                        onTap: () => Get.dialog(ViewImageDetails(image: image)),
                        child: SizedBox(
                          width: 140,
                          height: 180,
                          child: Column(
                            children: [
                              _buildSimpleList(image),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: TSizes.sm,
                                  ),
                                  child: Text(
                                    image.fileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (!controller.loading.value)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: TSizes.spaceBtwSections,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: TSizes.buttonWidth,
                        child: ElevatedButton.icon(
                          onPressed: () => controller.loadMoreMediaImages(),
                          label: const Text("المزيد"),
                          icon: const Icon(Iconsax.arrow_down),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  /* [
                  ListView.builder(
                    itemCount: 11,
                    itemBuilder: (context, index) {
                      return TRoundedImage(
                        imageType: ImageType.asset,
                        image: TImages.adidasLogo,
                        width: 90,
                        height: 90,
                        padding: TSizes.sm,
                        backgroundColor: TColors.primaryBackground,
                      );
                    },
                  ),
                ],*/

  List<ImageModel> _getSelectedFolderImages(MediaController controller) {
    List<ImageModel> images = [];
    if (controller.selectPath.value == MediaCategory.banners) {
      images = controller.alBannerImages
          .where((image) => image.url.isNotEmpty)
          .toList();
    } else if (controller.selectPath.value == MediaCategory.brands) {
      images = controller.alBrandImages
          .where((image) => image.url.isNotEmpty)
          .toList();
    } else if (controller.selectPath.value == MediaCategory.products) {
      images = controller.alProductImages
          .where((image) => image.url.isNotEmpty)
          .toList();
    } else if (controller.selectPath.value == MediaCategory.categories) {
      images = controller.alCategoryImages
          .where((image) => image.url.isNotEmpty)
          .toList();
    }
    return images;
  }

  Widget _buildEmptyAnimationWidget(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: TSizes.lg * 3),
      child: TAnimationLoaderWidget(
        width: 300,
        height: 300,
        text: "قم باختار مجلد",
        animation: TImages.packageAnimation,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildSimpleList(ImageModel image) {
    return TRoundedImage(
      width: 140,
      height: 140,
      padding: TSizes.sm,
      image: image.url,
      imageType: ImageType.network,
      margin: TSizes.spaceBtwItems / 2,
      backgroundColor: TColors.primaryBackground,
    );
  }
}
