import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/data_table/paginated_data_table.dart';
import 'package:stors_admin_panel/data/stor/screens/dashboard/table/table_source.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class DashboardOrderDataTable extends StatelessWidget {
  const DashboardOrderDataTable({super.key});

  @override
  Widget build(BuildContext context) {
    return TPaginatedDataTable(
      minWidth: 700,
      tableHeight: 500,
      dataRowHeight: TSizes.xl * 1.2,
      columns: [
        DataColumn2(label: Text("رقم الطلب")),
        DataColumn2(label: Text("التاريخ")),
        DataColumn2(label: Text("العناصر")),
        DataColumn2(label: Text("الحالة")),
        DataColumn2(label: Text("السعر")),
      ],
      source: TableSource(),
    );
  }
}
