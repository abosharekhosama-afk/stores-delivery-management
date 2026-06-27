import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/layouts/templates/login_template.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/reset_password/widgets/reset_password_widget.dart';

class ResetPasswordDesktopTablit extends StatelessWidget {
  const ResetPasswordDesktopTablit({super.key});

  @override
  Widget build(BuildContext context) {
    final email = Get.parameters["Email"] ?? "";
    return TLoginTemplate(child: ResetPasswordWidget());
  }
}
