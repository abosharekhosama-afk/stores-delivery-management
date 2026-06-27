import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/stor/screens/products/creat_product/widgets/sections/product_variations.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_addition_controller.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';

/// ProductVariationsSection - قسم إدارة متغيرات المنتج
/// يظهر فقط للمنتجات المتغيرة لإضافة متغيرات متعددة
class ProductVariationsSection extends StatelessWidget {
  const ProductVariationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProductAdditionController.instance;

    return Obx(() {
      // إظهار القسم للمنتجات المتغيرة فقط
      if (controller.currentProductType == ProductType.variable) {
        return const ProductVariations();
      }
      return const SizedBox.shrink();
    });
  }
}
