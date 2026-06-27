import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/stor/screens/products/creat_product/widgets/sections/product_attributes.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_addition_controller.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';

/// ProductAttributesSection - قسم إدارة خصائص المنتج
/// يظهر لجميع أنواع المنتجات لإضافة خصائص وصفية أو توليد متغيرات
class ProductAttributesSection extends StatelessWidget {
  const ProductAttributesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProductAdditionController.instance;

    return Obx(() {
      // إظهار القسم للمنتجات المتغيرة فقط
      if (controller.currentProductType == ProductType.variable) {
        return const ProductAttributes();
      }
      return const SizedBox.shrink();
    });
  }
}
