import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/Driver/controller/store_orders_detail_controller.dart';
import 'package:stors_admin_panel/data/Driver/storeDetails/widget/order_summary_card.dart';

class StoreOrdersDetailsScreen extends StatelessWidget {
  final String storeId;
  final String storeName;

  const StoreOrdersDetailsScreen({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  Widget build(BuildContext context) {
    // حقن الكنترولر وتمرير الـ storeId
    final controller = Get.put(
      StoreOrdersDetailsController(storeId),
      tag: storeId,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          storeName,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Obx(() {
        // if (controller.isLoading.value)
        // return const Center(child: CircularProgressIndicator());

        if (controller.orders.isEmpty) {
          return const Center(
            child: Text("لا توجد طلبات جاهزة للاستلام حالياً"),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.orders.length,
          itemBuilder: (context, index) {
            final order = controller.orders[index];
            // نقوم باستدعاء ويدجت البطاقة الذكية التي صممناها
            return OrderSummaryCard(order: order, controller: controller);
          },
        );
      }),
    );
  }
}
