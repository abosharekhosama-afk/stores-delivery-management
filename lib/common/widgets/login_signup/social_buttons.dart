import 'package:flutter/material.dart';
import 'package:get/instance_manager.dart';
import 'package:stors_admin_panel/features/features_authintication/controllers/signup_controllers.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/image_strings.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class Tsocialbuttons extends StatelessWidget {
  const Tsocialbuttons({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(StoreSignupController());
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: TColors.grey),
          ),
          child: IconButton(
            onPressed: () {},
            icon: Image(
              height: TSizes.iconMd,
              width: TSizes.iconMd,
              image: AssetImage(TImages.facebook),
            ),
          ),
        ),
        const SizedBox(width: TSizes.spaceBtwItems),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: TColors.grey),
          ),
          child: IconButton(
            onPressed: () {},
            icon: Image(
              height: TSizes.iconMd,
              width: TSizes.iconMd,
              image: AssetImage(TImages.google),
            ),
          ),
        ),
      ],
    );
  }
}
