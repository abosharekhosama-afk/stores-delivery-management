import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/login_signup/social_buttons.dart';
import 'package:stors_admin_panel/common/widgets/login_signup/form_divider.dart';
import 'package:stors_admin_panel/features/features_authintication/controllers/signup_controllers.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/login/widgets/login_header.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/regestar/widgets/signUpForm.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';
import 'package:stors_admin_panel/utils/constants/text_strings.dart';

class RegestarMobile extends StatelessWidget {
  const RegestarMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = StoreSignupController.instance;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              TLoginHeader(),
              const SizedBox(height: TSizes.spaceBtwSections),
              Signupform(),
              const SizedBox(height: TSizes.spaceBtwSections),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => controller.signup(),
                  child: Text(TTexts.createAccount),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),
              TFormDivider(dividerText: "or"),
              Tsocialbuttons(),
              const SizedBox(height: TSizes.spaceBtwSections),
            ],
          ),
        ),
      ),
    );
  }
}
