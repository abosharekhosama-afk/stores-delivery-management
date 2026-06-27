import 'package:flutter/material.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/forget_password/widgets/header_and_form.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class ForgetPasswordMobile extends StatelessWidget {
  const ForgetPasswordMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: HeaderAndForm(),
        ),
      ),
    );
  }
}
