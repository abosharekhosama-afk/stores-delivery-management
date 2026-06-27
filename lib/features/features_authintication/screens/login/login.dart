import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/responsive/responsive_design.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/login/responsiv_screens/login_desktop_tablet.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/login/responsiv_screens/login_mobile.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TResponsiveDesign(
      //userLayout: false,
      desktop: LoginDesktopTablet(),
      tablet: LoginDesktopTablet(),
      mobile: LoginMobile(),
    );
  }
}
