import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/routes/routes.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class HeaderAndForm extends StatelessWidget {
  const HeaderAndForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Iconsax.arrow_left),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        Text("كلمة المرور", style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: TSizes.spaceBtwItems),
        Text(
          "هل نسيت كلمة المرور",
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        Form(
          child: TextFormField(
            decoration: InputDecoration(
              labelText: "البريد الالكتروني",
              prefixIcon: Icon(Iconsax.direct_right),
            ),
          ),
        ),

        SizedBox(height: TSizes.spaceBtwSections),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Get.toNamed(
              TRoutes.resetPassword,
              parameters: {"Email": "Osama@gmail.com"},
            ),
            child: Text("اعادة التعيين"),
          ),
        ),
        SizedBox(height: TSizes.spaceBtwSections * 2),
      ],
    );
  }
}
