import 'package:flutter/material.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/login/widgets/login_form.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/login/widgets/login_header.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class LoginMobile extends StatelessWidget {
  const LoginMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(TSizes.defaultSpace),
          child: Column(children: [TLoginHeader(), TLoginForm()]),
        ),
      ),
    );
  }
}
