import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stors_admin_panel/data/Driver/model/driver_model.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class DriverNotificationController extends GetxController {
  final _db = FirebaseFirestore.instance;
  final String? driverId = FirebaseAuth.instance.currentUser?.uid;

  // جلب الإشعارات لحظياً (Stream)
  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationsStream() {
    return _db
        .collection(DriverModel.driverCollectionName)
        .doc(driverId)
        .collection("Notifications")
        .orderBy("createdAt", descending: true) // الأحدث أولاً
        .snapshots();
  }

  // تحديث حالة الإشعار إلى "تم فتحه"
  Future<void> markAsOpened(String docId) async {
    await _db
        .collection(DriverModel.driverCollectionName)
        .doc(driverId)
        .collection("Notifications")
        .doc(docId)
        .update({'isOpened': true, 'isRead': true});
  }

  // حذف الإشعار (يسمح فقط إذا تم فتحه كما طلبت سابقاً)
  Future<void> deleteNotification(String docId, bool isOpened) async {
    if (!isOpened) {
      TLoaders.warningSnackBar(
        title: "تنبيه",
        message: "يجب فتح الإشعار أولاً قبل حذفه",
      );

      return;
    }
    await _db
        .collection(DriverModel.driverCollectionName)
        .doc(driverId)
        .collection("Notifications")
        .doc(docId)
        .delete();
  }

  // دالة طلب الإذن التي سنستدعيها في الهوم
  Future<void> requestPermissionOnHome() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // طلب الإذن
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // إذا وافق، نجلب التوكن ونحدثه في السيرفر
      String? token = await messaging.getToken();
      if (token != null) {
        saveTokenToFirestore(token);
      }
      debugPrint('✅ تم منح الإذن وجلب التوكن بنجاح');
    } else {
      debugPrint('❌ رفض المستخدم منح إذن الإشعارات');
    }
  }

  /// حفظ التوكن في Firestore الخاص بالمندوب
  Future<void> saveTokenToFirestore(String token) async {
    try {
      // 1. التأكد من وجود مستخدم مسجل دخول حالياً
      final String? currentDriverId = FirebaseAuth.instance.currentUser?.uid;

      if (currentDriverId != null) {
        // 2. الوصول إلى مستند المندوب في كولكشن "DeliveryDrivers"
        // نستخدم DriverModel.fldToken لضمان مطابقة اسم الحقل في قاعدة البيانات
        await _db
            .collection(DriverModel.driverCollectionName)
            .doc(currentDriverId)
            .update({
              DriverModel.fldToken: token,
              DriverModel.fldLastTokenUpdate:
                  FieldValue.serverTimestamp(), // لتتبع متى تم تحديث التوكن آخر مرة
            });

        debugPrint("✅ تم تحديث FCM Token في Firestore بنجاح");
      } else {
        debugPrint("⚠️ لم يتم تحديث التوكن: لا يوجد مستخدم مسجل دخول");
      }
    } catch (e) {
      // إذا فشل التحديث (مثلاً المستند غير موجود بعد)، نستخدم set مع merge
      if (e is FirebaseException && e.code == 'not-found') {
        await _replaceTokenWithSet(token);
      } else {
        debugPrint("❌ خطأ أثناء حفظ التوكن: $e");
      }
    }
  }

  // دالة احتياطية في حال كان مستند المندوب لم ينشأ بعد
  Future<void> _replaceTokenWithSet(String token) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _db.collection(DriverModel.driverCollectionName).doc(uid).set({
        DriverModel.fldToken: token,
        DriverModel.fldLastTokenUpdate: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
