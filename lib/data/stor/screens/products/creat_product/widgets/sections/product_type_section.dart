import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/common/widgets/containers/rounded_container.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_addition_controller.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

/// ProductTypeSection - قسم اختيار نوع المنتج (مفرد/متغير)
/// يوفر واجهة تفاعلية لاختيار نوع المنتج مع شرح لكل نوع
class ProductTypeSection extends StatelessWidget {
  const ProductTypeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return TRoundedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TColors.primary.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
                ),
                child: Icon(
                  Iconsax.category_2,
                  color: TColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Text(
                "نوع المنتج",
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

          // Product Type Selection
          _buildProductTypeSelector(context),

          // Impact Notice
          const SizedBox(height: TSizes.spaceBtwItems),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TColors.info.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
              border: Border.all(color: TColors.info.withAlpha((0.3 * 255).round())),
            ),
            child: Row(
              children: [
                Icon(Iconsax.info_circle, color: TColors.info, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "تغيير نوع المنتج سيؤثر على الأقسام الأخرى في النموذج",
                    style: TextStyle(
                      fontSize: 12,
                      color: TColors.info,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء أداة اختيار نوع المنتج
  Widget _buildProductTypeSelector(BuildContext context) {
    final controller = ProductAdditionController.instance;

    return Obx(
      () => Row(
        children: [
          Text("نوع المنتج", style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: TSizes.spaceBtwItems),

          RadioMenuButton<ProductType>(
            value: ProductType.single,
            groupValue: controller.currentProductType,
            onChanged: (value) {
              if (value != null) {
                controller.updateProductType(value);
              }
            },
            child: const Text("مفرد"),
          ),
          RadioMenuButton<ProductType>(
            value: ProductType.variable,
            groupValue: controller.currentProductType,
            onChanged: (value) {
              if (value != null) {
                controller.updateProductType(value);
              }
            },
            child: const Text("متغير"),
          ),
        ],
      ),
    );
  }
}


