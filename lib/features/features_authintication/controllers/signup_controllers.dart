import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/reposity/repositories.authentication/authentication_repository.dart';
import 'package:stors_admin_panel/data/reposity/store_reposity.dart';
import 'package:stors_admin_panel/features/features_authintication/models/address_model.dart';
import 'package:stors_admin_panel/features/features_authintication/models/user_stor_model.dart';
import 'package:stors_admin_panel/features/features_authintication/models/wallet_model.dart';
import 'package:stors_admin_panel/routes/routes.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/constants/image_strings.dart';
import 'package:stors_admin_panel/utils/helpers/network_manager.dart';
import 'package:stors_admin_panel/utils/popups/full_screen_loader.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class StoreSignupController extends GetxController {
  static StoreSignupController get instance => Get.find();

  final hidePassword = true.obs;
  final privacyPolice = true.obs;
  GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final lastName = TextEditingController();
  final password = TextEditingController();
  final firstName = TextEditingController();
  final phoneNumber = TextEditingController();

  Future<void> signup() async {
    try {
      // Validate fields before showing the loading dialog.

      TFullScreenLoader.openLoadingDialog(
        "... يتم معالجة بياناتك",
        TImages.docerAnimation,
      );

      if (!signupFormKey.currentState!.validate()) {
        return;
      }

      if (!privacyPolice.value) {
        TLoaders.warningSnackBar(
          title: "Accept Privacy policy",
          message:
              "In arder to creat account you must have to read and accept the privacy policy & Term of Use.",
        );
        return;
      }

      final isConected = await NetworkManager.instance.isConnected();
      if (!isConected) {
        TFullScreenLoader.stopLoading();
        TLoaders.warningSnackBar(
          title: "لا يوجد اتصال",
          message: "الرجاء التحقق من اتصال الانترنت و المحاولة مرة اخرى.",
        );
        return;
      }

      final userCardentil = await AuthenticationRepository.instance
          .regesterWithEmailAndPassword(
            email.text.trim(),
            password.text.trim(),
          );

      final newStore = StoreModel(
        storeId: userCardentil.user!.uid,
        firstName: firstName.text.trim(),
        lastName: lastName.text.trim(),
        storName: "",
        banckAcountNumber: "",
        email: email.text.trim(),
        phoneNumber: phoneNumber.text.trim(),
        profilePicture: "",
        storeLogo: "",
        storeBanner: "",
        storeDescription: "",
        addressModel: AddressModel.empty(),
        isOpen: false,
        workingHours: null,
        storeStatus: StoreStatus.pending,
        isVerified: false,
        commissionRate: 0.0,
        totalSales: 0.0,
        rating: 0.0,
        wallet: WalletModel(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final storeRepository = Get.isRegistered<StoreRepository>()
          ? StoreRepository.instance
          : Get.put(StoreRepository());
      await storeRepository.saveStoreRecord(newStore);

      // Send email verification
      await AuthenticationRepository.instance.sendEmailVerify();
      TFullScreenLoader.stopLoading();
      TLoaders.successSnackBar(
        title: "مبارك",
        message:
            "تم انشاء حسابك! الرجاء تفقد البريد الالكتروني و التحقق من الحساب.",
      );

      // Redirect to email verification screen
      Get.toNamed(TRoutes.verifyEmail, arguments: email.text.trim());
    } catch (e) {
      await AuthenticationRepository.instance
          .deleteAccount(); // تنظيف الحساب الفاشل
      TLoaders.errorSnackBar(title: "خطا!", message: e.toString());
    } finally {
      TFullScreenLoader.stopLoading();
    }
  }
}
