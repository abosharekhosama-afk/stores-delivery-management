import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stors_admin_panel/common/widgets/data_table/paginated_data_table.dart';
import 'package:stors_admin_panel/data/stor/controller/product/all_products_controller.dart';
import 'package:stors_admin_panel/data/stor/screens/products/all_products/table/table_source.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class ProductTable extends StatelessWidget {
  const ProductTable({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AllProductsController>();

    return Obx(() {
      // Shimmer عند التحميل الأول فقط والقائمة فارغة
      if (controller.isLoading.value && controller.products.isEmpty) {
        return buildTableShimmer();
      }

      return TPaginatedDataTable(
        minWidth: 1000,
        rowsPerPage: controller.rowsPerPage,
        onPageChanged: (pageIndex) => controller.refreshProducts(),
        columns: const [
          DataColumn2(label: Text("المنتج")),
          DataColumn2(label: Text("المخزون")),
          DataColumn2(label: Text("البراند")),
          DataColumn2(label: Text("السعر")),
          DataColumn2(label: Text("التاريخ")),
          DataColumn2(label: Text("الحدث")),
        ],
        source: ProductTableSource(controller.filteredProducts, context),
      );
    });
  }

  Widget buildTableShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(
          10,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: TSizes.spaceBtwItems),
            child: Container(
              height: 50,
              width: double.infinity,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
