import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:stors_admin_panel/app.dart';
import 'package:stors_admin_panel/data/reposity/repositories.authentication/authentication_repository.dart';
import 'package:stors_admin_panel/data/stor/models/brand_model.dart';
import 'package:stors_admin_panel/data/stor/models/product_attribute_model.dart';
import 'package:stors_admin_panel/data/stor/models/product_model.dart';
import 'package:stors_admin_panel/data/stor/models/product_variation_model.dart';
import 'package:stors_admin_panel/firebase_options.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/helpers/network_manager.dart';
import 'package:url_strategy/url_strategy.dart';

// 1. تعريف القناة في المستوى العام (Global) لسهولة الوصول إليها
const AndroidNotificationChannel ordersChannel = AndroidNotificationChannel(
  'orders_channel', // هذا هو المعرف (ID) الذي يجب أن تضعه في كود الـ Cloud Function
  'تنبيهات الطلبات الجديدة',
  description: 'هذه القناة مخصصة لإشعارات الطلبات الجديدة للمتاجر',
  importance: Importance.max,
  playSound: true, // تفعيل الصوت
  enableVibration: true,
);

// 2. دالة التعامل مع الإشعارات في الخلفية
@pragma('vm:entry-point') // إضافة هذا التنبيه لضمان عمل الدالة في الخلفية
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();

  // 1. تهيئة Hive
  await Hive.initFlutter();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((value) {
    // تفعيل التخزين المحلي لـ Firestore
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    Get.put(AuthenticationRepository());
    Get.put(NetworkManager());
  });

  // إعداد معالج الرسائل في الخلفية
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. إنشاء قناة الإشعارات للأندرويد لضمان تفعيل الصوت والأهمية القصوى
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(ordersChannel);

  // 3. تسجيل الـ Adapters
  // ملاحظة: الترتيب ليس مهماً جداً، المهم تسجيل كل الأنواع المستخدمة
  Hive.registerAdapter(ProductModelAdapter()); // typeId: 0
  Hive.registerAdapter(BrandModelAdapter()); // typeId: 1
  Hive.registerAdapter(ProductAttributeModelAdapter()); // typeId: 2
  Hive.registerAdapter(ProductVariationModelAdapter()); // typeId: 3
  Hive.registerAdapter(ProductVisibilityAdapter()); // typeId: 4 (الـ Enum)

  await Hive.openBox<ProductModel>('local_products');

  runApp(const App());
}
