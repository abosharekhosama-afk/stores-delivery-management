import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/anim/TDelayedSlideIn.dart';
import 'package:stors_admin_panel/common/widgets/appbar/appbar.dart';
import 'package:stors_admin_panel/common/widgets/shimmers/NotificationShimmer.dart';
import 'package:stors_admin_panel/data/stor/controller/notification_controller.dart';
import 'package:stors_admin_panel/data/stor/screens/Notification/notification_card.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:iconsax/iconsax.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationControllerForScreen());
    final scrollController = ScrollController();
    double lastScrollPosition = 0.0;

    // قائمة الفلاتر التي ستظهر للمستخدم مع ربطها بالقيم البرمجية الحقيقية
    final List<Map<String, String>> filterOptions = [
      {'label': 'الكل', 'value': 'الكل'},
      {'label': 'الطلبات الجديدة', 'value': 'NEW_ORDER'},
      {'label': 'عمليات السحب', 'value': 'withdrawal'},
    ];
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // جعل الخلفية شفافة
        statusBarIconBrightness: Brightness.dark, // للأندرويد: أيقونات سوداء
        statusBarBrightness: Brightness.light, // للـ iOS: أيقونات سوداء
      ),
    );
    // مراقبة الاتجاه والتحفيز الذكي للجلب
    scrollController.addListener(() {
      double currentPosition = scrollController.position.pixels;

      // تحديث اتجاه الحركة
      if (currentPosition > lastScrollPosition && currentPosition > 0) {
        controller.isScrollingDown.value = true;
      } else if (currentPosition < lastScrollPosition) {
        controller.isScrollingDown.value = false;
      }
      lastScrollPosition = currentPosition;

      // جلب المزيد عند الاقتراب من النهاية بمقدار 200 بكسل
      if (currentPosition >= scrollController.position.maxScrollExtent - 200) {
        // لا يتم استدعاء الجلب إلا إذا كان الفلتر على "الكل" لضمان الترتيب التسلسلي المستقر
        if (controller.selectedFilter.value == "الكل") {
          controller.fetchNotifications();
        }
      }
    });
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // للأندرويد
        statusBarBrightness: Brightness.light, // للـ iOS
      ),
      child: Scaffold(
        appBar: TAppBar(
          title: Text("الإشعارات"),
          centerTitle: true,
          showBackArrow: true,
        ),
        body: Column(
          children: [
            // 🌟 --- شريط الفلترة العصري الموزع بالتساوي --- 🌟
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(
                  0.08,
                ), // خلفية ناعمة محيطة بالشريط
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Row(
                children: filterOptions.map((filter) {
                  return Obx(() {
                    final isSelected =
                        controller.selectedFilter.value == filter['value'];

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => controller.applyFilter(filter['value']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            // تأثير الانتقال اللوني العصري
                            color: isSelected
                                ? TColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: TColors.primary.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              filter['label']!,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[700],
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  });
                }).toList(),
              ),
            ),
            /*
            // --- شريط الفلترة الأفقي العصري ---
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: filterOptions.map((filter) {
                  return Obx(() {
                    final isSelected =
                        controller.selectedFilter.value == filter['value'];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ChoiceChip(
                          label: Text(filter['label']!),
                          selected: isSelected,
                          onSelected: (_) =>
                              controller.applyFilter(filter['value']!),
                          selectedColor: TColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  });
                }).toList(),
              ),
            ),
*/
            // --- قائمة عرض الإشعارات ---
            Expanded(
              child: Obx(() {
                if (controller.filteredNotifications.isEmpty &&
                    controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.filteredNotifications.isEmpty) {
                  return const Center(
                    child: Text("لا توجد إشعارات حالياً لهذا الفلتر"),
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  itemCount:
                      controller.filteredNotifications.length +
                      (controller.hasMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    // --- التحكم بالـ Shimmer السفلي تبعا للاتجاه والتحميل ---
                    if (index == controller.filteredNotifications.length) {
                      if (controller.isLoading.value &&
                          controller.isScrollingDown.value &&
                          controller.selectedFilter.value == "الكل") {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: NotificationShimmer(), // كارت مفرد آمن ومستقر
                        );
                      }
                      return const SizedBox(height: 40);
                    }

                    var doc = controller.filteredNotifications[index];
                    var data = doc;
                    String docId = doc.id;
                    bool isOpened = data.isOpened;

                    return Dismissible(
                      key: Key(docId),
                      direction: DismissDirection.startToEnd,
                      onDismissed: (_) =>
                          controller.deleteNotification(docId, isOpened),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(
                          Iconsax.box_remove5,
                          color: Colors.white,
                        ),
                      ),
                      child: TDelayedSlideIn(
                        delayInMilliseconds: (index % 20) * 50,
                        direction: SlideDirection.bottomToTop,
                        // تمرير اتجاه الحركة لإلغاء الأنميشن في الصعود
                        isScrollingDown: controller.isScrollingDown.value,
                        // 🔥 الحل هنا: تغليف البطاقة بـ Obx لتستجيب لـ .refresh() الخاص بالقائمة
                        child: Obx(() {
                          // نعيد جلب العنصر من القائمة المحدثة لضمان قراءة القيمة الجديدة بالـ reactive
                          final currentDoc =
                              controller.filteredNotifications[index];
                          return NotificationCard(
                            data: currentDoc,
                            onTap: () => controller.markAsOpened(docId),
                          );
                        }),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),

        /*
        body: Obx(() {
          if (controller.notifications.isEmpty && controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.notifications.isEmpty) {
            return const Center(child: Text("لا توجد إشعارات حالياً"));
          }

          return ListView.builder(
            controller: scrollController,
            itemCount:
                controller.notifications.length +
                (controller.hasMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              // عرض مؤشر تحميل صغير في الأسفل عند جلب بيانات جديدة
              if (index == controller.notifications.length) {
                return ListView.separated(
                  itemCount: 6,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: TSizes.spaceBtwItems),
                  itemBuilder: (_, __) => const NotificationShimmer(),
                );
              }

              var doc = controller.notifications[index];
              var data = doc.data() as Map<String, dynamic>;
              String docId = doc.id;
              bool isOpened = data['isOpened'] ?? false;

              return Dismissible(
                key: Key(docId),
                direction: DismissDirection.startToEnd,
                onDismissed: (_) =>
                    controller.deleteNotification(docId, isOpened),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Iconsax.box_remove5, color: Colors.white),
                ),
                child: TDelayedSlideIn(
                  // استخدام مودولو 20 يجعل الأنيميشن سريعاً وسلساً حتى في القوائم الطويلة
                  delayInMilliseconds: (index % 20) * 50,
                  direction: SlideDirection.bottomToTop,
                  child: NotificationCard(
                    data: data,
                    onTap: () => controller.markAsOpened(docId),
                  ),
                ),
              );
            },
          );
        }),
      */
      ),
    );
  }
}
