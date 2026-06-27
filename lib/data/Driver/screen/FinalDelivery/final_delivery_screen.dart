import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:pinput/pinput.dart';
import 'package:stors_admin_panel/data/Driver/controller/final_delivery_controller.dart';
import 'package:stors_admin_panel/data/stor/models/order_model.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart'; // حزمة لإدخال الكود بشكل جمالي

class FinalDeliveryScreen extends StatelessWidget {
  const FinalDeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FinalDeliveryController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // خلفية فاتحة جداً حديثة
      appBar: AppBar(
        title: const Text(
          "توصيل الطلبات",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        //centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.mainOrders.isEmpty) {
          return const Center(child: Text("لا توجد طلبات جاهزة للتوصيل"));
        }

        return ListView.builder(
          itemCount: controller.mainOrders.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final order = controller.mainOrders[index];
            return _buildOrderCard(context, order);
          },
        );
      }),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showDeliveryBottomSheet(context, order),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "#${order.id.substring(0, 7)}",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Iconsax.more, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Iconsax.location5,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.address?.fullAddress.toString() ??
                            "العنوان مفقود",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Iconsax.box, size: 18, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "${order.items.length} منتجات",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const Text(
                      "عرض التفاصيل",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeliveryBottomSheet(BuildContext context, OrderModel order) {
    final controller = FinalDeliveryController.instance;
    final pinController = TextEditingController();

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
              order.userId,
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
                  bool success = await controller.completeFinalDelivery(
                    order.id,
                    pinController.text,
                  );
                  if (success) {
                    Get.back();
                    TLoaders.successSnackBar(
                      title: "تم بنجاح",
                      message: "تم تسليم الطلب وإغلاقه",
                    );
                  } else {
                    TLoaders.errorSnackBar(
                      title: "خطأ",
                      message: "رمز التحقق غير صحيح",
                    );
                  }
                },
                child: const Text(
                  "تأكيد التسليم النهائي",
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

}


