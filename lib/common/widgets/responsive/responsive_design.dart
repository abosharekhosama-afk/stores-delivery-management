import 'package:flutter/cupertino.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class TResponsiveDesign extends StatelessWidget {
  const TResponsiveDesign({
    super.key,
    required this.desktop,
    required this.tablet,
    required this.mobile,
  });
  final Widget desktop;
  final Widget tablet;
  final Widget mobile;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= TSizes.desktopScreenSize) {
          return desktop;
        } else if (constraints.maxWidth < TSizes.desktopScreenSize &&
            constraints.maxWidth >= TSizes.tabletScreenSize) {
          return tablet;
        } else {
          return mobile;
        }
      },
    );
  }
}
