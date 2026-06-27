import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/responsive/responsive_design.dart';
import 'package:stors_admin_panel/features/media/screens/respnosive_screens/media_desktop.dart';
import 'package:stors_admin_panel/features/media/screens/respnosive_screens/media_mobile.dart';
import 'package:stors_admin_panel/features/media/screens/respnosive_screens/media_tablet.dart';

class MediaScreen extends StatelessWidget {
  const MediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TResponsiveDesign(
      desktop: MediaDesktop(),
      tablet: MediaTablet(),
      mobile: MediaMobile(),
    );
  }
}
