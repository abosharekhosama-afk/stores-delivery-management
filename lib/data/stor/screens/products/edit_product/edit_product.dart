import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/responsive/responsive_design.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_addition_controller.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_image_controller.dart';
import 'package:stors_admin_panel/data/stor/screens/products/edit_product/responsive_screen/edit_product_desktop.dart';
import 'package:stors_admin_panel/data/stor/screens/products/edit_product/responsive_screen/edit_product_mobile.dart';

class EditProduct extends StatelessWidget {
  const EditProduct({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ProductAdditionController());
    Get.put(ProductImageController());

    return TResponsiveDesign(
      desktop: EditProductDesktop(),
      tablet: EditProductDesktop(),
      mobile: EditProductMobile(),
    );
  }
}
