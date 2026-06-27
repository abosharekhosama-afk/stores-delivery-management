import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/layouts/headers/headers.dart';
import 'package:stors_admin_panel/common/widgets/layouts/sidebars/sidebar.dart';
import 'package:stors_admin_panel/common/widgets/layouts/sidebars/sidebar_controller.dart';

class TabletLayout extends StatelessWidget {
  const TabletLayout({super.key, this.body});
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    final controller = SidebarController.instance;
    return Scaffold(
      key: controller.scaffoldKey,
      drawer: const Sidebar(),
      appBar: Headers(scaffoldKey: controller.scaffoldKey),
      body: body ?? const SizedBox(),
    );
  }
}

/*class TabletLayout extends StatelessWidget {
  TabletLayout({super.key, this.body});
  final Widget? body;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      drawer: const Sidebar(),
      appBar: Headers(scaffoldKey: scaffoldKey),
      body: body ?? const SizedBox(),
    );
  }
}*/
