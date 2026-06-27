import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:stors_admin_panel/data/reposity/repositories.authentication/authentication_repository.dart';
import 'package:stors_admin_panel/utils/constants/image_strings.dart';
import 'package:stors_admin_panel/utils/helpers/network_manager.dart';
import 'package:stors_admin_panel/utils/popups/full_screen_loader.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();
  final localStorage = GetStorage();
  final email = TextEditingController();
  final password = TextEditingController();
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  final rememberMe = false.obs;
  final hidePassword = true.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    email.text = localStorage.read("REMEMBER_ME_EMAIL") ?? "";
    password.text = localStorage.read("REMEMBER_ME_PASSWORD") ?? "";
    super.onInit();
  }

  Future<void> emailAndpasswordLoginin() async {
    try {
      // Validate inputs before showing the loading indicator.
      if (!loginFormKey.currentState!.validate()) {
        return;
      }
      TFullScreenLoader.openLoadingDialog(
        "Logging tou in...",
        TImages.docerAnimation,
      );

      final isConected = await NetworkManager.instance.isConnected();
      if (!isConected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      if (rememberMe.value) {
        localStorage.write("REMEMBER_ME_EMAIL", email.text.trim());
        localStorage.write("REMEMBER_ME_PASSWORD", password.text.trim());
      }

      await AuthenticationRepository.instance.loginWithEmailAndPassword(
        email.text.trim(),
        password.text.trim(),
      );
      TFullScreenLoader.stopLoading();
      AuthenticationRepository.instance.screenRedirect();
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: "On Snap!", message: e.toString());
    }
  }

  /*
  Future<void> googleSignIn() async {
    try {
      // 1. التحقق من الإنترنت
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) return;

      // 2. بدء التحميل
      TFullScreenLoader.openLoadingDialog(
        "جاري تسجيل الدخول...",
        TImages.docerAnimation,
      );

      // 3. تنفيذ تسجيل الدخول بجوجل
      final userCredentials = await AuthenticationRepository.instance
          .signInWithGoogle();

      // إذا ألغى المستخدم تسجيل الدخول
      if (userCredentials == null) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // 4. التحقق إذا كان المستخدم جديداً لحفظ بياناته (أو تحديثها)
      final storeRepository = Get.put(StoreRepository());

      // ملاحظة: دالة saveStoreRecord يجب أن تحتوي داخلياً على فحص
      // if (!doc.exists) لضمان عدم المسح فوق البيانات القديمة
      await storeRepository.saveStoreRecord(userCredentials);

      TFullScreenLoader.stopLoading();

      // 5. التوجيه للشاشة المناسبة
      AuthenticationRepository.instance.screenRedirect();
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: "عذراً!", message: e.toString());
    }
  }
*/
  /*
  Future<void> googleSignIn() async {
    try {
      TFullScreenLoader.openLoadingDialog(
        "Logging tou in...",
        TImages.docerAnimation,
      );

      final isConected = await NetworkManager.instance.isConnected();
      if (!isConected) {
        TFullScreenLoader.stopLoading();
        return;
      }
      final storCredentials = await AuthenticationRepository.instance
          .signInWithGoogle();
      final storeRepository = StoreRepository.instance;

      await storeRepository.saveStoreRecord(storCredentials);
      TFullScreenLoader.stopLoading();
      AuthenticationRepository.instance.screenRedirect();
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: "Oh Snap", message: e.toString());
    }
  }
*/
}
