import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/responsive/responsive_design.dart';
import 'package:stors_admin_panel/features/features_authintication/controllers/signup_controllers.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/regestar/responsaiv_screen/regestar_desktop_tablet.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/regestar/responsaiv_screen/regestar_mobile.dart';

class Regestar extends StatelessWidget {
  const Regestar({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(StoreSignupController());

    return const TResponsiveDesign(
      // userLayout: false,
      desktop: RegestarDesktopTablet(),
      tablet: RegestarDesktopTablet(),
      mobile: RegestarMobile(),
    );
  }
}
