import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/common/widgets/containers/rounded_container.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_addition_controller.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class BasicInfoSection extends StatelessWidget {
  const BasicInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductAdditionController>();

    return TRoundedContainer(
      child: Form(
        key: controller.basicInfoFormKey,
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
                    Iconsax.document_text,
                    color: TColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems),
                Text(
                  "المعلومات الأساسية",
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

            // Product Title Field
            _buildTitleField(),
            const SizedBox(height: TSizes.spaceBtwInputFields),

            // Product Description Field
            _buildDescriptionField(),

            // Validation Status
            const SizedBox(height: TSizes.spaceBtwItems),
            Obx(() {
              final title = controller.product.value.title;
              final description = controller.product.value.description ?? '';
              final isValid =
                  title.isNotEmpty &&
                  title.length >= 3 &&
                  title.length <= 100 &&
                  description.isNotEmpty &&
                  description.length >= 10 &&
                  description.length <= 1000;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
                      isValid
                          ? "جميع الحقول صحيحة"
                          : "يرجى مراجعة الحقول المطلوبة",
                      style: TextStyle(
                        fontSize: 12,
                        color: isValid ? TColors.success : TColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    final controller = ProductAdditionController.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "اسم المنتج",
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

        TextFormField(
          controller: controller.titleController,
          decoration: InputDecoration(
            hintText: "أدخل اسم المنتج",
            prefixIcon: Icon(Iconsax.text, color: TColors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
              borderSide: BorderSide(color: TColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            counterText: "",
          ),
          maxLength: 100,
          validator: controller.validateTitle,
          onChanged: controller.updateTitle,
          textInputAction: TextInputAction.next,
        ),

        // Character counter
        Obx(() {
          final length = controller.product.value.title.length;
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "$length/100 حرف",
              style: TextStyle(
                fontSize: 12,
                color: length > 90 ? TColors.warning : TColors.grey,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDescriptionField() {
    final controller = ProductAdditionController.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "وصف المنتج",
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

        TextFormField(
          controller: controller.descriptionController,
          decoration: InputDecoration(
            hintText: "أدخل وصف مفصل للمنتج",
            prefixIcon: Icon(Iconsax.document_text, color: TColors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
              borderSide: BorderSide(color: TColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            alignLabelWithHint: true,
          ),
          maxLength: 1000,
          maxLines: 4,
          validator: controller.validateDescription,
          onChanged: controller.updateDescription,
          textInputAction: TextInputAction.newline,
        ),

        // Character counter
        Obx(() {
          final length = controller.product.value.description?.length ?? 0;
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "$length/1000 حرف",
              style: TextStyle(
                fontSize: 12,
                color: length > 900 ? TColors.warning : TColors.grey,
              ),
            ),
          );
        }),
      ],
    );
  }
}


