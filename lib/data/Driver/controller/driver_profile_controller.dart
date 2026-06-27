import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stors_admin_panel/data/Driver/model/driver_model.dart';
import 'package:stors_admin_panel/data/reposity/driver/delivery_epository.dart';
import 'package:stors_admin_panel/data/reposity/repositories.authentication/authentication_repository.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class DriverProfileController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // بيانات المندوب (Rxn تجعلها قابلة للمراقبة وممكن تكون null)
  var driver = Rxn<DriverModel>();
  var isLoading = false.obs; // لحالة التحميل أثناء الرفع

  @override
  void onInit() {
    super.onInit();
    // هنا يجب جلب بيانات المندوب الحالي من Firestore
    final driverId = AuthenticationRepository.instance.authUser?.uid;
    if (driverId != null) {
      fetchDriverData(driverId);
    }
  }

  Future<void> fetchDriverData(String driverId) async {
    try {
      isLoading.value = true; // بدء التحميل

      // استدعاء دالة المستودع
      final driverData = await DeliveryRepository.instance.getDriverDetails(
        driverId,
      );

      // تحديث المتغير المراقب
      driver.value = driverData;
    } catch (e) {
      // إظهار رسالة خطأ للمستخدم
      TLoaders.errorSnackBar(
        title: "خطأ في جلب البيانات",
        message: e.toString(),
      );
    } finally {
      isLoading.value = false; // إنهاء التحميل في كل الحالات
    }
  }

  // --- دالة اختيار ورفع الصورة الشخصية ---
  Future<void> uploadProfilePicture() async {
    // 1. اختيار مصدر الصورة (المعرض)
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // تقليل الجودة لسرعة الرفع وتقليل المساحة
      maxWidth: 512, // تحديد العرض الأقصى لتوحيد المقاسات
    );

    if (image != null) {
      // 2. إذا تم اختيار صورة، نبدأ حالة التحميل
      isLoading.value = true;
      File file = File(image.path);

      try {
        // 3. تحديد المسار في Firebase Storage
        // المسار: Users/{driverId}_profile.jpg
        String filePath = 'Drivers/${driver.value!.id}_profile.jpg';
        Reference ref = _storage.ref().child(filePath);

        // 4. بدء عملية الرفع
        UploadTask uploadTask = ref.putFile(file);

        // 5. الانتظار حتى اكتمال الرفع وجلب رابط التحميل
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // 6. تحديث رابط الصورة في Firestore
        await _db.collection('Drivers').doc(driver.value!.id).update({
          'profilePicture': downloadUrl,
        });

        // 7. تحديث البيانات في الواجهة محلياً
        driver.value = DriverModel(
          id: driver.value!.id,
          name: driver.value!.name,
          email: driver.value!.email,
          phoneNumber: driver.value!.phoneNumber,
          profilePicture: downloadUrl, // الرابط الجديد
          isActive: driver.value!.isActive,
          role: driver.value!.role,
          fcmToken: driver.value!.fcmToken,
        );

        TLoaders.successSnackBar(
          title: "نجاح",
          message: "تم تحديث الصورة الشخصية بنجاح",
        );
      } catch (e) {
        TLoaders.errorSnackBar(title: "خطأ", message: "فشل الرفع: $e");
        debugPrint("Error uploading image: $e");
      } finally {
        // 8. إنهاء حالة التحميل مهما كانت النتيجة
        isLoading.value = false;
      }
    }
  }
}
