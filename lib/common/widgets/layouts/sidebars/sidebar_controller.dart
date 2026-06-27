import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/stor/screens/dashboard/dashboard.dart';
import 'package:stors_admin_panel/routes/routes.dart';

class SidebarController extends GetxController {
  static SidebarController get instance => Get.find();

  final activeItem = TRoutes.dashboard.obs;
  final hoverItem = "".obs;

  // للتبسيط الآن: اجعل الشاشة الابتدائية مجرد نص للتأكد من العمل
  final Rx<Widget> currentScreen = Rx<Widget>(Dashboard());

  // تأكد أنك لا تعرف هذا المفتاح في أي مكان آخر
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  void changeActiveItem(String route) => activeItem.value = route;

  void changeHoverItem(String route) {
    if (!isActive(route)) {
      hoverItem.value = route;
    }
  }

  void menuOnTap(String route, Widget screen) {
    if (activeItem.value != route) {
      activeItem.value = route;

      // تأكد أن الشاشة (screen) التي ترسلها هي محتوى الشاشة فقط
      // (مثلاً DashboardContent) وليست TSitelayout مرة أخرى.
      currentScreen.value = screen;

      // إغلاق الدرور في الجوال فقط
      if (scaffoldKey.currentState?.isDrawerOpen ?? false) {
        scaffoldKey.currentState?.closeDrawer();
      }
    }
  }

  /*void menuOnTap(String route) {
    if (!isActive(route)) {
      changeActiveItem(route);

      if (TDeviceUtils.isMobileScreen(Get.context!)) Get.back();

      Get.toNamed(route);
    }
  }*/

  bool isActive(String route) => activeItem.value == route;
  bool isHovering(String route) => hoverItem.value == route;
}
