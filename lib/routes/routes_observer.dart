import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/layouts/sidebars/sidebar_controller.dart';
import 'package:stors_admin_panel/routes/routes.dart';

class RoutesObserver extends GetObserver {
  @override
  void didPop(Route<dynamic>? route, Route<dynamic>? previousRoute) {
    // TODO: implement didPop
    final sidbarController = Get.put(SidebarController());

    if (previousRoute != null) {
      for (var routName in TRoutes.sidbarMenuItems) {
        if (previousRoute.settings.name == routName) {
          sidbarController.activeItem.value = routName;
        }
      }
    }
  }
}
