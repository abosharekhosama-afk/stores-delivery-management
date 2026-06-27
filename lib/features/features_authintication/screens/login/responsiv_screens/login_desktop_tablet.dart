import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/layouts/templates/login_template.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/login/widgets/login_form.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/login/widgets/login_header.dart';

class LoginDesktopTablet extends StatelessWidget {
  const LoginDesktopTablet({super.key});

  @override
  Widget build(BuildContext context) {
    return TLoginTemplate(
      child: Column(children: [TLoginHeader(), TLoginForm()]),
    );
  }
}
