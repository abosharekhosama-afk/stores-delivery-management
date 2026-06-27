import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/layouts/headers/headers.dart';
import 'package:stors_admin_panel/common/widgets/layouts/sidebars/sidebar.dart';
import 'package:stors_admin_panel/common/widgets/layouts/sidebars/sidebar_controller.dart';

class Tsitelayoutwithhedar extends StatelessWidget {
  const Tsitelayoutwithhedar({super.key, this.screen, this.userLayout = true});
  final Widget? screen;

  final bool userLayout;
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SidebarController(), permanent: true);
    return Scaffold(
      key: controller.scaffoldKey,
      // نستخدم Obx هنا لضمان تحديث الشاشة بالكامل عند تغيير الـ Screen
      drawer: const Sidebar(), // السايد بار للـ Mobile
      appBar: Headers(scaffoldKey: controller.scaffoldKey),
      body: screen,
    );
  }
}
