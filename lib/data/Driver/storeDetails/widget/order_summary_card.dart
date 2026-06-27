import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/Driver/controller/store_orders_detail_controller.dart';
import 'package:stors_admin_panel/data/Driver/storeDetails/widget/orderItems_checklist_sheet.dart';
import 'package:stors_admin_panel/data/stor/models/store_orders_model.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';

class OrderSummaryCard extends StatelessWidget {
  final StoreOrdersModel order;
  final StoreOrdersDetailsController controller;

  const OrderSummaryCard({
    super.key,
    required this.order,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // حساب نسبة الإنجاز
    int totalItems = order.items.length;
    int pickedItems = order.items
        .where((i) => i.itemStatus == ItemStatus.shipped)
        .length;
    double progress = totalItems > 0 ? pickedItems / totalItems : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () =>
            _openItemsChecklist(context, order), // هنا نفتح تفاصيل العناصر
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "طلب #${order.storeOrderId}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildStatusBadge(progress),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "$totalItems عناصر في هذا الطلب",
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                color: progress == 1.0 ? Colors.green : Colors.blue,
                backgroundColor: Colors.grey[200],
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openItemsChecklist(BuildContext context, StoreOrdersModel order) {
    // سنستخدم Bottom Sheet لعرض العناصر بطريقة عصرية
    Get.bottomSheet(
      OrderItemsChecklistSheet(storeOrder: order, storeId: order.storeId),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  Widget _buildStatusBadge(double progress) {
    bool isDone = progress == 1.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDone
            ? Colors.green.withAlpha((0.1 * 255).round())
            : Colors.orange.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isDone ? "مكتمل" : "قيد الفحص",
        style: TextStyle(
          color: isDone ? Colors.green : Colors.orange,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
