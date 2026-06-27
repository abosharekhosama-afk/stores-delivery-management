import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/containers/circular_container.dart';
import 'package:stors_admin_panel/data/stor/controller/dashboard_controller.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';
import 'package:stors_admin_panel/utils/helpers/helper_functions.dart';

class OrderStatusPieChart extends StatelessWidget {
  const OrderStatusPieChart({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = DashboardController.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("حالة الطلبات", style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: TSizes.spaceBtwSections),

        SizedBox(
          height: 400,
          child: PieChart(
            PieChartData(
              sectionsSpace: 1.0,
              sections: controller.orderStatusData.entries.map((entry) {
                final status = entry.key;
                final count = entry.value;
                return PieChartSectionData(
                  showTitle: true,
                  title: count.toString(),
                  value: count.toDouble(),
                  radius: 100,
                  color: THelperFunctions.getOrderStatusColor(status),
                  titleStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {},
                enabled: true,
              ),
            ),
          ),
        ),

        SizedBox(
          width: double.infinity,
          child: DataTable(
            columns: [
              DataColumn(label: Text("الحالة")),
              DataColumn(label: Text("الطلبات")),
              DataColumn(label: Text("اجمالي")),
            ],
            rows: controller.orderStatusData.entries.map((entry) {
              final OrderStatus status = entry.key;
              final int count = entry.value;
              final totalAmount = controller.totalAmount[status] ?? 0;

              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        TCircularContainer(
                          width: 20,
                          height: 20,
                          backgroundColor: THelperFunctions.getOrderStatusColor(
                            status,
                          ),
                        ),
                        Expanded(
                          child: Text(controller.getDisplayStatusName(status)),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(count.toString())),
                  DataCell(Text("\$${totalAmount.toStringAsFixed(2)}")),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
