import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/data/stor/models/store_orders_model.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class InventoryOrderCard extends StatelessWidget {
  final StoreOrdersModel order;
  const InventoryOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TColors.grey.withAlpha((0.1 * 255).round())),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "طلب #${order.mainOrderId.substring(0, 8)}",
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Iconsax.shop,
                        size: 16,
                        color: TColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order.storeId,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ],
              ),
              // وسم الحالة (Status Badge)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: TColors.primary.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${order.items.length} قطع",
                  style: const TextStyle(
                    color: TColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: TSizes.spaceBtwSections),

          // شريط تقدم (Progress Bar) يوضح اكتمال التجميع
          Row(
            children: [
              const Expanded(
                child: LinearProgressIndicator(
                  value: 1.0, // لأننا نعرض الطلبات التي استلمها المندوب بالفعل
                  backgroundColor: TColors.grey,
                  color: Colors.green,
                  minHeight: 6,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "تم الاستلام",
                style: TextStyle(color: Colors.green[700], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


