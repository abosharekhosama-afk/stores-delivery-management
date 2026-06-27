import 'package:flutter/widgets.dart';
import 'package:stors_admin_panel/common/widgets/layouts/templates/login_template.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/regestar/widgets/venify_email.dart';

class VerifyDesktopTablet extends StatelessWidget {
  const VerifyDesktopTablet({super.key});

  @override
  Widget build(BuildContext context) {
    return TLoginTemplate(child: VenifyEmailWidget());
  }
}
