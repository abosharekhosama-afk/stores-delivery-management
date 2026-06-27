import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart'; // تأكد من إضافة lottie في pubspec.yaml
import 'package:stors_admin_panel/routes/routes.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/image_strings.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';
import 'package:stors_admin_panel/utils/helpers/helper_functions.dart';

class AccountStatusScreen extends StatelessWidget {
  const AccountStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // جلب الرسالة الممررة عبر arguments
    final message = Get.arguments ?? "تم تعليق حسابك مؤقتاً لمراجعة السياسات.";
    final isDark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      // استخدام AppBar بسيط بدون زر رجوع لضمان عدم خروج المستخدم للشاشات السابقة
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => Get.offAllNamed(TRoutes.login),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: TSizes.spaceBtwSections),

              /// 1. الجزء البصري (Animation)
              // يفضل استخدام ملف Lottie يعبر عن حالة الانتظار أو القفل
              Lottie.asset(
                TImages
                    .docerAnimation, // استبدلها بـ TImages.accountSuspendedAnimation إذا توفرت
                width: MediaQuery.of(context).size.width * 0.6,
                height: MediaQuery.of(context).size.width * 0.6,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// 2. العنوان الرئيسي
              Text(
                "حالة الحساب",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? TColors.white : TColors.dark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// 3. الرسالة التوضيحية
              Container(
                padding: const EdgeInsets.all(TSizes.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? TColors.darkerGrey
                      : TColors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                    color: isDark ? TColors.lightGrey : TColors.darkGrey,
                  ),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections * 1.5),

              /// 4. أزرار التحكم
              Column(
                children: [
                  // زر العودة الأساسي
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Get.offAllNamed(TRoutes.login),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: TSizes.buttonHeight,
                        ),
                      ),
                      child: const Text("العودة لتسجيل الدخول"),
                    ),
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),

                  // زر التواصل مع الدعم
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // هنا يمكنك فتح الواتساب أو البريد الإلكتروني
                      },
                      icon: const Icon(Icons.support_agent_rounded),
                      label: const Text("اتصل بالدعم الفني"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: TSizes.spaceBtwSections),

              /// 5. تذييل الصفحة (Footer)
              Text(
                "إذا كنت تعتقد أن هذا خطأ، يرجى تزويدنا برقم التعريف الخاص بك.",
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
