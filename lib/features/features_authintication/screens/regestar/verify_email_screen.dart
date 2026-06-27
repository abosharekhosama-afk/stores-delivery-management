import 'package:flutter/widgets.dart';
import 'package:stors_admin_panel/common/widgets/responsive/responsive_design.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/regestar/responsaiv_screen/verify_desktop_tablet.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/regestar/responsaiv_screen/verify_mobole.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TResponsiveDesign(
      //userLayout: false,
      desktop: VerifyDesktopTablet(),
      tablet: VerifyDesktopTablet(),
      mobile: VerifyMobole(),
    );
  }
}
