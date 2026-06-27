import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/responsive/responsive_design.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/forget_password/responsive_screens/forget_password_desktop_tablet.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/forget_password/responsive_screens/forget_password_mobile.dart';

class ForgetPassword extends StatelessWidget {
  const ForgetPassword({super.key});

  @override
  Widget build(BuildContext context) {
    return TResponsiveDesign(
      // userLayout: false,
      desktop: ForgetPasswordDesktopTablet(),
      mobile: ForgetPasswordMobile(),
      tablet: ForgetPasswordDesktopTablet(),
    );
  }
}
