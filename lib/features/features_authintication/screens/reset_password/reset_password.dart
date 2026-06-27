import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/responsive/responsive_design.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/reset_password/responsive_screens/reset_password_desktop_tablit.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/reset_password/responsive_screens/reset_password_mpbile.dart';

class ResetPassword extends StatelessWidget {
  const ResetPassword({super.key});

  @override
  Widget build(BuildContext context) {
    return TResponsiveDesign(
      //userLayout: false,
      desktop: ResetPasswordDesktopTablit(),
      mobile: ResetPasswordMpbile(),
      tablet: ResetPasswordDesktopTablit(),
    );
  }
}
