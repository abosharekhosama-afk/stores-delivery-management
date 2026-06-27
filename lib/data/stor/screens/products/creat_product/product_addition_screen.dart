import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/responsive/responsive_design.dart';
import 'package:stors_admin_panel/data/stor/screens/products/creat_product/responsive_screen/create_product_desktop.dart';
import 'package:stors_admin_panel/data/stor/screens/products/creat_product/responsive_screen/create_product_mobile.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_addition_controller.dart';

class ProductAdditionScreen extends StatelessWidget {
  const ProductAdditionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ProductAdditionController());

    return TResponsiveDesign(
      desktop: CreateProductDesktop(),
      tablet: CreateProductDesktop(),
      mobile: CreateProductMobile(),
    );
  }
}
