import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/data/stor/controller/store_order_controller.dart';
import 'package:stors_admin_panel/data/stor/screens/orders/Orders/order_list_tap.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';

class OrderTap extends StatelessWidget {
  const OrderTap({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StoreOrderController());
    return DefaultTabController(
      length: 5, // الأربعة أقسام التي طلبتها
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading:
              false, // لمنع تداخل أزرار الرجوع أثناء البحث
          elevation: 0,
          title: Obx(() {
            return Stack(
              //alignment: Alignment.centerLeft,
              children: [
                // 1. العنوان الافتراضي: يختفي تدريجياً عند تفعيل البحث
                Positioned(
                  top: 16,
                  child: AnimatedOpacity(
                    opacity: controller.isSearchActive.value ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    child: const Text(
                      "إدارة طلبات المتجر",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: controller.isSearchActive.value
                        ? CrossFadeState
                              .showSecond // يعرض شريط البحث الممتد
                        : CrossFadeState.showFirst, // يعرض أيقونة البحث فقط
                    // 1️⃣ الشكل الأول: أيقونة البحث عندما يكون مغلقاً
                    firstChild: Container(
                      width: 45,
                      height: 45,
                      alignment: Alignment.center,
                      child: IconButton(
                        icon: const Icon(
                          Iconsax.search_normal_1,
                          color: Colors.black87,
                        ),
                        onPressed: () => controller.toggleSearchStatus(),
                      ),
                    ),

                    // 2️⃣ الشكل الثاني: شريط البحث الكامل عندما يكون مفتوحاً
                    secondChild: Container(
                      width: MediaQuery.of(context).size.width - 32,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Iconsax.search_normal,
                              color: TColors.primary,
                            ),
                            onPressed: () => controller.searchOrders(
                              controller.textSearchController.text,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: controller.textSearchController,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (value) =>
                                  controller.searchOrders(value),
                              decoration: const InputDecoration(
                                hintText: "ابحث برقم الطلب...",
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                fillColor: Colors.white,
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () {
                              if (controller
                                  .textSearchController
                                  .text
                                  .isNotEmpty) {
                                controller.clearSearch();
                              } else {
                                controller.toggleSearchStatus();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                /*
                // 2. حقل البحث المتمدد: يأخذ المساحة بالكامل عند التفعيل
                Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    // إذا كان البحث نشطاً يأخذ عرض الشاشة بالكامل، وإذا كان مغلقاً ينكمش ليكون مساوياً لحجم الأيقونة فقط
                    width: controller.isSearchActive.value
                        ? MediaQuery.of(context).size.width - 32
                        : 50,
                    height: 45,
                    decoration: BoxDecoration(
                      color: controller.isSearchActive.value
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: controller.isSearchActive.value
                          ? Border.all(color: Colors.grey.shade300)
                          : null,
                      boxShadow: controller.isSearchActive.value
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        // أيقونة البحث / التنفيذ والتنقل
                        IconButton(
                          icon: Icon(
                            controller.isSearchActive.value
                                ? Iconsax.search_normal
                                : Iconsax.search_normal_1,
                            color: controller.isSearchActive.value
                                ? TColors.primary
                                : Colors.black87,
                          ),
                          onPressed: () {
                            if (!controller.isSearchActive.value) {
                              controller.toggleSearchStatus();
                            } else {
                              // تنفيذ البحث عند الضغط عليها وهي ممتدة
                              controller.searchOrders(
                                controller.textSearchController.text,
                              );
                            }
                          },
                        ),

                        // الحقل النصي للبحث (يظهر فقط عند التمدد)
                        if (controller.isSearchActive.value)
                          Expanded(
                            child: TextField(
                              controller: controller.textSearchController,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (value) =>
                                  controller.searchOrders(value),
                              decoration: const InputDecoration(
                                hintText: "ابحث برقم الطلب أو اسم العميل...",
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),

                        // أيقونة الإغلاق والتنظيف (تظهر فقط عند فتح البحث)
                        if (controller.isSearchActive.value)
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () {
                              if (controller
                                  .textSearchController
                                  .text
                                  .isNotEmpty) {
                                // إذا كان هناك نص، نقوم بتنظيفه أولاً وإعادة القائمة كاملة
                                controller.clearSearch();
                              } else {
                                // إذا كان الحقل فارغاً أصلاً، نغلق شريط البحث بالكامل وينكمش
                                controller.toggleSearchStatus();
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              */
              ],
            );
          }),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: TColors.primary,
            tabs: [
              Tab(text: "جديدة"),
              Tab(text: "قيد التجهيز"),
              Tab(text: "جاهزة للاستلام"),
              Tab(text: "مرفوضة"),
              Tab(text: "تم تسليمها"), // تبويب جديد للطلبات المستلمة
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            OrderListTab(statusTab: 'new'),
            OrderListTab(statusTab: 'processing'),
            OrderListTab(statusTab: 'ready'),
            OrderListTab(statusTab: 'cancelled'),
            OrderListTab(statusTab: 'picked_up'),
          ],
        ),
      ),
    );
  }
}
