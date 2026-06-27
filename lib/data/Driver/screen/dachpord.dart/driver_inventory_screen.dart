import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart'; // مكتبة أيقونات حديثة جداً
import 'package:stors_admin_panel/data/Driver/controller/driver_inventory_controller.dart';
import 'package:stors_admin_panel/data/Driver/screen/dachpord.dart/widget/inventory_order_card.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';

class DriverInventoryScreen extends StatelessWidget {
  const DriverInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DriverInventoryController());

    return Scaffold(
      backgroundColor:
          TColors.primaryBackground, // خلفية مائلة للرمادي الفاتح جداً
      appBar: AppBar(
        title: Text(
          "حقيبة التجميع",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        //centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          /// 1. شريط البحث والفلترة الحديث
          Padding(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.03 * 255).round()),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) =>
                          controller.searchQuery.value = value,
                      decoration: const InputDecoration(
                        hintText: "ابحث برقم الطلب أو اسم المتجر...",
                        prefixIcon: Icon(Iconsax.search_normal),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems),

                // زر فلترة صغير وأنيق
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.filter_edit, color: Colors.white),
                ),
              ],
            ),
          ),

          /// 2. القائمة
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.filteredOrders.isEmpty) {
                return const Center(
                  child: Text("لا توجد طلبات في حقيبتك حالياً"),
                );
              }

              return ListView.builder(
                itemCount: controller.filteredOrders.length,
                padding: const EdgeInsets.symmetric(
                  horizontal: TSizes.defaultSpace,
                ),
                itemBuilder: (context, index) {
                  final order = controller.filteredOrders[index];
                  return InventoryOrderCard(order: order);
                },
              );
            }),
          ),
        ],
      ),

      /// 3. زر الإجراء الرئيسي (Floating Action Button)
      /// يظهر فقط عندما يكون هناك طلبات لتفريغها في المركز
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showHandoverDialog(context),
        backgroundColor: TColors.primary,
        icon: const Icon(Iconsax.box_tick),
        label: const Text("تفريغ في المركز"),
      ),
    );
  }
}

void _showHandoverDialog(BuildContext context) {
  final controller = DriverInventoryController.instance;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // جزء علوي ملون يعطي طابعاً حديثاً
          Container(
            padding: const EdgeInsets.all(TSizes.lg),
            decoration: const BoxDecoration(
              color: TColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: const Center(
              child: Icon(Iconsax.box_tick, color: Colors.white, size: 50),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Column(
              children: [
                Text(
                  "تأكيد التسليم للمركز",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: TSizes.spaceBtwItems),
                Text(
                  "أنت على وشك تسليم (${controller.allPickedOrders.length}) طلبات لمركز التجميع الرئيسي. هل تأكدت من مطابقة جميع الشحنات؟",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: TSizes.spaceBtwSections),

                // أزرار الإجراءات
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("إلغاء"),
                      ),
                    ),
                    const SizedBox(width: TSizes.spaceBtwItems),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => controller.handoverOrdersToHub(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("تأكيد"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


