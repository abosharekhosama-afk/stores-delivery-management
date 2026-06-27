import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/data/Driver/controller/ready_stores_controller.dart';
import 'package:stors_admin_panel/data/Driver/storeDetails/store_orders_details_screen.dart';
import 'package:stors_admin_panel/features/features_authintication/models/address_model.dart';
import 'package:stors_admin_panel/features/features_authintication/models/user_stor_model.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';
import 'package:stors_admin_panel/utils/helpers/helper_functions.dart';

class ReadyStoresScreen extends StatelessWidget {
  const ReadyStoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReadyStoresController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("المتاجر الجاهزة للاستلام"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildLocationFilter(controller, context),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.filteredStores.isEmpty) {
                return const Center(
                  child: Text("لا توجد طلبات في هذه المنطقة"),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                itemCount: controller.filteredStores.length,
                itemBuilder: (context, index) {
                  final store = controller.filteredStores[index];
                  final int ordersCount = store['ordersCount'] ?? 0;
                  final storAddress = AddressModel.fromMap(
                    store[StoreModel.getAddressModel],
                  );
                  final bool isHighPriority = ordersCount >= 10;

                  return GestureDetector(
                    onTap: () => Get.to(
                      () => StoreOrdersDetailsScreen(
                        storeId: store[StoreModel.getStoreId],
                        storeName: store[StoreModel.getStorName],
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: THelperFunctions.isDarkMode(context)
                            ? TColors.darkerGrey
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: isHighPriority
                                ? Colors.red.withOpacity(0.1)
                                : Colors.black.withOpacity(0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: isHighPriority
                              ? Colors.red.withOpacity(0.3)
                              : TColors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            // خلفية خفيفة جداً تعطي انطباع بصري عن الحالة
                            Positioned(
                              left: -20,
                              top: -20,
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: isHighPriority
                                    ? Colors.red.withAlpha(10)
                                    : TColors.primary.withAlpha(10),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // 1. أيقونة المتجر بتصميم مميز
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: isHighPriority
                                          ? Colors.red.shade50
                                          : TColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Icon(
                                      Iconsax.shop,
                                      color: isHighPriority
                                          ? Colors.red
                                          : TColors.primary,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // 2. تفاصيل المتجر
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          store[StoreModel.getStorName],
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Iconsax.location,
                                              size: 14,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                storAddress.subAddress,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(
                                                      color: Colors.grey,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 3. مؤشر عدد الطلبات (Badge)
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isHighPriority
                                              ? Colors.red
                                              : TColors.primary,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  (isHighPriority
                                                          ? Colors.red
                                                          : TColors.primary)
                                                      .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              "$ordersCount",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const Text(
                                              "طلبات",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
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
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

Widget _buildLocationFilter(
  ReadyStoresController controller,
  BuildContext context,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "تصفية المتاجر حسب الموقع",
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: TSizes.spaceBtwItems),

        Row(
          children: [
            // 1. القائمة المنسدلة (المحافظة) - تأخذ مساحة 40% من العرض مثلاً
            Expanded(
              flex: 1,
              child: Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: THelperFunctions.isDarkMode(context)
                        ? TColors.darkerGrey
                        : TColors.softGrey,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: TColors.grey.withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      borderRadius: BorderRadius.circular(TSizes.buttonRadius),
                      value: controller.selectedCity.value,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: TColors.primary,
                      ),
                      items: controller.addressData.keys.map((String gov) {
                        return DropdownMenuItem<String>(
                          value: gov,
                          child: Text(
                            gov,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) controller.updateCity(val);
                      },
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // 2. تابات المناطق (المدن) - تأخذ المساحة المتبقية
            Expanded(
              flex: 3,
              child: Obx(() {
                final cities = controller.currentDistrictCities;
                return SizedBox(
                  height: 45,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: cities.length,
                    itemBuilder: (context, index) {
                      final city = cities[index];
                      return Obx(() {
                        final isSelected =
                            controller.selectedDistrict.value == city;
                        return GestureDetector(
                          onTap: () => controller.updateDistrict(city),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? TColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? TColors.primary
                                    : TColors.grey.withOpacity(0.5),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                city,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white
                                      : (THelperFunctions.isDarkMode(context)
                                            ? Colors.white70
                                            : Colors.black87),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      });
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildPriorityTag(int count) {
  if (count < 5) {
    return const SizedBox.shrink(); // لا يظهر شيء إذا كانت الطلبات أقل من 5
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.orange.shade100, // لون هادئ لا يزعج العين
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.orange.shade700, width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flash_on, size: 14, color: Colors.orange.shade900),
        const SizedBox(width: 4),
        Text(
          "أولوية: طلبات كثيرة",
          style: TextStyle(
            color: Colors.orange.shade900,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
