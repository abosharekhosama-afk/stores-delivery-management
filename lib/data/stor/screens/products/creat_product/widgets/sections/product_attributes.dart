import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/common/widgets/containers/rounded_container.dart';
import 'package:stors_admin_panel/common/widgets/images/t_rounded_image.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_attributes_controller.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_addition_controller.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_variation_controller.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/constants/image_strings.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';
import 'package:stors_admin_panel/utils/device/device_utility.dart';
import 'package:stors_admin_panel/utils/validators/validation.dart';

class ProductAttributes extends StatelessWidget {
  const ProductAttributes({super.key});

  @override
  Widget build(BuildContext context) {
    final productAttributesController = Get.put(ProductAttributesController());
    final productVariationController = Get.put(ProductVariationController());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: TColors.primaryBackground),
        const SizedBox(height: TSizes.spaceBtwSections),

        Text(
          "اضف عناصر المنتج",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: TSizes.spaceBtwItems),

        Form(
          key: productAttributesController.attributesFormKey,
          child: TDeviceUtils.isDesktopScreen(context)
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildAttributeName(productAttributesController),
                    ),
                    const SizedBox(width: TSizes.spaceBtwItems),
                    Expanded(
                      flex: 2,
                      child: _buildAttributeTextField(
                        productAttributesController,
                      ),
                    ),
                    const SizedBox(width: TSizes.spaceBtwItems),
                    _buildAttributeButton(productAttributesController),
                  ],
                )
              : Column(
                  children: [
                    _buildAttributeName(productAttributesController),
                    const SizedBox(height: TSizes.spaceBtwItems),
                    _buildAttributeTextField(productAttributesController),
                    const SizedBox(height: TSizes.spaceBtwItems),
                    _buildAttributeButton(productAttributesController),
                  ],
                ),
        ),
        const SizedBox(width: TSizes.spaceBtwSections),

        Text("جميع الخيارات", style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(width: TSizes.spaceBtwItems),

        TRoundedContainer(
          backgroundColor: TColors.primaryBackground,
          child: Column(
            children: [
              Obx(
                () => productAttributesController.productAttributes.isNotEmpty
                    ? buildAttributelist(context, productAttributesController)
                    : buildEmptyAttributes(),
              ),
            ],
          ),
        ),
        const SizedBox(width: TSizes.spaceBtwSections),

        Obx(
          () =>
              ProductAdditionController.instance.currentProductType ==
                      ProductType.variable &&
                  productVariationController.productVariation.isEmpty
              ? Center(
                  child: SizedBox(
                    width: 200,
                    child: ElevatedButton.icon(
                      onPressed: () => productVariationController
                          .generateVariationConfirmation(context),
                      label: const Text("توليد خيار"),
                      icon: const Icon(Iconsax.activity),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  TextFormField _buildAttributeName(ProductAttributesController controller) {
    return TextFormField(
      controller: controller.attributeName,
      validator: (value) => TValidator.validateEmptyText("اسم الخيار", value),
      decoration: const InputDecoration(
        labelText: "اسم الخيار",
        hintText: "الاوان, المقاس, الخامات",
      ),
    );
  }

  SizedBox _buildAttributeTextField(ProductAttributesController controller) {
    return SizedBox(
      height: 80,
      child: TextFormField(
        controller: controller.attribute,
        expands: true,
        maxLines: null,
        textAlign: TextAlign.start,
        keyboardType: TextInputType.multiline,
        textAlignVertical: TextAlignVertical.top,
        validator: (value) => TValidator.validateEmptyText("حقل الخيار", value),
        decoration: const InputDecoration(
          labelText: "الخيارات",
          hintText: "اضف فاصل بين الخيارات مثل احمر | اخضر | ازرق",
          alignLabelWithHint: true,
        ),
      ),
    );
  }

  SizedBox _buildAttributeButton(ProductAttributesController controller) {
    return SizedBox(
      width: 100,
      child: ElevatedButton.icon(
        onPressed: () => controller.addNewAttribute(),
        icon: const Icon(Iconsax.add),
        style: ElevatedButton.styleFrom(
          foregroundColor: TColors.black,
          backgroundColor: TColors.secondary,
          side: const BorderSide(color: TColors.secondary),
        ),
        label: const Text("اضافة"),
      ),
    );
  }

  ListView buildAttributelist(
    BuildContext context, // تم تصحيح الكتابة من contex
    ProductAttributesController controller,
  ) {
    return ListView.separated(
      itemCount: controller.productAttributes.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) =>
          const SizedBox(height: TSizes.spaceBtwItems),
      itemBuilder: (context, index) {
        final attribute = controller.productAttributes[index];
        return Container(
          padding: const EdgeInsets.all(TSizes.md),
          decoration: BoxDecoration(
            color: TColors.white,
            borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
            border: Border.all(
              color: TColors.grey.withAlpha((0.3 * 255).round()),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رأس العنصر: اسم الخاصية وزر الحذف
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    attribute.name ?? "",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => controller.removeAttribute(index, context),
                    icon: const Icon(
                      Iconsax.trash,
                      color: TColors.error,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TSizes.sm),

              // عرض القيم بشكل Chips مع دعم الصور
              Wrap(
                spacing: TSizes.sm,
                runSpacing: TSizes.sm,
                children: attribute.values!.map((value) {
                  final trimValue = value.trim();

                  return Obx(() {
                    // التحقق مما إذا كانت القيمة تمتلك صورة مسبقاً
                    final hasImage = controller.attributeValueImages
                        .containsKey(trimValue);
                    final imageBytes =
                        controller.attributeValueImages[trimValue];

                    return ActionChip(
                      onPressed: () =>
                          controller.pickImageForAttributeValue(trimValue),
                      padding: const EdgeInsets.all(TSizes.xs),
                      backgroundColor: hasImage
                          ? TColors.primary.withAlpha((0.1 * 255).round())
                          : TColors.light,
                      avatar: hasImage
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: _buildImageWidget(imageBytes),
                            )
                          : const Icon(Iconsax.camera, size: 16),
                      label: Text(trimValue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          TSizes.borderRadiusMd,
                        ),
                      ),
                    );
                  });
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  /*
  ListView buildAttributelist(
    BuildContext contex,
    ProductAttributesController controller,
  ) {
    return ListView.separated(
      itemCount: controller.productAttributes.length,
      shrinkWrap: true,
      separatorBuilder: (context, index) =>
          const SizedBox(height: TSizes.spaceBtwItems),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: TColors.white,
            borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
          ),
          child: ListTile(
            title: Text(controller.productAttributes[index].name ?? ""),
            subtitle: Text(
              controller.productAttributes[index].values!
                  .map((e) => e.trim())
                  .join(', '),
            ),
            trailing: IconButton(
              onPressed: () => controller.removeAttribute(index, context),
              icon: const Icon(Iconsax.trash, color: TColors.error),
            ),
          ),
        );
      },
    );
  }
*/
  Column buildEmptyAttributes() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: TRoundedImage(
            width: 150,
            height: 80,
            imageType: ImageType.asset,
            image: TImages.defaultAttributeColorsImageIcon,
          ),
        ),
        SizedBox(height: TSizes.spaceBtwItems),
        Text("لا يوجد خيارات لهذا المنتج اضف للمنتج"),
      ],
    );
  }

  Widget _buildImageWidget(dynamic imageSource) {
    if (imageSource is Uint8List) {
      return Image.memory(
        imageSource,
        width: 25,
        height: 25,
        fit: BoxFit.cover,
      );
    } else if (imageSource is String) {
      // عرض الصورة من الرابط (استخدم CachedNetworkImage إذا كان متوفراً)
      return TRoundedImage(
        padding: 0.0,
        imageType: ImageType.network,
        image: imageSource,
        width: 25,
        height: 25,
        fit: BoxFit.cover,
      );
    }
    return const Icon(Iconsax.image);
  }
}
