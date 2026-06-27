import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/common/widgets/images/t_rounded_image.dart';
import 'package:stors_admin_panel/data/stor/models/product_model.dart';
import 'package:stors_admin_panel/routes/routes.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class TProductCardDesktop extends StatelessWidget {
  const TProductCardDesktop({super.key, required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        border: Border.all(color: TColors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // الجزء العلوي: الصورة + أزرار التحكم
          Expanded(
            child: Stack(
              children: [
                TRoundedImage(
                  image: product.thumbnail,
                  imageType: ImageType.network,
                  applyImageRadius: true,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                // أزرار التحكم تظهر في الديسكتوب بشكل ثابت أو عند الحوم (Hover)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Column(
                    children: [
                      IconButton(
                        onPressed: () => Get.toNamed(
                          TRoutes.editProduct,
                          arguments: product,
                        ),
                        icon: const Icon(Iconsax.edit, color: Colors.blue),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      IconButton(
                        onPressed: () {}, // دالة الحذف
                        icon: const Icon(Iconsax.trash, color: Colors.red),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // الجزء السفلي: البيانات
          Padding(
            padding: const EdgeInsets.all(TSizes.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "\$${product.price}",
                      style: Theme.of(context).textTheme.headlineSmall!
                          .copyWith(color: TColors.primary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: product.stock > 0
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "المخزون: ${product.stock}",
                        style: TextStyle(
                          color: product.stock > 0 ? Colors.green : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
