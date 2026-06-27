import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/common/widgets/containers/rounded_container.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_addition_controller.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

/// ProductPricingSection - قسم التسعير والمخزون
/// يظهر فقط للمنتجات المفردة، مخفي للمنتجات المتغيرة
class ProductPricingSection extends StatelessWidget {
  const ProductPricingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProductAdditionController.instance;

    return Obx(() {
      // إخفاء القسم للمنتجات المتغيرة
      if (controller.currentProductType == ProductType.variable) {
        return const SizedBox.shrink();
      }

      return TRoundedContainer(
        child: Form(
          key: controller.pricingFormKey,
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
                      borderRadius: BorderRadius.circular(
                        TSizes.borderRadiusMd,
                      ),
                    ),
                    child: Icon(
                      Iconsax.dollar_circle,
                      color: TColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Text(
                    "التسعير والمخزون",
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

              // Pricing Fields
              Row(
                children: [
                  // Regular Price
                  Expanded(
                    child: _buildPriceField(
                      label: "السعر الأساسي",
                      controller: controller.priceController,
                      icon: Iconsax.dollar_circle,
                      isRequired: true,
                      validator: _validatePrice,
                    ),
                  ),

                  const SizedBox(width: TSizes.spaceBtwInputFields),

                  // Sale Price
                  Expanded(
                    child: _buildPriceField(
                      label: "سعر البيع (اختياري)",
                      controller: controller.salePriceController,
                      icon: Iconsax.discount_circle,
                      isRequired: false,
                      validator: _validateSalePrice,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: TSizes.spaceBtwInputFields),

              // Stock and SKU
              Row(
                children: [
                  // Stock
                  Expanded(child: _buildStockField()),

                  const SizedBox(width: TSizes.spaceBtwInputFields),

                  // SKU
                  Expanded(child: _buildSkuField()),
                ],
              ),

              // Pricing Tips
              const SizedBox(height: TSizes.spaceBtwItems),
              _buildPricingTips(),

              // Validation Status
              const SizedBox(height: TSizes.spaceBtwItems),
              Obx(() => _buildValidationStatus()),
            ],
          ),
        ),
      );
    });
  }

  /// بناء حقل السعر
  Widget _buildPriceField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isRequired,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: TColors.textPrimary,
              ),
            ),
            if (isRequired)
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
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            hintText: "0.00",
            prefixIcon: Icon(icon, color: TColors.grey),
            suffixText: "ريال",
            suffixStyle: TextStyle(color: TColors.grey, fontSize: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
              borderSide: BorderSide(color: TColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: validator,
        ),
      ],
    );
  }

  /// بناء حقل المخزون
  Widget _buildStockField() {
    final controller = ProductAdditionController.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "الكمية المتاحة",
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
          controller: controller.stockController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: "0",
            prefixIcon: Icon(Iconsax.box, color: TColors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
              borderSide: BorderSide(color: TColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: _validateStock,
        ),
      ],
    );
  }

  /// بناء حقل SKU
  Widget _buildSkuField() {
    final controller = ProductAdditionController.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "رمز المنتج (SKU)",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: TColors.textPrimary,
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),

        TextFormField(
          controller: controller.skuController,
          decoration: InputDecoration(
            hintText: "مثال: PROD-001",
            prefixIcon: Icon(Iconsax.code, color: TColors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
              borderSide: BorderSide(color: TColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: _validateSku,
        ),
      ],
    );
  }

  /// بناء نصائح التسعير
  Widget _buildPricingTips() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TColors.info.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
        border: Border.all(color: TColors.info.withAlpha((0.3 * 255).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.info_circle, color: TColors.info, size: 16),
              const SizedBox(width: 8),
              Text(
                "نصائح التسعير",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: TColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "• السعر الأساسي هو السعر الذي سيظهر للعملاء\n"
            "• سعر البيع هو السعر المخفض (اختياري)\n"
            "• تأكد من أن سعر البيع أقل من السعر الأساسي\n"
            "• SKU يساعد في تتبع المخزون والمبيعات",
            style: TextStyle(
              fontSize: 12,
              color: TColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء حالة التحقق
  Widget _buildValidationStatus() {
    final controller = ProductAdditionController.instance;
    final isValid = controller.isPricingComplete.value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            isValid ? "بيانات التسعير صحيحة" : "يرجى مراجعة بيانات التسعير",
            style: TextStyle(
              fontSize: 12,
              color: isValid ? TColors.success : TColors.warning,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== VALIDATION METHODS ====================

  /// التحقق من صحة السعر الأساسي
  String? _validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'السعر الأساسي مطلوب';
    }
    final price = double.tryParse(value);
    if (price == null || price <= 0) {
      return 'السعر يجب أن يكون رقماً موجباً';
    }
    if (price > 999999) {
      return 'السعر يجب أن يكون أقل من 1,000,000 ريال';
    }
    return null;
  }

  /// التحقق من صحة سعر البيع
  String? _validateSalePrice(String? value) {
    if (value == null || value.isEmpty) {
      return null; // اختياري
    }
    final salePrice = double.tryParse(value);
    if (salePrice == null || salePrice < 0) {
      return 'سعر البيع يجب أن يكون رقماً موجباً';
    }

    // التحقق من أن سعر البيع أقل من السعر الأساسي
    final controller = ProductAdditionController.instance;
    final regularPrice = double.tryParse(controller.priceController.text) ?? 0;
    if (salePrice >= regularPrice) {
      return 'سعر البيع يجب أن يكون أقل من السعر الأساسي';
    }

    return null;
  }

  /// التحقق من صحة المخزون
  String? _validateStock(String? value) {
    if (value == null || value.isEmpty) {
      return 'الكمية مطلوبة';
    }
    final stock = int.tryParse(value);
    if (stock == null || stock < 0) {
      return 'الكمية يجب أن تكون رقماً صحيحاً موجباً';
    }
    if (stock > 999999) {
      return 'الكمية يجب أن تكون أقل من 1,000,000';
    }
    return null;
  }

  /// التحقق من صحة SKU
  String? _validateSku(String? value) {
    if (value == null || value.isEmpty) {
      return null; // اختياري
    }
    if (value.length > 50) {
      return 'SKU يجب أن يكون أقل من 50 حرف';
    }
    // التحقق من عدم وجود أحرف خاصة محظورة
    if (RegExp(r'[^\w\-]').hasMatch(value)) {
      return 'SKU يجب أن يحتوي على أحرف وأرقام وشرطة فقط';
    }
    return null;
  }
}
