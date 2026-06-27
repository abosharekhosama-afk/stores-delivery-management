import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/breadcrumbs/breadcrumb_with_heading.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_addition_controller.dart';
import 'package:stors_admin_panel/data/stor/screens/products/creat_product/widgets/sections/basic_info_section.dart';
import 'package:stors_admin_panel/data/stor/screens/products/creat_product/widgets/sections/product_attributes_section.dart';
import 'package:stors_admin_panel/data/stor/screens/products/creat_product/widgets/sections/product_category_section.dart';
import 'package:stors_admin_panel/data/stor/screens/products/creat_product/widgets/sections/product_images_section.dart';
import 'package:stors_admin_panel/data/stor/screens/products/creat_product/widgets/sections/product_pricing_section.dart';
import 'package:stors_admin_panel/data/stor/screens/products/creat_product/widgets/sections/product_type_section.dart';
import 'package:stors_admin_panel/data/stor/screens/products/creat_product/widgets/sections/product_variations_section.dart';
import 'package:stors_admin_panel/data/stor/screens/products/creat_product/widgets/sections/product_visibilty_widget.dart';
import 'package:stors_admin_panel/routes/routes.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class EditProductDesktop extends StatelessWidget {
  const EditProductDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return
    //bottomNavigationBar: _buildBottomNavigation(),
    SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BreadcrumbWithHeading(
              resurnToPreviousScreen: true,
              heading: "تعديل المنتج",
              breadcrumbItems: [TRoutes.products, "تعديل المنتج"],
            ),
            const SizedBox(height: TSizes.spaceBtwSections),

            // Progress Indicator
            _buildProgressIndicator(),
            const SizedBox(height: TSizes.spaceBtwSections),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      BasicInfoSection(),
                      SizedBox(height: TSizes.spaceBtwSections),
                      ProductTypeSection(),
                      SizedBox(height: TSizes.spaceBtwSections),
                      ProductPricingSection(),
                      SizedBox(height: TSizes.spaceBtwSections),
                      ProductAttributesSection(),
                      SizedBox(height: TSizes.spaceBtwSections),
                      ProductVariationsSection(),
                    ],
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwSections),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ProductCategorySection(),
                      SizedBox(height: TSizes.spaceBtwSections),
                      ProductImagesSection(),
                      SizedBox(height: TSizes.spaceBtwSections),
                      ProductVisibiltyWidget(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Obx(() {
      final controller = Get.find<ProductAdditionController>();
      final completedSections = controller.getCompletedSectionsCount();
      final totalSections =
          7; // Basic Info, Type, Pricing, Attributes, Variations, Category, Images

      return Container(
        padding: const EdgeInsets.all(TSizes.spaceBtwItems),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
          border: Border.all(
            color: TColors.grey.withAlpha((0.3 * 255).round()),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "تقدم إضافة المنتج",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: TColors.dark,
                  ),
                ),
                Text(
                  "$completedSections من $totalSections",
                  style: TextStyle(fontSize: 14, color: TColors.grey),
                ),
              ],
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            LinearProgressIndicator(
              value: completedSections / totalSections,
              backgroundColor: TColors.grey.withAlpha((0.3 * 255).round()),
              valueColor: AlwaysStoppedAnimation<Color>(
                completedSections == totalSections
                    ? TColors.success
                    : TColors.primary,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBottomNavigation() {
    return Obx(() {
      final controller = Get.find<ProductAdditionController>();
      final isValid = controller.isFormValid;

      return Container(
        padding: const EdgeInsets.all(TSizes.spaceBtwItems),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: TColors.grey.withAlpha((0.3 * 255).round())),
          ),
        ),
        child: Row(
          children: [
            // Cancel Button
            Expanded(
              child: OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: TSizes.buttonHeight / 2,
                  ),
                  side: BorderSide(color: TColors.grey),
                ),
                child: Text("إلغاء", style: TextStyle(color: TColors.dark)),
              ),
            ),
            const SizedBox(width: TSizes.spaceBtwItems),

            // Save Draft Button
            /*Expanded(
              child: OutlinedButton(
                onPressed: controller.saveDraft,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: TSizes.buttonHeight / 2,
                  ),
                  side: BorderSide(color: TColors.warning),
                ),
                child: Text(
                  "حفظ كمسودة",
                  style: TextStyle(color: TColors.warning),
                ),
              ),
            ),
            const SizedBox(width: TSizes.spaceBtwItems),
*/
            // Save Product Button
            Expanded(
              child: ElevatedButton(
                onPressed: isValid ? controller.saveProduct : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: TSizes.buttonHeight / 2,
                  ),
                  backgroundColor: isValid ? TColors.primary : TColors.grey,
                ),
                child: Text(
                  "حفظ المنتج",
                  style: TextStyle(
                    color: isValid ? Colors.white : TColors.darkGrey,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
