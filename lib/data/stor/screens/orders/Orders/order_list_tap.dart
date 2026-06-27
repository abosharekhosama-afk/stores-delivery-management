import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/shimmers/TOrderCardShimmer.dart';
import 'package:stors_admin_panel/data/reposity/repositories.authentication/authentication_repository.dart';
import 'package:stors_admin_panel/data/stor/controller/store_order_controller.dart';
import 'package:stors_admin_panel/data/stor/models/store_orders_model.dart';
import 'package:stors_admin_panel/data/stor/screens/orders/Orders/order_detail_screen.dart'; // تأكد من المسار
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class OrderListTab extends StatelessWidget {
  final String statusTab;
  const OrderListTab({super.key, required this.statusTab});

  @override
  Widget build(BuildContext context) {
    final controller = StoreOrderController.instance;

    return Obx(() {
      // 1. إذا كان التطبيق يقوم بالبحث في الفايربيز حالياً، اعرض مؤشر التحميل الخاص بالبحث
      if (controller.isSearchingFirebase.value) {
        return const Center(
          child: CircularProgressIndicator(color: TColors.primary),
        );
      }

      // اختيار القائمة الصحيحة بناءً على التبويب

      List<StoreOrdersModel> orders = _getFilteredOrders(controller, statusTab);
      if (controller.isLoading.value) {
        return ListView.builder(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          itemCount: 8, // عدد البطاقات الوهمية
          itemBuilder: (_, __) => const TOrderCardShimmer(),
        );
      }
      // 3. التحقق من خلو البيانات
      if (orders.isEmpty) {
        return Center(
          child: Text(
            controller.isUserSearchingNow.value
                ? "لا توجد نتائج مطابقة في هذا القسم"
                : "لا توجد طلبات في هذا القسم",
            style: const TextStyle(fontSize: 15, color: Colors.grey),
          ),
        );
      }

      // استبدل الـ ListView.builder في ملف order_list_tab.dart
      return RefreshIndicator(
        onRefresh: () => controller.fetchInitialOrders(
          AuthenticationRepository.instance.authUser!.uid,
        ),
        child: ListView.builder(
          controller: controller.scrollController, // ربط الكنترولر هنا
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          physics:
              const AlwaysScrollableScrollPhysics(), // لضمان عمل الـ RefreshIndicator حتى لو كانت القائمة قصيرة
          itemCount: orders.length + (controller.isMoreLoading.value ? 1 : 0),
          itemBuilder: (_, index) {
            if (index < orders.length) {
              final order = orders[index];
              return TOrderCard(order); // ويدجت الكارد الخاص بك
            } else {
              return const Padding(
                padding: EdgeInsets.all(10),
                child: Center(child: CircularProgressIndicator()),
              );
            }
          },
        ),
      );

      /* return ListView.builder(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        itemCount: orders.length,
        itemBuilder: (_, index) {
          final order = orders[index];
          return TDelayedSlideIn(
            delayInMilliseconds: 300 + (index * 100),
            child: GestureDetector(
              onTap: () => Get.to(() => OrderDetailScreen(order: order)),
              child: Container(
                margin: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
                padding: const EdgeInsets.all(TSizes.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha((0.1 * 255).round()),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // أيقونة ملونة حسب الحالة
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: TColors.primary.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: TColors.primary,
                      ),
                    ),
                    const SizedBox(width: TSizes.spaceBtwItems),

                    // بيانات الطلب
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "طلب #${order.mainOrderId}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${order.orderDate.toString().split(' ')[0]} • ${order.items.length ?? 0} عناصر",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // السعر أو أيقونة الانتقال
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );*/
    });
  }

  List<StoreOrdersModel> _getFilteredOrders(
    StoreOrderController controller,
    String status,
  ) {
    // تحديد المصدر الرئيسي للبيانات: إما نتائج البحث أو القائمة الكلية للطلبات
    List<StoreOrdersModel> sourceList = controller.isUserSearchingNow.value
        ? controller.filteredOrders
        : controller.allStoreOrders;
    // تصفية القائمة المختارة بناءً على التبويب الحالي المقروء من الـ StatusTab
    switch (status) {
      case 'new':
        return sourceList
            .where((o) => o.status == OrderStatus.pending)
            .toList();
      case 'processing':
        return sourceList
            .where((o) => o.status == OrderStatus.accepted)
            .toList();
      case 'ready':
        return sourceList
            .where(
              (o) =>
                  o.status == OrderStatus.readyForPickup ||
                  o.status == OrderStatus.shipped,
            )
            .toList();
      case 'cancelled':
        return sourceList
            .where((o) => o.status == OrderStatus.rejected)
            .toList();
      case 'picked_up':
        return sourceList
            .where((o) => o.status == OrderStatus.shipped)
            .toList();
      default:
        return sourceList
            .where((o) => o.status == OrderStatus.rejected)
            .toList();
    }

    /*switch (status) {
      case 'new':
        return controller.pendingOrders;
      case 'processing':
        return controller.processingOrders;
      case 'ready':
        return controller.readyOrders;
      case 'cancelled':
        return controller.rejectedOrders;
      case 'picked_up':
        return controller.pickedUpOrders;
      default:
        return controller.rejectedOrders;
    }*/
  }

  Widget TOrderCard(StoreOrdersModel order) {
    return GestureDetector(
      onTap: () => Get.to(() => OrderDetailScreen(order: order)),
      child: Container(
        margin: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
        padding: const EdgeInsets.all(TSizes.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha((0.1 * 255).round()),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // أيقونة ملونة حسب الحالة
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TColors.primary.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                color: TColors.primary,
              ),
            ),
            const SizedBox(width: TSizes.spaceBtwItems),

            // بيانات الطلب
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "طلب #${order.storeOrderId}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${order.orderDate.toString().split(' ')[0]} • ${order.items.length} عناصر",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),

            // السعر أو أيقونة الانتقال
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
