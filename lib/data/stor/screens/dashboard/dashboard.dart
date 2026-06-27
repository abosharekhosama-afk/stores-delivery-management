import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/responsive/responsive_design.dart';
import 'package:stors_admin_panel/data/stor/controller/dashboard_controller.dart';
import 'package:stors_admin_panel/data/stor/screens/dashboard/responsive_screens/dashboard_desktop_tablit.dart';
import 'package:stors_admin_panel/data/stor/screens/dashboard/responsive_screens/dashboard_mobail.dart';
import 'package:stors_admin_panel/data/stor/screens/dashboard/responsive_screens/dashboard_tablit.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(DashboardController());
    return TResponsiveDesign(
      desktop: DashboardDesktopTablit(),
      tablet: DashboardTablet(),
      mobile: DashboardMobail(),
    );
  }
}
