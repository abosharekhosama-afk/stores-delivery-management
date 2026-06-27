import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stors_admin_panel/data/reposity/repositories.authentication/authentication_repository.dart';
import 'package:stors_admin_panel/features/features_authintication/models/user_stor_model.dart';

class NotificationController extends GetxController {
  static NotificationController get instance => Get.find();

  final _db = FirebaseFirestore.instance;
  final String? storeId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    // 1. مراقبة تحديث التوكن تلقائياً
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      saveTokenToFirestore(newToken);
    });

    // 2. إعداد استقبال الإشعارات
    setupPushNotifications();
  }

  // --- جزء إدارة الـ FCM (Push Notifications) ---

  Future<void> setupPushNotifications() async {
    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission();

    await subscribeToTopics();

    final token = await fcm.getToken();
    if (token != null) {
      saveTokenToFirestore(token);
    }

    // الإشعار والتطبيق مفتوح
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Get.snackbar(
        message.notification?.title ?? "تحديث جديد",
        message.notification?.body ?? "",
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 5),
      );
    });

    // عند الضغط على الإشعار
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleNotificationClick(message);
    });
  }

  void saveTokenToFirestore(String token) async {
    if (storeId != null) {
      await _db
          .collection(StoreModel.getStoreCollectionName)
          .doc(storeId)
          .update({'fcmToken': token});
    }
  }

  void handleNotificationClick(RemoteMessage message) {
    if (message.data['type'] == 'REJECTION' ||
        message.data['type'] == 'order_update') {
      // كود الانتقال لصفحة تفاصيل الطلب
      // Get.toNamed('/order-details', arguments: message.data['orderId']);
    }
  }

  // --- جزء إدارة قائمة الإشعارات (Firestore UI) ---

  // جلب الإشعارات لحظياً
  Stream<QuerySnapshot> getNotifications() {
    return _db
        .collection(StoreModel.getStoreCollectionName)
        .doc(storeId)
        .collection('Notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> requestPermissionAndGetToken() async {
    final user = AuthenticationRepository.instance.authUser;
    if (user == null) return;

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // طلب الإذن (سيظهر للمستخدم فقط إذا لم يسبق له الموافقة)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      try {
        String? token = await messaging.getToken();
        if (token != null) {
          saveTokenToFirestore(token);
        }
      } catch (e) {
        debugPrint(
          "📡 فشل الجلب الأولي (غالباً أوفلاين)، سيتكفل المراقب بالباقي: $e",
        );
      }
    }
  }

  // الدالة الجديدة للاشتراك في القنوات
  Future<void> subscribeToTopics() async {
    try {
      // 1. الاشتراك في القناة العامة لجميع المتاجر
      await FirebaseMessaging.instance.subscribeToTopic("store_owners");
      // الاشتراك في قناة المتاجر و المستخدمين
      await FirebaseMessaging.instance.subscribeToTopic("all_app_users");
      // 2. الاشتراك في قناة خاصة بهذا المتجر فقط (باستخدام الـ UID الخاص به)
      if (storeId != null) {
        await FirebaseMessaging.instance.subscribeToTopic("store_$storeId");
        debugPrint("📡 Subscribed to topic: store_$storeId");
      }

      debugPrint("📡 Subscribed to general topic: store_owners");
    } catch (e) {
      debugPrint("❌ Error subscribing to topics: $e");
    }
  }
}

/*
class NotificationController extends GetxController {
  static NotificationController get instance => Get.find();
  final _db = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      saveTokenToFirestore(newToken);
    });
  }

  Future<void> setupPushNotifications() async {
    final fcm = FirebaseMessaging.instance;

    // 1. طلب الإذن
    await fcm.requestPermission();

    // 2. جلب التوكن وتخزينه
    final token = await fcm.getToken();
    if (token != null) {
      saveTokenToFirestore(token);
    }

    // 3. التعامل مع الإشعار والتطبيق مفتوح (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // هنا يمكنك إظهار Snack-bar مخصص أو تنبيه داخل التطبيق
      Get.snackbar(
        message.notification?.title ?? "طلب جديد",
        message.notification?.body ?? "",
        snackPosition: SnackPosition.TOP,
      );
    });

    // 4. التعامل مع الضغط على الإشعار وفتح التطبيق
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleNotificationClick(message);
    });
  }

  void saveTokenToFirestore(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await _db.collection("Stores").doc(userId).update({'fcmToken': token});
    }
  }

  void handleNotificationClick(RemoteMessage message) {
    // التحقق من نوع الإشعار والانتقال لصفحة الطلبات
    if (message.data['type'] == 'vendor_order') {
      // مثال: الانتقال لصفحة تفاصيل الطلب باستخدام الـ ID المرسل
      // Get.to(() => OrderDetailScreen(orderId: message.data['orderId']));
      debugPrint("Navigate to Order: ${message.data['orderId']}");
    }
  }

  // داخل الـ NotificationController
  void setupListeners() {
    // هذا المستمع يعمل تلقائياً عندما يقوم Firebase بجلب توكن جديد
    // (مثلاً عند عودة الإنترنت بعد انقطاع)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      saveTokenToFirestore(newToken);
      debugPrint("🌐 تم تحديث التوكن تلقائياً بعد عودة الاتصال");
    });
  }

  Future<void> requestPermissionAndGetToken() async {
    final user = AuthenticationRepository.instance.authUser;
    if (user == null) return;

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // طلب الإذن (سيظهر للمستخدم فقط إذا لم يسبق له الموافقة)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      try {
        String? token = await messaging.getToken();
        if (token != null) {
          saveTokenToFirestore(token);
        }
      } catch (e) {
        debugPrint(
          "📡 فشل الجلب الأولي (غالباً أوفلاين)، سيتكفل المراقب بالباقي: $e",
        );
      }
    }
  }
}
*/
