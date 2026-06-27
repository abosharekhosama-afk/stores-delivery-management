import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:stors_admin_panel/common/styles/spacing_styles.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';
import 'package:stors_admin_panel/utils/constants/text_strings.dart';
import 'package:stors_admin_panel/utils/helpers/helper_functions.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({
    super.key,
    required this.image,
    required this.title,
    required this.subTitle,
    this.onPressed,
    this.isLottie =
        false, // أضفنا خياراً لتحديد ما إذا كان الملف Lottie أم صورة عادية
  });

  final String image, title, subTitle;
  final VoidCallback? onPressed;
  final bool isLottie;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: TSpacingStyle.paddingWithAppBarHeight * 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// 1. الجزء البصري (Lottie Animation أو Image)
              isLottie
                  ? Lottie.asset(
                      image,
                      width: THelperFunctions.screenWidth() * 0.6,
                      fit: BoxFit.contain,
                    )
                  : Image(
                      image: AssetImage(image),
                      width: THelperFunctions.screenWidth() * 0.6,
                    ),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// 2. النصوص (العنوان والوصف)
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),

              Text(
                subTitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// 3. زر المتابعة
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TSizes.buttonRadius),
                    ),
                  ),
                  child: const Text(TTexts.tContinue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
