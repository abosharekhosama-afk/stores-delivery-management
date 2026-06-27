import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stors_admin_panel/common/widgets/icons/table_action_icon_buttons.dart';
import 'package:stors_admin_panel/data/stor/models/product_model.dart';
import 'package:stors_admin_panel/routes/routes.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/image_strings.dart'; // تأكد من وجود Placeholder هنا
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class ProductTableSource extends DataTableSource {
  final List<ProductModel> products;
  final BuildContext context;

  ProductTableSource(this.products, this.context);

  @override
  DataRow? getRow(int index) {
    if (index >= products.length) return null;
    final product = products[index];

    return DataRow2(
      cells: [
        DataCell(
          Row(
            children: [
              // عرض الصورة مع Shimmer و Placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
                child: Image.network(
                  product.thumbnail,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 50,
                            height: 50,
                            color: Colors.white,
                          ),
                        ),
                  errorBuilder: (_, __, ___) => Image.asset(
                    TImages.productImage1,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Flexible(
                child: Text(
                  product.title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.apply(color: TColors.primary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(product.stock.toString())),
        DataCell(Text(product.brande?.name ?? 'بدون علامة')),
        DataCell(Text('\$${product.price}')),
        DataCell(
          Text(
            product.date != null
                ? "${product.date!.day}/${product.date!.month}/${product.date!.year}"
                : 'غير محدد',
          ),
        ),
        DataCell(
          TTableActionButtons(
            onEditPressed: () =>
                Get.toNamed(TRoutes.editProduct, arguments: product),
            onDeletePressed: () {}, // أضف منطق الحذف هنا
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => products.length;
  @override
  int get selectedRowCount => 0;
}
