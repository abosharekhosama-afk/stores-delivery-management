import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/anim/TDelayedSlideIn.dart';
import 'package:stors_admin_panel/common/widgets/images/t_rounded_image.dart';
import 'package:stors_admin_panel/common/widgets/shimmers/TMerchantActionShimmer.dart';
import 'package:stors_admin_panel/data/stor/controller/product/merchant_action_controller.dart';
import 'package:stors_admin_panel/data/stor/models/cart_item_model.dart';
import 'package:stors_admin_panel/data/stor/models/store_orders_model.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';

class MerchantPendingActionsScreen extends StatelessWidget {
  const MerchantPendingActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MerchantActionController());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "طلبات بانتظار قرارك",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 6,
            itemBuilder: (_, __) => const TMerchantActionShimmer(),
          );
        }
        if (controller.pendingActions.isEmpty) {
          return const Center(child: Text("لا توجد طلبات معلقة حالياً"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.pendingActions.length,
          itemBuilder: (context, index) {
            final order = controller.pendingActions[index];
            // استخراج المنتجات المعلقة فقط من هذا الطلب
            final pendingItems = order.items
                .where(
                  (i) => i.itemStatus == ItemStatus.pickupFailed_WaitingAction,
                )
                .toList();

            return Column(
              children: pendingItems.asMap().entries.map((entry) {
                var item = entry.value;
                // تطبيق الأنيميشن مع اتجاه اختياري وتأخير ديناميكي
                return TDelayedSlideIn(
                  delayInMilliseconds: 300 + (index * 100),
                  child: _buildActionCard(context, order, item, controller),
                );
              }).toList(),
            );
          },
        );
      }),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    StoreOrdersModel order,
    CartItemModel item,
    controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // صورة المنتج
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: TRoundedImage(
                    image: item.image ?? "",
                    imageType: ImageType.network,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                // تفاصيل المنتج
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "طلب رقم: #${order.storeOrderId.substring(0, 8)}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${item.price} ₪",
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha((0.1 * 255).round()),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "الكمية: ${item.quantity}",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // أزرار الأكشن
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showDecisionDialog(
                      context,
                      order.storeOrderId,
                      item,
                      controller,
                      true,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "تأكيد الإلغاء",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showDecisionDialog(
                      context,
                      order.storeOrderId,
                      item,
                      controller,
                      false,
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "رفض (المنتج متوفر)",
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDecisionDialog(
    context,
    String orderId,
    item,
    controller,
    bool isConfirming,
  ) {
    Get.defaultDialog(
      title: isConfirming ? "تأكيد إلغاء المنتج" : "رفض طلب الإلغاء",
      middleText: isConfirming
          ? "هل أنت متأكد من عدم توفر المنتج؟ سيتم خصم ثمنه من أرباحك وإبلاغ الزبون."
          : "سيتم إبلاغ المندوب بأن المنتج متوفر وعليه إعادة محاولة الاستلام.",
      textConfirm: "استمرار",
      textCancel: "تراجع",
      confirmTextColor: Colors.white,
      buttonColor: isConfirming ? Colors.red : Colors.green,
      onConfirm: () {
        controller.handleMerchantDecision(
          orderId,
          item.productId,
          isConfirming ? ItemStatus.rejected : ItemStatus.readyForPickup,
        );
      },
    );
  }
}
