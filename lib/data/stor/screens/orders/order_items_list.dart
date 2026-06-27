
/*
class OrderItemsList extends StatelessWidget {
  final String statusTab; // 'new', 'processing', 'ready', 'rejected'
  const OrderItemsList({super.key, required this.statusTab});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StoreOrderController>();

    return Obx(() {
      // 1. استخدام القوائم المفلترة الجاهزة من المتحكم بدلاً من فلترتها هنا
      List<CartItemModel> items = [];
      if (statusTab == 'new') {
        items = controller.newItems;
        debugPrint("nubmer of items : ${items.length}");
      } else if (statusTab == 'processing') {
        items = controller.processingItems;
        debugPrint("nubmer of items : ${items.length}");
      } else if (statusTab == 'ready') {
        items = controller.readyItems;
        debugPrint("nubmer of items : ${items.length}");
      } else if (statusTab == 'rejected') {
        items = controller.rejectedItems;
        debugPrint("nubmer of items : ${items.length}");
      }
      if (items.isEmpty) {
        return const Center(child: Text("لا توجد عناصر في هذا القسم"));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        itemCount: items.length,
        itemBuilder: (_, index) {
          final item = items[index]; // item هنا عبارة عن Map
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
            child: Padding(
              padding: const EdgeInsets.all(TSizes.md),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    // 2. قراءة البيانات باستخدام مفاتيح الـ Map كما تم تخزينها
                    leading: item.image != null
                        ? TRoundedImage(
                            imageType: ImageType.network,
                            image: item.image,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.image,
                            size: 60,
                          ), // صورة بديلة في حال عدم وجودها
                    title: Text(
                      item.title ?? 'بدون اسم',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "رقم الطلب: #${item.mainOrderId}\nالكمية: ${item.quantity}",
                    ),
                  ),
                  const Divider(),
                  _buildActionButtons(item, context),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  // 3. تعديل منطق الأزرار لتمرير المتغيرات المطلوبة للمتحكم بشكل صحيح
  Widget _buildActionButtons(CartItemModel item, BuildContext context) {
    final controller = StoreOrderController.instance;

    // استخراج المعرفات المطلوبة لدالة changeStatus
    final storeId = item.storeId;
    final mainOrderId = item.mainOrderId;
    final productId = item.productId;

    if (statusTab == 'new') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            // استدعاء الدالة الصحيحة وتمرير Enum
            onPressed: () => controller.changeStatus(
              storeOrderId: currentOrder.storeOrderId,
              mainOrderId: currentOrder.mainOrderId,
              productId: item.productId,
              variationId: item.variationId,
              status: ItemStatus.rejected,
              currentStatus: item.itemStatus,
            ),
            child: const Text("رفض", style: TextStyle(color: Colors.red)),
          ),
          const SizedBox(width: TSizes.spaceBtwItems),
          ElevatedButton(
            onPressed: () => controller.changeStatus(
              storeId,
              mainOrderId ?? "",
              productId,
              ItemStatus.accepted,
              item.itemStatus,
            ),
            child: const Text("قبول وتجهيز"),
          ),
        ],
      );
    } else if (statusTab == 'processing') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          onPressed: () => controller.changeStatus(
            storeId,
            mainOrderId ?? "",
            productId,
            ItemStatus.readyForPickup,
            item.itemStatus,
          ),
          child: const Text("تم التجهيز (جاهز للاستلام)"),
        ),
      );
    } else if (statusTab == 'ready') {
      return const Row(
        children: [
          Icon(Icons.info_outline, color: TColors.primary, size: 20),
          SizedBox(width: 8),
          Text(
            "في انتظار وصول المندوب",
            style: TextStyle(color: TColors.primary),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

}
*/