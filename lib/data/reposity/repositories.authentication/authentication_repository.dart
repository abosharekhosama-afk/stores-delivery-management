import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:stors_admin_panel/data/Driver/model/driver_model.dart';
import 'package:stors_admin_panel/features/features_authintication/models/user_stor_model.dart';
import 'package:stors_admin_panel/routes/routes.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/constants/image_strings.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';
import 'package:stors_admin_panel/utils/device/device_utility.dart';
import 'package:stors_admin_panel/utils/exceptions/firebase_auth_exceptions.dart';
import 'package:stors_admin_panel/utils/exceptions/firebase_exceptions.dart';
import 'package:stors_admin_panel/utils/exceptions/format_exceptions.dart';
import 'package:stors_admin_panel/utils/exceptions/platform_exceptions.dart';
import 'package:stors_admin_panel/utils/popups/full_screen_loader%20copy.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  final deviceStorage = GetStorage();
  final _auth = FirebaseAuth.instance;

  User? get authUser => _auth.currentUser;

  bool get isAuthentication => _auth.currentUser != null;

  /// عند تشغيل التطبيق، نقرأ القيمة المخزنة (إن وجدت) وتحويلها لـ Enum
  AppRole? get role {
    String? storedRole = deviceStorage.read('USER_ROLE');
    if (storedRole == null) return null;
    try {
      return AppRole.values.firstWhere((e) => e.name == storedRole);
    } catch (_) {
      return null;
    }
  }

  /// تعيين الدور وحفظه في الجهاز
  set role(AppRole? value) {
    if (value != null) deviceStorage.write('USER_ROLE', value.name);
  }

  @override
  void onReady() {
    //FlutterNativeSplash.remove();
    if (TDeviceUtils.isDesktopScreen(Get.context!)) {
      _auth.setPersistence(Persistence.LOCAL);
    }

    Future.delayed(const Duration(milliseconds: 500), () => screenRedirect());
  }

  // داخل AuthenticationRepository

  // دالة التوجيه الذكية
  void screenRedirect() async {
    final user = _auth.currentUser;

    // 1. فحص تسجيل الدخول (محلي وسريع)
    if (user == null) {
      Get.offAllNamed(TRoutes.chooseUserType);
      return;
    }

    // 2. التوجيه المتفائل (Optimistic Routing)
    // نجلب الدور المخزن محلياً من آخر جلسة دخول
    String? localRole = deviceStorage.read('USER_ROLE');
    //await user.reload();
    bool isEmailVerified = user.emailVerified;

    if (localRole != null && isEmailVerified) {
      // توجيه فوري دون انتظار الـ Firebase

      _redirectToHome(role);

      // في الخلفية: نحدث البيانات للتأكد من أن الحساب لا يزال فعالاً
      _silentCheck(user);
      return;
    }

    // 3. إذا لم يوجد دور مخزن أو الإيميل غير موثق، نبدأ المسار التقليدي
    if (!isEmailVerified) {
      Get.offAllNamed(TRoutes.verifyEmail, arguments: user.email);
      return;
    }

    // 4. المسار البطيء (أول مرة دخول فقط أو بعد تسجيل الخروج)
    await fetchAndSaveRole(user);
  }

  // دالة جلب البيانات وحفظها محلياً
  Future<void> fetchAndSaveRole(User user) async {
    try {
      TFullScreenLoader.openLoadingDialog(
        'جاري تهيئة الحساب...',
        TImages.docerAnimation,
      );
      print("خطا Future");
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection(DriverModel.driverCollectionName)
            .doc(user.uid)
            .get(),
        FirebaseFirestore.instance
            .collection(StoreModel.getStoreCollectionName)
            .doc(user.uid)
            .get(),
      ]);
      print("خطا results");

      // 1. أغلق الديالوج أولاً
      TFullScreenLoader.stopLoading();

      // 2. انتظر قليلاً لضمان استقرار الـ Navigation Stack
      await Future.delayed(const Duration(milliseconds: 200));

      final driverDoc = results[0];
      final storeDoc = results[1];

      if (driverDoc.exists) {
        bool isActive = driverDoc.data()?['isActive'] ?? false;
        if (isActive) {
          print("خطا");
          role = AppRole.driver;
          _redirectToHome(AppRole.driver);
        } else {
          // إذا لم يكن مفعلاً، يجب توجيهه لصفحة تسجيل الدخول أو إظهار رسالة واضحة
          String msg = "هذا الحساب غير مفعل. ";
          Get.offAllNamed(TRoutes.accountStatus, arguments: msg);
        }
      } else if (storeDoc.exists) {
        final status = storeDoc.data()?[StoreModel.getStoreStatus];
        print("خطا storeDoc.exists");
        if (status == StoreStatus.active.name || status == 'active') {
          // تأكد من المقارنة بالنص أو الـ Enum بشكل صحيح
          role = AppRole.admin;
          _redirectToHome(AppRole.admin);
        } else {
          String msg = "هذا الحساب  محظور ";
          if (status == StoreStatus.suspended.name) {
            msg =
                "تم إيقاف هذا الحساب لمخالفة الشروط. يرجى التواصل مع الإدارة.";
          } else if (status == StoreStatus.pending.name) {
            msg = "حسابك لا يزال تحت المراجعة، سيتم إشعارك فور تفعيله.";
          }
          Get.offAllNamed(TRoutes.accountStatus, arguments: msg);
        }
      } else {
        TLoaders.warningSnackBar(
          title: "تنبيه",
          message: "لم يتم العثور على بيانات لهذا الحساب",
        );
        Get.offAllNamed(TRoutes.chooseUserType);
      }
    } catch (e) {
      print("خطا catch");
      TFullScreenLoader.stopLoading();
      debugPrint("Error Fetching Role: $e");
      TLoaders.errorSnackBar(
        title: "خطأ",
        message: "حدث خطأ غير متوقع أثناء جلب البيانات",
      );
    }
  }

  /* Future<void> fetchAndSaveRole(User user) async {
    try {
      TFullScreenLoader.openLoadingDialog(
        'جاري تهيئة الحساب...',
        TImages.docerAnimation,
      );

      // تنفيذ الاستعلامات بالتوازي (Parallel Execution)
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection(DriverModel.driverCollectionName)
            .doc(user.uid)
            .get(),
        FirebaseFirestore.instance
            .collection(StoreModel.getStoreCollectionName)
            .doc(user.uid)
            .get(),
      ]);
      TFullScreenLoader.stopLoading();
      final driverDoc = results[0];
      final storeDoc = results[1];

      if (driverDoc.exists) {
        if (driverDoc.data()?['isActive'] ?? false) {
          role = AppRole.driver;
          _redirectToHome(AppRole.driver);
        } else if (driverDoc.data()?['isActive'] == false) {
          TLoaders.warningSnackBar(
            title: "عذرا",
            message: "هذا الحساب غير مفعل",
          );
        }
      } else if (storeDoc.exists) {
        if ((storeDoc.data()?[StoreModel.getStoreStatus] ==
            StoreStatus.active)) {
          role = AppRole.admin;
          _redirectToHome(AppRole.admin);
        } else if ((storeDoc.data()?[StoreModel.getStoreStatus] ==
            StoreStatus.suspended)) {
          TLoaders.warningSnackBar(
            title: "عذرا",
            message:
                "هذا الحساب تم ايقافه يرجي التواصل مع الدعم الفني لمعرفة المزيد",
          );
        } else if ((storeDoc.data()?[StoreModel.getStoreStatus] ==
            StoreStatus.pending)) {
          TLoaders.warningSnackBar(
            title: "عذرا",
            message: "هذا الحساب ما زال تحت المراجعة",
          );
        }
      } else {
        TLoaders.warningSnackBar(
          title: "تنبيه",
          message: "لم يتم تحديد دور لهذا الحساب",
        );
        Get.offAllNamed(TRoutes.chooseUserType);
      }
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(
        title: "خطأ",
        message: "حدث خطأ أثناء جلب البيانات",
      );
    }
  }*/

  // فحص صامت في الخلفية (Silent Validation)
  void _silentCheck(User user) async {
    try {
      // 1. تحديث حالة الـ Auth (للتحقق من حذف الحساب أو تغيير كلمة المرور أو توثيق الإيميل)
      await user.reload();

      // 2. جلب البيانات من Firestore بناءً على الدور المخزن محلياً
      final String? localRole = deviceStorage.read('USER_ROLE');

      if (localRole == AppRole.driver.name) {
        final doc = await FirebaseFirestore.instance
            .collection(DriverModel.driverCollectionName)
            .doc(user.uid)
            .get();

        bool isActive = doc.data()?['isActive'] ?? false;
        if (!isActive) _forceLogout("عذراً، تم إلغاء تفعيل حسابك");
      } else if (localRole == AppRole.admin.name) {
        final doc = await FirebaseFirestore.instance
            .collection(StoreModel.getStoreCollectionName)
            .doc(user.uid)
            .get();

        final status = doc.data()?[StoreModel.getStoreStatus];
        if (status != StoreStatus.active.name && status != 'active') {
          _forceLogout("تم تعليق حسابك، يرجى التواصل مع الإدارة");
        }
      }
    } catch (e) {
      debugPrint("Silent check failed: $e");
      // في حال فشل التحقق بسبب حذف الحساب نهائياً من Firebase
      if (e.toString().contains('user-not-found')) {
        _forceLogout("لم يتم العثور على هذا الحساب");
      }
    }
  }

  // دالة مساعدة لتنفيذ الخروج الإجباري
  void _forceLogout(String message) async {
    // إظهار ديلوج إجباري
    await Get.defaultDialog(
      title: "تنبيه الأمان",
      middleText: message,
      contentPadding: const EdgeInsets.all(TSizes.defaultSpace),
      titleStyle: const TextStyle(color: Colors.red),
      barrierDismissible: false, // منع الإغلاق عند الضغط خارج الديلوج
      onWillPop: () async => false, // منع زر الرجوع في أندرويد
      confirm: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            // 1. مسح الدور المخزن محلياً لضمان عدم الدخول التلقائي مرة أخرى
            deviceStorage.remove('USER_ROLE');

            // 2. تسجيل الخروج من Firebase
            await _auth.signOut();

            // 3. التوجيه لشاشة الحالة مع مسح سجل الشاشات بالكامل
            Get.offAllNamed(TRoutes.accountStatus, arguments: message);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            side: BorderSide.none,
          ),
          child: const Text("موافق"),
        ),
      ),
    );
  }

  // دالة مساعدة لتوحيد منطق التوجيه
  void _redirectToHome(AppRole? userRole) {
    if (userRole == null) {
      Get.offAllNamed(TRoutes.chooseUserType);
    }
    if (userRole == AppRole.driver) {
      Get.offAllNamed(TRoutes.navigationMenu);
    } else if (userRole == AppRole.admin) {
      Get.offAllNamed(TRoutes.firstScreen);
    }
  }

  /*
  void screenRedirect() async {
    final user = _auth.currentUser;

    // 1. فحص حالة التسجيل أولاً (أسرع عملية)
    if (user == null) {
      Get.offAllNamed(TRoutes.chooseUserType);
      return;
    }

    // 2. التحقق من توثيق البريد الإلكتروني قبل أي عملية جلب بيانات من Firestore
    // ملاحظة: reload() قد تفشل إذا كان الإنترنت ضعيفاً، لذا نضعها داخل try
    try {
      await user.reload();
    } catch (e) {
      debugPrint("خطأ في تحديث بيانات المستخدم: $e");
      // إذا فشل التحديث بسبب الإنترنت وكان لدينا دور مخزن محلياً، نكمل العمل
      if (role != null) {
        _redirectToHome(role!);
        return;
      }
    }

    if (!(user.emailVerified)) {
      Get.offAllNamed(TRoutes.verifyEmail, arguments: user.email);
      return;
    }

    // 3. إذا كان الدور (Role) موجوداً محلياً، نوجه المستخدم فوراً (تجربة مستخدم سريعة جداً)
    if (role != null) {
      _redirectToHome(role!);
      return;
    }

    // 4. جلب البيانات من Firestore (فقط إذا لم نعرف الدور محلياً)
    try {
      TFullScreenLoader.openLoadingDialog(
        'جاري التحقق من الصلاحيات...',
        TImages.defaultLoaderAnimation,
      );

      // نستخدم Future.wait لجلب البيانات بالتوازي إذا كان هناك أكثر من احتمال (اختياري لزيادة السرعة)
      final driverDoc = await FirebaseFirestore.instance
          .collection(DriverModel.driverCollectionName)
          .doc(user.uid)
          .get();

      TFullScreenLoader.stopLoading();
      final driver = DriverModel.fromSnapshot(driverDoc);
      if (driverDoc.exists && driver.isActive) {
        role = AppRole.driver;
        // حفظ الدور محلياً هنا (مثلاً باستخدام GetStorage) لضمان السرعة في المرة القادمة
        _redirectToHome(AppRole.driver);
      } else {
        final storeDoc = await FirebaseFirestore.instance
            .collection(StoreModel.getStoreCollectionName)
            .doc(user.uid)
            .get();
        // فحص إضافي للتأكد من أنه تاجر
        if (driverDoc.exists && driver.isActive) {
          role = AppRole.admin;
          _redirectToHome(AppRole.admin);
        }
        TLoaders.warningSnackBar(title: "عذرا", message: "لم يتم العثور على حسابك")
      }
    } catch (e) {
      TFullScreenLoader.stopLoading();
      // معالجة ذكية للخطأ: لا نوجهه فوراً للخروج، بل نعطيه محاولة أخرى أو نتحقق من الاتصال
      Get.snackbar("خطأ في الاتصال", "يرجى التحقق من إنترنت جهازك");
    }
  }
*/

  /*
  void screenRedirect() async {
    final user = _auth.currentUser;

    // 1. إذا لم يكن هناك مستخدم مسجل
    if (user == null) {
      Get.offAllNamed(TRoutes.chooseUserType);
      return;
    }

    // إذا كان الدور مخزناً محلياً، نوجه المستخدم فوراً (يعمل بدون إنترنت)
    if (role != null) {
      _redirectToHome(role!);
      return;
    }

    try {
      // 2. تحديث بيانات المستخدم للتحقق من حالة الـ Email Verification
      await user.reload();
      final updatedUser = _auth.currentUser;

      // 3. التحقق هل البريد الإلكتروني موثق؟
      if (updatedUser?.emailVerified ?? false) {
        TFullScreenLoader.openLoadingDialog(
          'جاري التحقق من الصلاحيات...',
          TImages.defaultLoaderAnimation,
        );
        // أ) البحث في كولكشن المناديب أولاً
        final driverDoc = await FirebaseFirestore.instance
            .collection(DriverModel.driverCollectionName)
            .doc(updatedUser!.uid)
            .get();
        TFullScreenLoader.stopLoading();
        if (driverDoc.exists) {
          // إذا وجدناه مندوباً، نوجهه لداشبورد المندوب
          role = AppRole.driver;
          Get.offAllNamed(TRoutes.navigationMenu);
        } else {
          // ب) إذا لم يكن مندوباً، نوجهه لداشبورد التاجر (أو يمكنك إضافة فحص آخر هنا)
          role = AppRole.admin;
          Get.offAllNamed(TRoutes.dashboard);
        }
      } else {
        // 4. إذا كان مسجلاً ولكن لم يوثق البريد بعد
        Get.offAllNamed(TRoutes.verifyEmail, arguments: updatedUser?.email);
      }
    } catch (e) {
      // في حال حدوث خطأ تقني، نرجعه لشاشة الاختيار لضمان عدم تعليق التطبيق
      Get.offAllNamed(TRoutes.chooseUserType);
    }
  }
*/
  /*
  void screenRedirect() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Reload user data to get latest verification status
      await user.reload();
      final updatedUser = _auth.currentUser;

      if (updatedUser?.emailVerified ?? false) {
        // await TLocalStorage.init(user.uid);
        Get.offAllNamed(TRoutes.dashboard);
      } else {
        Get.offAllNamed(TRoutes.verifyEmail, arguments: updatedUser!.email);
      }
    } else {
      //deviceStorage.writeIfNull("isFirstTime", true);
      //deviceStorage.read("isFirstTime") != null
      Get.offAllNamed(TRoutes.login);
    }
  }
*/
  // LOGIN

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
      throw TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطا غير متوقع. الرجاء المحاولة مجددا";
    }
  }

  // REGISTER
  Future<UserCredential> regesterWithEmailAndPassword(
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
    } on FormatException catch (_) {
      throw TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطا غير متوقع. الرجاء المحاولة مجددا";
    }
  }

  Future<void> sendEmailVerify() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطا غير متوقع. الرجاء المحاولة مجددا";
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطا غير متوقع. الرجاء المحاولة مجددا";
    }
  }

  /*
  final gSign.GoogleSignIn _googleSignIn = gSign.GoogleSignIn.standard();
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. بدء عملية تسجيل الدخول
      // ملاحظة: تأكد أنك لا تستخدم GoogleSignIn().signIn() بل _googleSignIn.signIn()
      final GoogleSignInAccount? userAccount = await _googleSignIn.signIn();

      if (userAccount == null) return null;

      // 2. الحصول على بيانات المصادقة
      final GoogleSignInAuthentication googleAuth =
          await userAccount.authentication;

      // 3. إنشاء كائن الاعتماد لـ Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. تسجيل الدخول في Firebase
      return await _auth.signInWithCredential(credential);
    } on PlatformException catch (e) {
      // خطأ شائع: "sign_in_failed" بسبب الـ SHA-1 أو الإعدادات
      throw e.message ?? "حدث خطأ في منصة التشغيل";
    } catch (e) {
      throw "حدث خطأ غير متوقع: $e";
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. بدء عملية تسجيل الدخول
      final GoogleSignInAccount? userAccount = await GoogleSignIn().signIn();

      // إذا قام المستخدم بإغلاق نافذة الاختيار دون اختيار حساب
      if (userAccount == null) return null;

      // 2. الحصول على بيانات المصادقة
      final GoogleSignInAuthentication googleAuth =
          await userAccount.authentication;

      // 3. إنشاء الاعتماد لـ Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. تسجيل الدخول وإرجاع النتيجة
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException()
          .message; // تأكد من وجود دالة message في الكلاس الخاص بك
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      if (kDebugMode) print("Something went wrong: $e");
      throw "حدث خطأ غير متوقع، يرجى المحاولة لاحقاً.";
    }
  }
*/
  /*
   Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? userAccount = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
          await userAccount?.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      if (kDebugMode) debugPrint("somthing went wrong, pleas try agin");
      return null;
    }
  }
*/
  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      //  await GoogleSignIn().signOut();
      Get.offAllNamed(TRoutes.login);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطا غير متوقع. الرجاء المحاولة مجددا";
    }
  }

  Future<void> deleteAccount() async {
    try {
      //   await UserReposity.instance.removeUserRecord(_auth.currentUser!.uid);
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطا غير متوقع. الرجاء المحاولة مجددا";
    }
  }

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
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  Future<void> signInWithGoogle() async {}
}
