import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/responsive/responsive_design.dart';
import 'package:stors_admin_panel/features/personalizatuon/screens/profile/responsive_desine/profile_desktop.dart';
import 'package:stors_admin_panel/features/personalizatuon/screens/profile/responsive_desine/profile_mobile.dart';
import 'package:stors_admin_panel/features/personalizatuon/screens/profile/responsive_desine/profile_tablet.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return TResponsiveDesign(
      desktop: ProfileDesktop(),
      mobile: ProfileMobile(),
      tablet: ProfileTablet(),
    );
  }
}
