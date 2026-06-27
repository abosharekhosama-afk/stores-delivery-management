import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/common/widgets/anim/TDelayedSlideIn.dart';
import 'package:stors_admin_panel/common/widgets/images/t_rounded_image.dart';
import 'package:stors_admin_panel/common/widgets/shimmers/TOrderDetailShimmer.dart';
import 'package:stors_admin_panel/data/stor/controller/store_order_controller.dart';
import 'package:stors_admin_panel/data/stor/models/store_orders_model.dart';
import 'package:stors_admin_panel/data/stor/models/cart_item_model.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class OrderDetailScreen extends StatelessWidget {
  final StoreOrdersModel order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final controller = StoreOrderController.instance;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB), // لون خلفية هادئ وعصري
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "تفاصيل الطلب #${order.mainOrderId}",
          style: const TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() {
        // حالة التحميل (إذا كان الكنترولر يقوم بجلب بيانات محدثة)
        if (controller.isLoading.value) {
          return const TOrderDetailShimmer();
        }

        final currentOrder = controller.allStoreOrders.firstWhere(
          (o) => o.mainOrderId == order.mainOrderId,
          orElse: () => order, // في حال لم يجدها (لحظياً) استخدم النسخة الممرة
        );

        return SingleChildScrollView(
          child: Column(
            children: [
              // --- قسم ملخص حالة الطلب العلوي ---
              // 1. أنيميشن الهيدر العلوي (ينزلق من الأعلى)
              TDelayedSlideIn(child: _buildHeaderStatus(currentOrder)),
              Padding(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TDelayedSlideIn(
                      delayInMilliseconds: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "العناصر المطلوبة",
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            "${currentOrder.items.length} منتجات",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBtwItems),

                    // قائمة المنتجات بتصميم البطاقات الحديثة
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: currentOrder.items.length,
                      itemBuilder: (_, index) {
                        return TDelayedSlideIn(
                          delayInMilliseconds: 300 + (index * 100),
                          child: _buildModernItemCard(
                            currentOrder.items[index],
                            context,
                            currentOrder,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // الهيدر العلوي الذي يعطي طابع التطبيقات العالمية
  Widget _buildHeaderStatus(StoreOrdersModel updatedOrder) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // كود التسليم بتصميم "التذكرة الرقمية"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: TColors.primary.withAlpha((0.05 * 255).round()),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: TColors.primary.withAlpha((0.1 * 255).round()),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  "كود التحقق من التسليم",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // عرض الكود بخط عريض ومتباعد
                    Text(
                      order.pickupCode, // افترضت وجود حقل بهذا الاسم
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: TColors.primary,
                      ),
                    ),
                    const SizedBox(width: 15),
                    // زر نسخ الكود
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: order.pickupCode),
                        );
                        TLoaders.successSnackBar(
                          title: "تم النسخ",
                          message: "تم نسخ كود التسليم بنجاح",
                        );
                      },
                      icon: const Icon(
                        Iconsax.copy,
                        size: 20,
                        color: TColors.primary,
                      ),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // تاريخ الطلب والحالة
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Iconsax.calendar, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                "تاريخ الطلب: ${order.orderDate.toString().split(' ')[0]}",
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatusBadge(ItemStatus.pending),
        ],
      ),
    );
  }

  /*
  Widget _buildHeaderStatus(StoreOrdersModel updatedOrder) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Color(0xFFEEF2FF),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 35,
              color: TColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "تاريخ الطلب: ${order.orderDate.toString().split(' ')[0]}",
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildStatusBadge(
            ItemStatus.pending,
          ), // يمكن تمرير حالة الطلب الكلية هنا
        ],
      ),
    );
  }
*/
  Widget _buildModernItemCard(
    CartItemModel item,
    BuildContext context,
    StoreOrdersModel updatedOrder,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).round()),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // صورة المنتج مع زوايا ناعمة جداً
                  TRoundedImage(
                    imageType: ImageType.network,
                    image: item.image,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    borderRadius: 20,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.layers_outlined,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "الكمية: ${item.quantity}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildStatusBadge(item.itemStatus),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // منطقة تتبع الحالة مع خلفية باهتة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              color: const Color(0xFFF9FAFB),
              child: Column(
                children: [
                  _buildModernStepper(item.itemStatus),
                  const SizedBox(height: 20),
                  if (_getNextActionStatus(item.itemStatus) != null)
                    _buildActionButton(item, updatedOrder),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStepper(ItemStatus currentStatus) {
    // تحديد الخطوات
    final steps = ["جديد", "تجهيز", "جاهز"];
    int currentStepIndex = 0;
    if (currentStatus == ItemStatus.accepted) currentStepIndex = 1;
    if (currentStatus == ItemStatus.readyForPickup) currentStepIndex = 2;

    return Row(
      children: List.generate(steps.length, (index) {
        bool isCompleted = index < currentStepIndex;
        bool isCurrent = index == currentStepIndex;

        return Expanded(
          child: Row(
            children: [
              // الدوائر المحسنة
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted || isCurrent
                          ? TColors.primary
                          : Colors.grey[200],
                      border: isCurrent
                          ? Border.all(
                              color: TColors.primary.withAlpha(
                                (0.2 * 255).round(),
                              ),
                              width: 4,
                            )
                          : null,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : Icons.circle,
                      size: isCompleted ? 14 : 8,
                      color: isCompleted || isCurrent
                          ? Colors.white
                          : Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isCurrent ? TColors.primary : Colors.grey,
                    ),
                  ),
                ],
              ),
              // الخطوط الواصلة
              if (index != steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(
                      bottom: 16,
                      left: 4,
                      right: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: isCompleted ? TColors.primary : Colors.grey[200],
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActionButton(CartItemModel item, StoreOrdersModel currentOrder) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getActionColor(
              item.itemStatus,
            ).withAlpha((0.2 * 255).round()),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _getActionColor(item.itemStatus),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        onPressed: () => _handleStatusChange(item, currentOrder),
        child: Text(
          _getActionText(item.itemStatus),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  // --- دوال مساعدة محدثة بصرياً ---

  Widget _buildStatusBadge(ItemStatus status) {
    Color color;
    String text;
    switch (status) {
      case ItemStatus.pending:
        color = Colors.blue;
        text = "طلب جديد";
        break;
      case ItemStatus.accepted:
        color = Colors.orange;
        text = "قيد التجهيز";
        break;
      case ItemStatus.readyForPickup:
        color = Colors.green;
        text = "جاهز للاستلام";
        break;
      case ItemStatus.rejected:
        color = Colors.red;
        text = "مرفوض";
        break;
      case ItemStatus.shipped:
        color = Colors.pink;
        text = "تم الشحن";
        break;
      case ItemStatus.cancelled:
        color = Colors.brown;
        text = "تم الإلغاء";
        break;
      case ItemStatus.delivered:
        color = Colors.green;
        text = "تم التسليم";
        break;
      case ItemStatus.pickupFailed_WaitingAction:
        color = Colors.red;
        text = "فشل الاستلام - في انتظار الإجراء";
        break;
      case ItemStatus.pickupFailed_Confirmed:
        color = Colors.orange;
        text = "فشل الاستلام - تم التأكيد";
        break;
    }

    return UnconstrainedBox(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha((0.1 * 255).round()),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: color.withAlpha((0.2 * 255).round()),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دوال المنطق بقيت كما هي لضمان عمل التطبيق
  String _getActionText(ItemStatus status) {
    if (status == ItemStatus.pending) return "قبول وتجهيز المنتج";
    if (status == ItemStatus.accepted) return "تأكيد جاهزية المنتج";
    return "";
  }

  ItemStatus? _getNextActionStatus(ItemStatus status) {
    if (status == ItemStatus.pending) return ItemStatus.accepted;
    if (status == ItemStatus.accepted) return ItemStatus.readyForPickup;
    return null;
  }

  Color _getActionColor(ItemStatus status) {
    return status == ItemStatus.pending
        ? TColors.primary
        : const Color(0xFFF59E0B);
  }

  void _handleStatusChange(CartItemModel item, StoreOrdersModel currentOrder) {
    final nextStatus = _getNextActionStatus(item.itemStatus);
    if (item.itemStatus == ItemStatus.pending) {
      Get.defaultDialog(
        title: "معالجة المنتج",
        titleStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        middleText: "هل تريد البدء في تجهيز هذا المنتج؟",
        textConfirm: "تأكيد القبول",
        textCancel: "رفض المنتج",
        confirmTextColor: Colors.white,
        buttonColor: TColors.primary,
        onConfirm: () {
          Get.back();
          StoreOrderController.instance.changeStatus(
            storeOrderId: currentOrder.storeOrderId,
            mainOrderId: currentOrder.mainOrderId,
            productId: item.productId,
            variationId: item.variationId,
            status: ItemStatus.accepted,
            currentStatus: item.itemStatus,
          );
        },
        onCancel: () {
          StoreOrderController.instance.changeStatus(
            storeOrderId: currentOrder.storeOrderId,
            mainOrderId: currentOrder.mainOrderId,
            productId: item.productId,
            variationId: item.variationId,
            status: ItemStatus.rejected,
            currentStatus: item.itemStatus,
          );
        },
      );
    } else if (nextStatus != null) {
      StoreOrderController.instance.changeStatus(
        storeOrderId: currentOrder.storeOrderId,
        mainOrderId: currentOrder.mainOrderId,
        productId: item.productId,
        variationId: item.variationId,
        status: nextStatus,
        currentStatus: item.itemStatus,
      );
    }
  }
}
