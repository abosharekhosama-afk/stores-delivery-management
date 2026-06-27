import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/containers/rounded_container.dart';
import 'package:stors_admin_panel/data/stor/controller/product/all_products_controller.dart';
import 'package:stors_admin_panel/data/stor/screens/products/all_products/table/product_table.dart';
import 'package:stors_admin_panel/data/stor/screens/products/all_products/widgets/TableHeader.dart';
import 'package:stors_admin_panel/routes/routes.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class ProductsDesktop extends StatelessWidget {
  const ProductsDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AllProductsController>();

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /*const BreadcrumbWithHeading(
              heading: "المنتجات",
              breadcrumbItems: ["المنتجات"],
            ),
            //  Text("المنتجات", style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: TSizes.spaceBtwSections),
*/
            TRoundedContainer(
              child: Column(
                children: [
                  Obx(
                    () => Tableheader(
                      buttonText: "منتج جديد",
                      onPressed: () => Get.toNamed(TRoutes.createProduct),
                      searchController: controller.searchTextController,
                      focusNode: controller.searchFocusNode,
                      showClear: controller.showClearButton.value,
                      onSearchSubmit: () => controller.triggerSearch(),
                      onClearPressed: () => controller.clearSearch(),
                      //searchOnChanged: (val) => controller.searchOnChanged(val),
                    ),
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),
                  ProductTable(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
