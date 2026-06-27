import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/images/t_rounded_image.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_detail_controller.dart';
import 'package:stors_admin_panel/data/stor/models/product_model.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';

class TProductImageHeader extends StatelessWidget {
  const TProductImageHeader({super.key, required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductDetailController>();
    final List<String> allImages = [
      product.thumbnail,
      ...(product.images ?? []),
    ];

    return SliverAppBar(
      automaticallyImplyLeading: true,
      expandedHeight: 450,
      stretch: true,
      backgroundColor: Colors.white,
      // تصميم الحافة السفلية المقوسة
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: TColors.light,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
          ),
          child: Stack(
            children: [
              /// الصورة الرئيسية مع Hero Animation
              Center(
                child: Obx(() {
                  final image =
                      controller.selectedVariation.value?.image.isNotEmpty ==
                          true
                      ? controller.selectedVariation.value!.image
                      : controller.selectedImage.value;
                  return Hero(
                    tag: product.id,
                    child: TRoundedImage(
                      padding: 0.0,
                      image: image,
                      imageType: ImageType.network,
                      width: double.infinity,
                      height: double.infinity,
                      customBorderRadius: BorderRadius.only(
                        topLeft: Radius.zero,
                        topRight: Radius.zero,
                      ),
                      fit: BoxFit.cover,
                      backgroundColor: Colors.transparent,
                    ),
                  );
                }),
              ),

              /// قائمة الصور المصغرة العائمة (Floating Gallery)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Container(
                  height: 70,
                  alignment: Alignment.center,
                  child: ListView.separated(
                    itemCount: allImages.length,
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, index) {
                      return Obx(() {
                        final isSelected =
                            controller.selectedImage.value == allImages[index];
                        return GestureDetector(
                          onTap: () =>
                              controller.selectedImage.value = allImages[index],
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? TColors.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: TColors.primary.withOpacity(0.3),
                                    blurRadius: 10,
                                  ),
                              ],
                            ),
                            child: TRoundedImage(
                              padding: 0.0,
                              borderRadius: 10,
                              image: allImages[index],
                              imageType: ImageType.network,
                              width: 60,
                              height: 70,
                              fit: BoxFit.cover,
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        );
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
