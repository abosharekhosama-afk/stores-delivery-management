import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stors_admin_panel/data/Driver/model/driver_model.dart';
import 'package:stors_admin_panel/data/reposity/driver/driver_authentication_repository.dart';
import 'package:stors_admin_panel/data/reposity/repositories.authentication/authentication_repository.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class DriverAuthController extends GetxController {
  static DriverAuthController get instance => Get.find();

  // الحقول النصية
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  final phone = TextEditingController();

  // مفتاح الفورم للتحقق من البيانات (Validation)
  GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  var isLoading = false.obs;
  final _db = FirebaseFirestore.instance;

  // تسجيل حساب مندوب جديد
  Future<void> signupDriver() async {
    try {
      isLoading.value = true;

      // 1. التحقق من صحة البيانات المدخلة في الواجهة
      if (!signupFormKey.currentState!.validate()) {
        isLoading.value = false;
        return;
      }

      // 2. استخدام المستودع لإنشاء الحساب في Firebase Auth
      final userCredential = await DriverAuthenticationRepository.instance
          .registerWithEmailAndPassword(
            email.text.trim(),
            password.text.trim(),
          );

      // 3. تجهيز بيانات المندوب لحفظها في Firestore
      final newDriver = {
        DriverModel.fldId: userCredential.user!.uid,
        DriverModel.fldName: name.text.trim(),
        DriverModel.fldEmail: email.text.trim(),
        DriverModel.fldPhone: phone.text.trim(),
        DriverModel.fldRole: 'driver',
        DriverModel.fldIsActive: false,
        DriverModel.fldCreatedAt: DateTime.now(),
      };

      // 4. الحفظ في كولكشن المناديب الخاص
      await _db
          .collection(DriverModel.driverCollectionName)
          .doc(userCredential.user!.uid)
          .set(newDriver);

      // 5. إرسال بريد التحقق
      await DriverAuthenticationRepository.instance.sendEmailVerification();
      AuthenticationRepository.instance.screenRedirect();
      TLoaders.successSnackBar(
        title: "نجاح",
        message: "تم إنشاء الحساب بنجاح، يرجى تفعيل البريد الإلكتروني",
      );

      // التوجيه سيتم تلقائياً عبر screenRedirect في المستودع
    } catch (e) {
      await AuthenticationRepository.instance
          .deleteAccount(); // تنظيف الحساب الفاشل
      TLoaders.errorSnackBar(title: "خطأ", message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // تسجيل دخول المندوب
  Future<void> loginDriver() async {
    try {
      isLoading.value = true;

      // التحقق من الفورم
      if (!loginFormKey.currentState!.validate()) {
        isLoading.value = false;
        return;
      }

      // استخدام المستودع لتسجيل الدخول
      await DriverAuthenticationRepository.instance.loginWithEmailAndPassword(
        email.text.trim(),
        password.text.trim(),
      );
      AuthenticationRepository.instance.screenRedirect();

      // ملاحظة: المستودع سيقوم تلقائياً بفحص كولكشن DeliveryDrivers
      // وتوجيه المستخدم للـ Dashboard المناسبة عبر دالة screenRedirect
    } catch (e) {
      TLoaders.errorSnackBar(title: "خطأ في الدخول", message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
