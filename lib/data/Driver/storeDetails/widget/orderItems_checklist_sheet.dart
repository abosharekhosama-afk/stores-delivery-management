import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:stors_admin_panel/data/Driver/controller/store_orders_detail_controller.dart';
import 'package:stors_admin_panel/data/stor/models/cart_item_model.dart';
import 'package:stors_admin_panel/data/stor/models/store_orders_model.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class OrderItemsChecklistSheet extends StatelessWidget {
  final StoreOrdersModel storeOrder;
  final String storeId;

  const OrderItemsChecklistSheet({
    super.key,
    required this.storeOrder,
    required this.storeId,
  });

  @override
  Widget build(BuildContext context) {
    // نستخدم Get.find للوصول للكنترولر المحقون مسبقاً في الشاشة الأساسية
    final controller = Get.find<StoreOrdersDetailsController>(tag: storeId);

    return Container(
      constraints: BoxConstraints(
        maxHeight: Get.height * 0.85,
      ), // يغطي 85% من الشاشة
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            "فحص ومطابقة العناصر",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Expanded(
            child: Obx(() {
              // البحث عن الطلب المحدث دائماً من القائمة في الكنترولر
              final currentOrder = controller.orders.firstWhere(
                (o) => o.storeOrderId == storeOrder.storeOrderId,
              );

              return ListView.builder(
                itemCount: currentOrder.items.length,
                itemBuilder: (context, index) {
                  final item = currentOrder.items[index];
                  return _buildItemRow(
                    index,
                    item,
                    controller,
                    storeOrder.mainOrderId,
                    storeOrder.storeOrderId,
                  );
                },
              );
            }),
          ),
          // زر التأكيد النهائي
          _buildFinalAction(
            context,
            controller,
            storeOrder.mainOrderId,
            storeOrder.storeOrderId,
          ),
        ],
      ),
    );
  }

  // هنا تضع دوال الـ Build الفرعية (التي أرسلتها لك سابقاً) مثل _buildItemRow

  Widget _buildItemRow(
    int index,
    CartItemModel item,
    StoreOrdersDetailsController controller,
    String mainOrderId,
    String storeOrderId,
  ) {
    // تحديد الألوان بناءً على الحالة
    bool isPicked = item.itemStatus == ItemStatus.shipped;
    bool isWaiting = item.itemStatus == ItemStatus.pickupFailed_WaitingAction;
    bool isFailed = item.itemStatus == ItemStatus.pickupFailed_Confirmed;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPicked
            ? Colors.green.withAlpha((0.05 * 255).round())
            : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isPicked
              ? Colors.green
              : (isWaiting ? Colors.orange : Colors.grey[200]!),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // صورة المنتج
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              item.image ?? "",
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_not_supported, size: 40),
            ),
          ),
          const SizedBox(width: 15),

          // تفاصيل المنتج
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: isPicked ? TextDecoration.lineThrough : null,
                    color: isPicked ? Colors.grey : Colors.black87,
                  ),
                ),
                Text(
                  "الكمية: ${item.quantity} | ${item.variationId}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (isWaiting)
                  const Text(
                    "بانتظار تأكيد التاجر للرفض...",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),

          // الأزرار التفاعلية
          if (item.itemStatus == ItemStatus.readyForPickup)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // زر التأكيد (صح)
                IconButton(
                  onPressed: () => controller.markItemAsPickedUp(
                    storeOrderId: storeOrderId,
                    mainOrderId: mainOrderId,
                    productId: item.productId,
                  ),
                  icon: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 28,
                  ),
                ),
                // زر الإبلاغ عن مشكلة (تحذير)
                IconButton(
                  onPressed: () => _showProblemMenu(
                    mainOrderId,
                    storeOrderId,
                    index,
                    controller,
                  ),
                  icon: const Icon(Icons.error_outline, color: Colors.orange),
                ),
              ],
            )
          else
            // أيقونة الحالة النهائية
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                isPicked
                    ? Icons.done_all
                    : (isFailed ? Icons.cancel_outlined : Icons.hourglass_top),
                color: isPicked
                    ? Colors.green
                    : (isFailed ? Colors.red : Colors.orange),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFinalAction(
    BuildContext context,
    StoreOrdersDetailsController controller,
    String mainOrderId,
    String storeOrderId,
  ) {
    return Obx(() {
      // الحصول على الطلب الحالي لمتابعة حالته
      final order = controller.orders.firstWhere(
        (o) => o.storeOrderId == storeOrderId,
      );
      bool canFinalize = controller.isOrderReadyToFinalize(order);

      return Container(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: canFinalize ? Colors.black : Colors.grey[300],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 0,
          ),
          onPressed: canFinalize
              ? () => _showCodeDialog(
                  context,
                  controller,

                  mainOrderId,
                  storeOrderId,
                )
              : null,
          child: Text(
            canFinalize
                ? "تأكيد الاستلام برمز المتجر"
                : "يرجى فحص كافة العناصر أولاً",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: canFinalize ? Colors.white : Colors.black45,
            ),
          ),
        ),
      );
    });
  }

  // حوار الإبلاغ عن نقص
  void _showProblemMenu(
    String mainOrderId,
    String storeOrderId,
    int itemIndex,
    StoreOrdersDetailsController controller,
  ) {
    Get.defaultDialog(
      title: "تأكيد نقص المنتج",
      middleText:
          "هل تريد إبلاغ التاجر بتعذر استلام هذا المنتج؟ سيتعين على التاجر تأكيد ذلك من حسابه.",
      textConfirm: "إرسال طلب للتاجر",
      textCancel: "إلغاء",
      confirmTextColor: Colors.white,
      buttonColor: Colors.orange,
      onConfirm: () {
        controller.requestItemCancellation(
          mainOrderId: mainOrderId,
          storeOrderId: storeOrderId,
          productId: controller.orders
              .firstWhere((o) => o.storeOrderId == storeOrderId)
              .items[itemIndex]
              .productId,
        );
        Get.back();
      },
    );
  }

  void _showCodeDialog(
    BuildContext context,
    StoreOrdersDetailsController controller,
    String mainOrderId,
    String storeOrderId,
  ) {
    final TextEditingController pinController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              storeOrderId,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            // Text(order.userPhone, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            const Text(
              "أدخل رمز الاستلام من العميل",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // استخدام Pinput لشكل احترافي
            Pinput(
              length: 6,
              controller: pinController,
              defaultPinTheme: PinTheme(
                width: 56,
                height: 56,
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                ),
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () async {
                  bool success = await controller.finalizePickup(
                    mainOrderId: mainOrderId,
                    storeOrderId: storeOrderId,
                    inputCode: pinController.text,
                  );
                  if (success) {
                    Get.back(); // إغلاق الديالوج
                    Get.back(); // إغلاق البوتوم شيت
                    TLoaders.successSnackBar(
                      title: "تم بنجاح",
                      message: "الطلب الآن في عهدتك. ",
                    );
                  } else {
                    TLoaders.errorSnackBar(
                      title: "خطأ",
                      message: "الرمز غير صحيح، يرجى المحاولة مرة أخرى",
                    );
                  }
                },
                child: const Text(
                  "تأكيد الاستلام النهائي",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // حوار إدخال الرمز
  /*
  void _showCodeDialog(
    StoreOrdersDetailsController controller,
    String orderId,
  ) {
    final TextEditingController codeController = TextEditingController();

    Get.defaultDialog(
      title: "رمز التحقق",
      content: Column(
        children: [
          const Text("اطلب من التاجر إدخال الرمز الخاص بهذا الطلب"),
          const SizedBox(height: 15),
          TextField(
            controller: codeController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: "0000",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
      textConfirm: "تأكيد وشحن",
      onConfirm: () async {
        bool success = await controller.finalizePickup(
          orderId,
          codeController.text,
        );
        if (success) {
          Get.back(); // إغلاق الديالوج
          Get.back(); // إغلاق البوتوم شيت
          TLoaders.successSnackBar(
            title: "تم بنجاح",
            message: "الطلب الآن في طريقك للتوصيل",
          );
        } else {
          TLoaders.errorSnackBar(
            title: "خطأ",
            message: "الرمز غير صحيح، يرجى المحاولة مرة أخرى",
          );
        }
      },
    );
  }
*/
}
