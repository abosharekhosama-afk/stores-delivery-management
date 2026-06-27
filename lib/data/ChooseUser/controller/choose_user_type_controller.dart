import 'package:get/get.dart';
import 'package:stors_admin_panel/routes/routes.dart'; // تأكد من استيراد ملف المسارات الخاص بك

class ChooseUserTypeController extends GetxController {
  static ChooseUserTypeController get instance => Get.find();

  /// التوجه لصفحة تسجيل دخول التاجر
  void navigateToMerchantLogin() {
    Get.toNamed(TRoutes.login); // تأكد من تعريف هذا المسار
  }

  /// التوجه لصفحة تسجيل دخول المندوب
  void navigateToDriverLogin() {
    Get.toNamed(TRoutes.driverLogin); // تأكد من تعريف هذا المسار
  }
}
