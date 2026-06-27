import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/layouts/templates/login_template.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/forget_password/widgets/header_and_form.dart';

class ForgetPasswordDesktopTablet extends StatelessWidget {
  const ForgetPasswordDesktopTablet({super.key});

  @override
  Widget build(BuildContext context) {
    return TLoginTemplate(child: HeaderAndForm());
  }
}
