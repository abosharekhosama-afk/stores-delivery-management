import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/success_screen/success_screen.dart';
import 'package:stors_admin_panel/data/reposity/repositories.authentication/authentication_repository.dart';
import 'package:stors_admin_panel/utils/constants/image_strings.dart';
import 'package:stors_admin_panel/utils/constants/text_strings.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class VerifyEmailController extends GetxController {
  static VerifyEmailController get instance => Get.find();

  Timer? _timer;

  @override
  void onInit() {
    sendEmailVerification();
    setTimerForAutoRedirect();
    super.onInit();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  sendEmailVerification() async {
    try {
      await AuthenticationRepository.instance.sendEmailVerify();
      TLoaders.successSnackBar(
        title: "Email Sent",
        message: "Please check your inbox and verify your email.",
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: "Oh Snap!", message: e.toString());
    }
  }

  setTimerForAutoRedirect() {
    const maxWaitTime = Duration(minutes: 5); // Maximum wait time of 5 minutes
    final startTime = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        await FirebaseAuth.instance.currentUser?.reload();
        final user = FirebaseAuth.instance.currentUser;

        // Check if email is verified
        if (user?.emailVerified ?? false) {
          timer.cancel();
          _navigateToSuccessScreen();
          return;
        }

        // Check if maximum wait time has been exceeded
        if (DateTime.now().difference(startTime) > maxWaitTime) {
          timer.cancel();
          TLoaders.warningSnackBar(
            title: "Time Out",
            message:
                "Email verification is taking longer than expected. Please try again later.",
          );
          return;
        }
      } catch (e) {
        timer.cancel();
        TLoaders.errorSnackBar(
          title: "Error",
          message: "Failed to check email verification status.",
        );
      }
    });
  }

  void _navigateToSuccessScreen() {
    Get.off(
      () => SuccessScreen(
        image: TImages.successfullyRegisterAnimation,
        title: TTexts.yourAccountCreatedTitle,
        subTitle: TTexts.yourAccountCreatedSubTitle,
        onPressed: () => AuthenticationRepository.instance.screenRedirect(),
      ),
    );
  }

  checkEmailVerificationStatus() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.emailVerified) {
        _timer?.cancel();
        _navigateToSuccessScreen();
      } else {
        TLoaders.warningSnackBar(
          title: 'لم يتم التحقق',
          message: 'يرجى تفعيل الحساب من خلال الرابط المرسل لبريدك أولاً.',
        );
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: "خطا",
        message: "فشل من التحقق من حالة الحساب.",
      );
    }
  }

  void resendEmailVerification() {
    sendEmailVerification();
  }
}
