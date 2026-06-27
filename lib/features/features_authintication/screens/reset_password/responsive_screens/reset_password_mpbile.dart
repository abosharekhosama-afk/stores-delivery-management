import 'package:flutter/material.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/reset_password/widgets/reset_password_widget.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class ResetPasswordMpbile extends StatelessWidget {
  const ResetPasswordMpbile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(TSizes.defaultSpace),
          child: ResetPasswordWidget(),
        ),
      ),
    );
  }
}
