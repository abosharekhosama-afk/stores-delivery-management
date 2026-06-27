import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stors_admin_panel/data/reposity/repositories.authentication/authentication_repository.dart';
import 'package:stors_admin_panel/data/reposity/store_reposity.dart';
import 'package:stors_admin_panel/features/features_authintication/models/user_stor_model.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class StoreController extends GetxController {
  static StoreController get instance => Get.find();

  // الحالة (Loading)
  final profileLoading = false.obs;
  final updateLoading = false.obs;
  final imageLoading = false.obs;
  final bannerLoading = false.obs;

  // البيانات
  Rx<StoreModel> store = StoreModel.empty().obs;
  final repository = Get.put(StoreRepository());

  // المتحكمات في النصوص
  late TextEditingController firstName;
  late TextEditingController lastName;
  late TextEditingController phone;
  late TextEditingController bankAccount;

  @override
  void onInit() {
    super.onInit();
    firstName = TextEditingController();
    lastName = TextEditingController();
    phone = TextEditingController();
    bankAccount = TextEditingController();
    fetchStoreRecord(); // جلب البيانات عند بدء التشغيل
  }

  /// --- جلب البيانات ---
  Future<void> fetchStoreRecord() async {
    try {
      profileLoading.value = true;
      // استبدل 'YOUR_STORE_ID' بمعرف التاجر الحالي (من الـ Auth مثلاً)
      final storeId = AuthenticationRepository.instance.authUser!.uid;
      final storeData = await repository.fetchStoreDetails(storeId);
      store.value = storeData;

      // تعبئة النصوص
      firstName.text = storeData.firstName;
      lastName.text = storeData.lastName;
      phone.text = storeData.phoneNumber;
      bankAccount.text = storeData.banckAcountNumber;
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: e.toString());
    } finally {
      profileLoading.value = false;
    }
  }

  /// --- تحديث البيانات ---
  Future<void> updateStoreInformation() async {
    try {
      updateLoading.value = true;

      // 1. تجميع البيانات المعدلة
      final updatedData = {
        StoreModel.getFirstName: firstName.text.trim(),
        StoreModel.getLastName: lastName.text.trim(),
        StoreModel.getPhoneNumber: phone.text.trim(),
        StoreModel.getBanckAcountNumber: bankAccount.text.trim(),
        StoreModel.getUpdatedAt: DateTime.now(),
      };

      // 2. التحديث في Firestore
      await repository.updateSingleField(store.value.storeId, updatedData);

      // 3. تحديث الحالة المحلية للمستخدم لرؤية النتائج فوراً
      store.value.firstName = firstName.text.trim();
      store.value.lastName = lastName.text.trim();
      store.value.phoneNumber = phone.text.trim();
      store.value.banckAcountNumber = bankAccount.text.trim();

      store.refresh(); // لتحديث واجهة المستخدم

      TLoaders.successSnackBar(
        title: 'تم بنجاح',
        message: 'تم تحديث بياناتك الأساسية.',
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: e.toString());
    } finally {
      updateLoading.value = false;
    }
  }

  /// --- دالة اختيار ورفع الصورة (سواء بروفايل أو بانر) ---
  Future<void> updateStoreImage(bool isProfilePicture) async {
    try {
      // 1. اختيار الصورة من المعرض
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // لتقليل حجم الصورة وسرعة الرفع
      );

      if (image == null) return;

      // 2. بدء حالة التحميل بناءً على نوع الصورة
      if (isProfilePicture) {
        imageLoading.value = true;
      } else {
        bannerLoading.value = true;
      }

      // 3. رفع الصورة إلى Firebase Storage
      // نستخدم المسار بناءً على النوع
      String path = isProfilePicture ? 'Stores/Profiles' : 'Stores/Banners';
      final String downloadUrl = await repository.uploadImage(path, image);

      // 4. تحديث الحقل في Firestore
      String fieldName = isProfilePicture ? 'profilePicture' : 'storeBanner';
      await repository.updateSingleField(store.value.storeId, {
        fieldName: downloadUrl,
      });

      // 5. تحديث الحالة المحلية لتظهر الصورة فوراً للمستخدم
      if (isProfilePicture) {
        store.value.profilePicture = downloadUrl;
      } else {
        store.value.storeBanner = downloadUrl;
      }
      store.refresh();

      TLoaders.successSnackBar(
        title: 'مبارك',
        message: 'تم تحديث الصورة بنجاح',
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: e.toString());
    } finally {
      imageLoading.value = false;
      bannerLoading.value = false;
    }
  }
}
