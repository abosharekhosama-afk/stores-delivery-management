import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stors_admin_panel/data/reposity/repositories.authentication/authentication_repository.dart';
import 'package:stors_admin_panel/data/reposity/store_reposity.dart';
import 'package:stors_admin_panel/features/features_authintication/models/user_stor_model.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class ProfileControllerNew extends GetxController {
  static ProfileControllerNew get instance => Get.find();

  final formKey = GlobalKey<FormState>();
  final _storeRepository = Get.put(StoreRepository());

  // الحقول الأساسية
  final storeName = TextEditingController();
  final storeDescription = TextEditingController();
  final phone = TextEditingController();
  final bankAccount = TextEditingController();
  var storeM = StoreModel.empty().obs;

  var isLogoLoading = false.obs; // لحالة تحميل الصورة
  var isStoreOpen = true.obs; // لحالة المتجر (مفتوح/مغلق) التفاعلية
  @override
  void onInit() {
    super.onInit();
    fetchBasicProfileData();
  }

  /// جلب البيانات الأساسية فقط
  Future<void> fetchBasicProfileData() async {
    try {
      final store = await _storeRepository.getStoreById(
        AuthenticationRepository.instance.authUser!.uid,
      );
      if (store.storeId.isNotEmpty) {
        storeM.value = store;
        storeName.text = store.storName;
        isStoreOpen.value = store.isOpen;
        storeDescription.text = store.storeDescription;
        // هنا يمكنك إضافة جلب الهاتف والحساب البنكي إذا كانت موجودة في المودل
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ في الجلب', message: e.toString());
    }
  }

  /// تحديث البيانات الأساسية فقط
  Future<void> updateBasicProfile() async {
    try {
      if (!formKey.currentState!.validate()) return;

      final Map<String, dynamic> data = {
        StoreModel.getStorName: storeName.text.trim(),
        StoreModel.getStoreDescription: storeDescription.text.trim(),
        // أضf الحقول الأخرى هنا
      };

      await _storeRepository.updateSingleField(
        AuthenticationRepository.instance.authUser!.uid,
        data,
      );
      TLoaders.successSnackBar(
        title: 'تم بنجاح',
        message: 'تم تحديث البيانات الأساسية.',
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: e.toString());
    }
  }

  // دالة اختيار ورفع الصورة

  Future<void> pickAndUploadLogo() async {
    try {
      // 1. اختيار الصورة من المعرض
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // لتقليل حجم الصورة وسرعة الرفع
      );

      if (image == null) return;
      isLogoLoading.value = true;
      // 3. رفع الصورة إلى Firebase Storage
      // نستخدم المسار بناءً على النوع
      String path = 'Stores/Logos';
      final String downloadUrl = await _storeRepository.uploadImage(
        path,
        image,
      );

      // 4. تحديث الحقل في Firestore
      String fieldName = StoreModel.getStoreLogo;
      await _storeRepository.updateSingleField(storeM.value.storeId, {
        fieldName: downloadUrl,
      });

      // 5. تحديث الحالة المحلية لتظهر الصورة فوراً للمستخدم

      storeM.value.storeLogo = downloadUrl;

      storeM.refresh();

      TLoaders.successSnackBar(
        title: 'مبارك',
        message: 'تم تحديث الصورة بنجاح',
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: e.toString());
    } finally {
      isLogoLoading.value = false;
    }
  }

  // دالة تغيير حالة المتجر مباشرة بقاعدة البيانات
  Future<void> toggleStoreOpenStatus(bool value) async {
    try {
      isStoreOpen.value = value;
      await _storeRepository.updateSingleField(storeM.value.storeId, {
        StoreModel.getIsOpen: value,
      });
      TLoaders.successSnackBar(
        title: 'تمت العملية',
        message: value
            ? 'تم فتح المتجر بنجاح لاستقبال الطلبات.'
            : 'تم إغلاق المتجر مؤقتاً.',
      );
    } catch (e) {
      // إرجاع الحالة السابقة في الواجهة لو حدث خطأ بالشبكة أو السيرفر
      isStoreOpen.value = !value;
      TLoaders.errorSnackBar(title: 'خطأ في التحديث', message: e.toString());
    }
  }
}
