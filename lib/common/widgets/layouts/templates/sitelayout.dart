import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/layouts/sidebars/sidebar_controller.dart';
import 'package:stors_admin_panel/common/widgets/responsive/responsive_design.dart';
import 'package:stors_admin_panel/common/widgets/responsive/screens/desktop_layout.dart';
import 'package:stors_admin_panel/common/widgets/responsive/screens/mobile_layout.dart';
import 'package:stors_admin_panel/common/widgets/responsive/screens/tablet_layout.dart';

class TSitelayout extends StatelessWidget {
  const TSitelayout({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SidebarController(), permanent: true);

    return Obx(() {
      // نستمع هنا لتغير الشاشة الحالية من السايدبار
      final Widget screen = controller.currentScreen.value;
      final String route = controller.activeItem.value;
      return TResponsiveDesign(
        desktop: DesktopLayout(body: screen),
        tablet: TabletLayout(body: screen),
        mobile: MobileLayout(body: screen),
      );
    });
  }
}


/*
class TSitelayout extends StatelessWidget {
  const TSitelayout({
    super.key,
    this.desktop,
    this.tablet,
    this.mobile,
    this.userLayout = true,
  });
  final Widget? desktop;
  final Widget? tablet;
  final Widget? mobile;

  final bool userLayout;
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SidebarController(), permanent: true);
    return Scaffold(
      key: controller.scaffoldKey,
      // نستخدم Obx هنا لضمان تحديث الشاشة بالكامل عند تغيير الـ Screen
      drawer: const Sidebar(), // السايد بار للـ Mobile
      appBar: Headers(scaffoldKey: controller.scaffoldKey),
      body: TResponsiveDesign(
        desktop: DesktopLayout(), // لا نمرر body هنا
        tablet: TabletLayout(),
        mobile: MobileLayout(),
      ),
    );
  }
}
*/