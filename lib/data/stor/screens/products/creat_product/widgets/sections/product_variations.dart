import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/containers/rounded_container.dart';
import 'package:stors_admin_panel/common/widgets/images/t_rounded_image.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_variation_controller.dart';
import 'package:stors_admin_panel/data/stor/models/product_variation_model.dart';
import 'package:stors_admin_panel/data/stor/screens/products/creat_product/widgets/sections/variation_image_upload.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_addition_controller.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/constants/image_strings.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class ProductVariations extends StatelessWidget {
  const ProductVariations({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductVariationController());
    return Obx(
      () =>
          ProductAdditionController.instance.currentProductType ==
              ProductType.variable
          ? TRoundedContainer(
              padding: EdgeInsets.symmetric(
                vertical: TSizes.md,
                horizontal: TSizes.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "خصائص المنتج",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      TextButton(
                        onPressed: () => controller.removeVariations(context),
                        child: const Text("حذف الخصائص"),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  // --- الخطوة الجديدة: أداة التعديل الجماعي السريع ---
                  if (controller.productVariation.isNotEmpty)
                    TRoundedContainer(
                      showBorder: true,
                      backgroundColor: TColors.primary.withAlpha(
                        (0.1 * 255).round(),
                      ),
                      padding: const EdgeInsets.all(TSizes.md),
                      margin: const EdgeInsets.only(
                        bottom: TSizes.spaceBtwSections,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "تعديل جماعي سريع (سيتم التطبيق على كافة المقاسات والألوان)",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: TSizes.spaceBtwItems),
                          Row(
                            children: [
                              // حقل السعر للكل
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: "السعر للكل",
                                    prefixIcon: Icon(
                                      Icons.monetization_on_outlined,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) =>
                                      controller.applyPriceToAll(value),
                                ),
                              ),
                              const SizedBox(width: TSizes.md),
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: "سعر الخصم للكل",
                                    prefixIcon: Icon(Icons.discount_outlined),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) =>
                                      controller.applySalePriceToAll(value),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: TSizes.spaceBtwItems),

                          Row(
                            children: [
                              // حقل المخزون للكل
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: "المخزون للكل",
                                    prefixIcon: Icon(
                                      Icons.inventory_2_outlined,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) =>
                                      controller.applyStockToAll(value),
                                ),
                              ),
                              const SizedBox(width: TSizes.md),
                              // حقل الوصف للكل
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: "معرف المنتج للكل",
                                    prefixIcon: Icon(
                                      Icons.confirmation_num_outlined,
                                    ),
                                  ),
                                  onChanged: (value) =>
                                      controller.applySKUToAll(value),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: TSizes.spaceBtwItems),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: "وصف موجز للكل",
                              prefixIcon: Icon(Icons.description_outlined),
                            ),
                            onChanged: (value) =>
                                controller.applyDescriptionToAll(value),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: TSizes.spaceBtwItems),

                  if (controller.productVariation.isNotEmpty)
                    ListView.separated(
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: controller.productVariation.length,
                      shrinkWrap: true,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: TSizes.spaceBtwItems / 2),
                      itemBuilder: (context, index) {
                        final variation = controller.productVariation[index];
                        return _buildVariationTile(
                          context,
                          index,
                          variation,
                          controller,
                          ValueKey(variation.id),
                        );
                      },
                    )
                  else
                    _buildNoVariationMessage(),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildVariationTile(
    BuildContext context,
    int index,
    ProductVariationModel variation,
    ProductVariationController controller,
    Key? key,
  ) {
    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: TSizes.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        side: BorderSide(
          color: TColors.borderPrimary.withAlpha((0.3 * 255).round()),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: TSizes.md,
            vertical: 0,
          ),
          backgroundColor: TColors.white,
          collapsedBackgroundColor: Colors.white,
          //childrenPadding: const EdgeInsets.all(TSizes.md),

          // العنوان الآن سيستجيب للتحديثات بفضل عمل refresh للقائمة
          title: Row(
            children: [
              Expanded(
                child: Text(
                  variation.attributeValues.entries
                      .map((e) => e.value)
                      .join(" - "),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                "${variation.price} \$",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: TColors.primary,
                ),
              ),
              const SizedBox(width: TSizes.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: variation.stock > 0
                      ? Colors.green.withAlpha((0.1 * 255).round())
                      : Colors.red.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "مخزون: ${variation.stock}",
                  style: TextStyle(
                    fontSize: TSizes.sm,
                    color: variation.stock > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),

              IconButton(
                onPressed: () => controller.removeVariationAt(index),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: VariationImageUpload(variation: variation),
                ),
                const SizedBox(width: TSizes.spaceBtwItems / 2),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          // حقل السعر مع تحديث الواجهة
                          Expanded(
                            child: _buildCompactTextField(
                              controller: controller
                                  .priceControllerList[index][variation]!,
                              label: "السعر",
                              onChanged: (v) {
                                variation.price = double.tryParse(v) ?? 0.0;
                                controller.productVariation
                                    .refresh(); // تحديث العنوان فوراً
                              },
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: TSizes.sm),
                          // حقل السعر بعد الخصم
                          Expanded(
                            child: _buildCompactTextField(
                              controller: controller
                                  .salePriceControllerList[index][variation]!,
                              label: "سعر الخصم",
                              onChanged: (v) {
                                variation.salePrice = double.tryParse(v) ?? 0.0;
                                controller.productVariation.refresh();
                              },
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: TSizes.sm),
                          // حقل المخزون مع تحديث حالة اللون في العنوان
                          Expanded(
                            child: _buildCompactTextField(
                              controller: controller
                                  .stockControllerList[index][variation]!,
                              label: "المخزون",
                              onChanged: (v) {
                                variation.stock = int.tryParse(v) ?? 0;
                                controller.productVariation
                                    .refresh(); // لتحديث لون ومص القيمة في العنوان
                              },
                              isNumber: true,
                              onlyDigits: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TSizes.sm),
                      _buildCompactTextField(
                        controller: controller
                            .descriptionControllerList[index][variation]!,
                        label: "وصف موجز للخاصية",
                        onChanged: (v) => variation.description = v,
                      ),
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

  /*
  Widget _buildVariationTile(
    BuildContext context,
    int index,
    ProductVariationModel variation,
    ProductVariationController controller,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: TSizes.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        side: BorderSide(color: TColors.borderPrimary.withAlpha((0.3 * 255).round())),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: TSizes.md,
            vertical: 0,
          ),
          backgroundColor: TColors.white,
          collapsedBackgroundColor: Colors.white,
          childrenPadding: const EdgeInsets.all(TSizes.md),
          // عرض تفاصيل سريعة في العنوان (العنوان + السعر + المخزون)
          title: Row(
            children: [
              Expanded(
                child: Text(
                  variation.attributeValues.entries
                      .map((e) => "${e.value}")
                      .join(" - "),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                "${variation.price} \$",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: TColors.primary,
                ),
              ),
              const SizedBox(width: TSizes.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: variation.stock > 0
                      ? Colors.green.withAlpha((0.1 * 255).round())
                      : Colors.red.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "مخزون: ${variation.stock}",
                  style: TextStyle(
                    fontSize: TSizes.xs,
                    color: variation.stock > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // منطقة الصورة (مدمجة)
                SizedBox(
                  width: 100,
                  child: VariationImageUpload(variation: variation),
                ),
                const SizedBox(width: TSizes.spaceBtwItems),

                // الحقول النصية (موزعة أفقياً)
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // حقل السعر
                          Expanded(
                            child: _buildCompactTextField(
                              controller: controller
                                  .priceControllerList[index][variation]!,
                              label: "السعر",
                              onChanged: (v) =>
                                  variation.price = double.tryParse(v) ?? 0.0,
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: TSizes.sm),
                          // حقل السعر بعد الخصم
                          Expanded(
                            child: _buildCompactTextField(
                              controller: controller
                                  .salePriceControllerList[index][variation]!,
                              label: "سعر الخصم",
                              onChanged: (v) => variation.salePrice =
                                  double.tryParse(v) ?? 0.0,
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: TSizes.sm),
                          // حقل المخزون
                          Expanded(
                            child: _buildCompactTextField(
                              controller: controller
                                  .stockControllerList[index][variation]!,
                              label: "المخزون",
                              onChanged: (v) =>
                                  variation.stock = int.tryParse(v) ?? 0,
                              isNumber: true,
                              onlyDigits: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TSizes.sm),
                      // حقل الوصف
                      _buildCompactTextField(
                        controller: controller
                            .descriptionControllerList[index][variation]!,
                        label: "وصف موجز للخاصية",
                        onChanged: (v) => variation.description = v,
                      ),
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
*/
  // ويدجت مساعد لإنشاء حقول نصية مدمجة لتقليل تكرار الكود
  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required Function(String) onChanged,
    bool isNumber = false,
    bool onlyDigits = false,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: [
        if (onlyDigits) FilteringTextInputFormatter.digitsOnly,
        if (isNumber && !onlyDigits)
          FilteringTextInputFormatter.allow(RegExp(r'^\d+.?\d{0,2}$')),
      ],
      decoration: InputDecoration(
        isDense: true, // يجعل الحقل مدمجاً
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: TColors.grey.withAlpha((0.5 * 255).round()),
          ),
        ),
      ),
    );
  }

  /*
  Widget _buildVariationTile(
    BuildContext context,
    int index,
    ProductVariationModel variation,
    ProductVariationController controller,
  ) {
    return ExpansionTile(
      backgroundColor: TColors.lightGrey,
      collapsedBackgroundColor: TColors.lightGrey,
      childrenPadding: const EdgeInsets.all(TSizes.md),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
      ),

      title: Text(
        variation.attributeValues.entries
            .map((e) => "${e.key} : ${e.value}")
            .join(", "),
      ),
      children: [
        Row(
          children: [
            VariationImageUpload(variation: variation),
            const SizedBox(width: TSizes.spaceBtwInputFields),
            Flexible(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller:
                              controller.priceControllerList[index][variation],
                          onChanged: (value) =>
                              variation.price = double.tryParse(value) ?? 0.0,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+.?\d{0,2}$'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: "السعر",
                            hintText: "اضف السعر مع بشكل عشري",
                            hintStyle: TextStyle(fontSize: TSizes.sm),
                          ),
                        ),
                      ),
                      const SizedBox(width: TSizes.spaceBtwInputFields / 2),
                      Expanded(
                        child: TextFormField(
                          controller: controller
                              .salePriceControllerList[index][variation],
                          onChanged: (value) => variation.salePrice =
                              double.tryParse(value) ?? 0.0,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+.?\d{0,2}$'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: "السعر بعد الخصم",
                            hintText: "اضف السعر مع بشكل عشري",
                            hintStyle: TextStyle(fontSize: TSizes.sm),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.spaceBtwInputFields / 2),

                  TextFormField(
                    controller:
                        controller.stockControllerList[index][variation],
                    onChanged: (value) =>
                        variation.stock = int.tryParse(value) ?? 0,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: "المخزون",
                      hintText: "اضف العدد الفعلى للمخزون",
                      hintStyle: TextStyle(fontSize: TSizes.sm),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwInputFields),

        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller:
                    controller.descriptionControllerList[index][variation],
                onChanged: (value) => variation.description = value,
                decoration: const InputDecoration(
                  labelText: "الوصف",
                  hintText: "...اضف وصف لهذاه الخاصية",
                ),
              ),
            ),
          ],
        ),

        /*VariationImageUpload(variation: variation),
        const SizedBox(height: TSizes.spaceBtwInputFields),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller.stockControllerList[index][variation],
                onChanged: (value) =>
                    variation.stock = int.tryParse(value) ?? 0,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: "المخزون",
                  hintText: "اضف العدد الفعلى للمخزون",
                  hintStyle: TextStyle(fontSize: TSizes.sm),
                ),
              ),
            ),

            const SizedBox(width: TSizes.spaceBtwInputFields),
            Expanded(
              child: TextFormField(
                controller: controller.priceControllerList[index][variation],
                onChanged: (value) =>
                    variation.price = double.tryParse(value) ?? 0.0,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+.?\d{0,2}$')),
                ],
                decoration: const InputDecoration(
                  labelText: "السعر",
                  hintText: "اضف السعر مع بشكل عشري",
                  hintStyle: TextStyle(fontSize: TSizes.sm),
                ),
              ),
            ),
            const SizedBox(width: TSizes.spaceBtwInputFields),
            Expanded(
              child: TextFormField(
                controller:
                    controller.salePriceControllerList[index][variation],
                onChanged: (value) =>
                    variation.salePrice = double.tryParse(value) ?? 0.0,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+.?\d{0,2}$')),
                ],
                decoration: const InputDecoration(
                  labelText: "السعر بعد الخصم",
                  hintText: "اضف السعر مع بشكل عشري",
                  hintStyle: TextStyle(fontSize: TSizes.sm),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwInputFields),

        TextFormField(
          controller: controller.descriptionControllerList[index][variation],
          onChanged: (value) => variation.description = value,
          decoration: const InputDecoration(
            labelText: "الوصف",
            hintText: "...اضف وصف لهذاه الخاصية",
          ),
        ),
      */
      ],
    );
  }
*/
  Widget _buildNoVariationMessage() {
    return const Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TRoundedImage(
              width: 200,
              height: 200,
              imageType: ImageType.asset,
              image: TImages.defaultVariationImageIcon,
            ),
          ],
        ),
        SizedBox(height: TSizes.spaceBtwItems),
        Text("لا يوجد متغيرات اضف لهذا المنتج"),
      ],
    );
  }
}
