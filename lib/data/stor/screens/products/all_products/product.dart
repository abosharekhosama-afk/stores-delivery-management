import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/responsive/responsive_design.dart';
import 'package:stors_admin_panel/data/stor/controller/product/all_products_controller.dart';
import 'package:stors_admin_panel/data/stor/screens/products/all_products/responsiv_screens/product_mobile.dart';
import 'package:stors_admin_panel/data/stor/screens/products/all_products/responsiv_screens/product_tablit.dart';
import 'package:stors_admin_panel/data/stor/screens/products/all_products/responsiv_screens/products_desktop.dart';

class AllProduct extends StatelessWidget {
  const AllProduct({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => AllProductsController());
    return TResponsiveDesign(
      desktop: ProductsDesktop(),
      tablet: ProductTablit(),
      mobile: ProductMobile(),
    );
  }
}
