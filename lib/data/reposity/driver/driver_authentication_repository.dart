import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:stors_admin_panel/routes/routes.dart'; // تأكد من وجود مسارات المندوب هنا
import 'package:stors_admin_panel/utils/exceptions/firebase_auth_exceptions.dart';
import 'package:stors_admin_panel/utils/exceptions/firebase_exceptions.dart';
import 'package:stors_admin_panel/utils/exceptions/format_exceptions.dart';
import 'package:stors_admin_panel/utils/exceptions/platform_exceptions.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class DriverAuthenticationRepository extends GetxController {
  static DriverAuthenticationRepository get instance => Get.find();

  // المتغيرات
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final deviceStorage = GetStorage();

  // الحصول على بيانات المستخدم الحالي
  User? get authUser => _auth.currentUser;

  @override
  void onReady() {
    // FlutterNativeSplash.remove();
    //screenRedirect();
  }

  /// --- وظيفة التوجيه الذكي (Screen Redirect) ---
  /// تفحص هل المستخدم مسجل، وهل هو مندوب فعلاً قبل إدخاله
  void screenRedirect() async {
    final user = _auth.currentUser;

    if (user != null) {
      // التحقق من وجود المندوب في Firestore لضمان الصلاحية
      try {
        final driverDoc = await _db
            .collection("DeliveryDrivers")
            .doc(user.uid)
            .get();

        if (driverDoc.exists) {
          if (user.emailVerified) {
            // توجيه لصفحة المندوب الرئيسية (يجب تعريفها في TRoutes)
            Get.offAllNamed(TRoutes.driverDashboard);
          } else {
            Get.offAllNamed(TRoutes.verifyEmail, arguments: user.email);
          }
        } else {
          // إذا كان الحساب غير موجود في كولكشن المناديب (مثلاً تاجر يحاول الدخول)
          await logout();
          TLoaders.errorSnackBar(
            title: "خطأ في الصلاحيات",
            message: "هذا الحساب ليس لديه صلاحيات المندوب.",
          );
        }
      } catch (e) {
        await logout();
      }
    } else {
      Get.offAllNamed(TRoutes.login);
    }
  }

  /// --- تسجيل الدخول (LOGIN) ---
  Future<UserCredential> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطأ غير متوقع. الرجاء المحاولة مجدداً";
    }
  }

  /// --- إنشاء حساب مندوب جديد (REGISTER) ---
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw "فشل إنشاء الحساب. حاول مرة أخرى.";
    }
  }

  /// --- إرسال بريد التحقق (EMAIL VERIFICATION) ---
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } catch (e) {
      throw "تعذر إرسال بريد التحقق.";
    }
  }

  /// --- إعادة تعيين كلمة المرور (PASSWORD RESET) ---
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } catch (e) {
      throw "حدث خطأ أثناء محاولة إرسال رابط استعادة كلمة المرور.";
    }
  }

  /// --- إعادة المصادقة (للحماية قبل العمليات الحساسة) ---
  Future<void> reAuthenticateEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await _auth.currentUser!.reauthenticateWithCredential(credential);
    } catch (e) {
      throw 'فشلت عملية المصادقة. تأكد من البيانات.';
    }
  }

  /// --- تسجيل الخروج (LOGOUT) ---
  Future<void> logout() async {
    try {
      await _auth.signOut();
      Get.offAllNamed(TRoutes.login);
    } catch (e) {
      throw "حدث خطأ أثناء تسجيل الخروج.";
    }
  }

  /// --- حذف الحساب (DELETE ACCOUNT) ---
  Future<void> deleteAccount() async {
    try {
      // يمكنك هنا إضافة كود لحذف بياناته من كولكشن DeliveryDrivers أولاً
      await _auth.currentUser?.delete();
    } catch (e) {
      throw "حدث خطأ أثناء حذف الحساب.";
    }
  }
}
