import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/containers/rounded_container.dart';
import 'package:stors_admin_panel/data/stor/controller/dashboard_controller.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';
import 'package:stors_admin_panel/utils/helpers/helper_functions.dart';

class TableSource extends DataTableSource {
  @override
  DataRow? getRow(int index) {
    final order = DashboardController.instance.allOrders[index];
    return DataRow2(
      cells: [
        DataCell(
          Text(
            "",
            style: Theme.of(
              Get.context!,
            ).textTheme.bodyLarge!.apply(color: TColors.primary),
          ),
        ),
        // const DataCell(Text(order.formattedOrderDate)),
        const DataCell(Text("5 منتجات")),
        DataCell(
          TRoundedContainer(
            radius: TSizes.cardRadiusSm,
            padding: EdgeInsets.symmetric(
              horizontal: TSizes.md,
              vertical: TSizes.xs,
            ),
            backgroundColor: THelperFunctions.getOrderStatusColor(
              order.status,
            ).withAlpha((0.1 * 255).round()),
            child: Text(
              order.status.name.capitalize.toString(),
              style: TextStyle(
                color: THelperFunctions.getOrderStatusColor(order.status),
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            "\$${order.items.fold(0.0, (sum, item) => sum + (item.price * item.quantity))}",
          ),
        ),
      ],
    );
  }

  @override
  // TODO: implement isRowCountApproximate
  bool get isRowCountApproximate => false;

  @override
  // TODO: implement rowCount
  int get rowCount => DashboardController.instance.allOrders.length;

  @override
  // TODO: implement selectedRowCount
  int get selectedRowCount => 0;
}


