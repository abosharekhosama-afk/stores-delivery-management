import 'package:get/get.dart';
import 'package:stors_admin_panel/data/Driver/Notification/screen/driver_notifications_screen.dart';
import 'package:stors_admin_panel/data/Driver/Notification/service/driver_notification_controller.dart';
import 'package:stors_admin_panel/data/Driver/screen/DriverProfile/driver_profile_screen.dart';
import 'package:stors_admin_panel/data/Driver/screen/FinalDelivery/final_delivery_screen.dart';
import 'package:stors_admin_panel/data/Driver/screen/dachpord.dart/driver_inventory_screen.dart';
import 'package:stors_admin_panel/data/Driver/storeReady/ready_stores_screen.dart';

class NavigationController extends GetxController {
  // المتغير المسؤول عن رقم التبويب النشط حالياً
  final Rx<int> selectedIndex = 0.obs;

  // قائمة الشاشات التي سيتم التنقل بينها
  // ملاحظة: تأكد من تطابق أسماء الكلاسات مع ما لديك في المشروع
  final screens = [
    const ReadyStoresScreen(), // شاشة عرض المتاجر التي لديها طلبات جاهزة
    const DriverInventoryScreen(), // شاشة حقيبة المجمّع (التي صممناها سابقاً)
    const FinalDeliveryScreen(),
    const NotificationsScreen(), // شاشة الإشعارات للمندوب
    const DriverProfileScreen(), // شاشة الملف الشخصي للمندوب
    //const SettingsScreen(), // شاشة الإعدادات الشخصية للمندوب
  ];
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    final notificationController = Get.put(DriverNotificationController());
    notificationController.requestPermissionOnHome();
  }

  // دالة اختيارية إذا أردت التنقل لتبويب معين برمجياً من شاشة أخرى
  void jumpToTab(int index) {
    selectedIndex.value = index;
  }
}
