import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/reposity/repositories.authentication/authentication_repository.dart';
import 'package:stors_admin_panel/data/stor/models/notification_model.dart';
import 'package:stors_admin_panel/features/features_authintication/models/user_stor_model.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class NotificationControllerForScreen extends GetxController {
  static NotificationControllerForScreen get instance => Get.find();
  final _db = FirebaseFirestore.instance;
  final String storeId = AuthenticationRepository.instance.authUser!.uid;

  // متغيرات الترقيم
  RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  // القائمة المفلترة المعروضة حالياً في الواجهة
  RxList<NotificationModel> filteredNotifications = <NotificationModel>[].obs;
  RxBool isLoading = false.obs;
  RxBool hasMore = true.obs;
  // اتجاه التمرير لمنع أنيميشن الصعود
  var isScrollingDown = true.obs;

  // نوع الفلتر الحالي (أمثلة: "الكل", "طلب جديد", "تنبيه", "تحديث")
  var selectedFilter = "الكل".obs;
  DocumentSnapshot? lastDocument;
  final int documentLimit = 15;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications(); // جلب أول 20 عند التشغيل
  }

  Future<void> fetchNotifications() async {
    if (isLoading.value || !hasMore.value) return;

    isLoading.value = true;
    try {
      Query<Map<String, dynamic>> query = _db
          .collection('Stores') // استخدمت النص مباشرة لضمان الوضوح
          .doc(storeId)
          .collection(NotificationModel.getCollectionName)
          .orderBy(NotificationModel.getFieldCreatedAt, descending: true)
          .limit(documentLimit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      final querySnapshot = await query.get();

      if (querySnapshot.docs.length < documentLimit) {
        hasMore.value = false; // لا توجد بيانات أخرى لجلبها
      }

      if (querySnapshot.docs.isNotEmpty) {
        lastDocument = querySnapshot.docs.last;
        // 🌟 تحويل الـ Docs مباشرة إلى لستة موديلات وإضافتها
        final newNotifications = querySnapshot.docs
            .map((doc) => NotificationModel.fromSnapshot(doc))
            .toList();
        notifications.addAll(newNotifications);
        applyFilter(selectedFilter.value);
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: "خطأ", message: "فشل جلب الإشعارات: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// دالة تطبيق الفلتر محلياً في الذاكرة (0 تكلفة فايربيز)
  void applyFilter(String filterType) {
    selectedFilter.value = filterType;

    if (filterType == "الكل") {
      filteredNotifications.assignAll(notifications);
    } else {
      filteredNotifications.assignAll(
        notifications
            .where((notification) => notification.type == filterType)
            .toList(),
      );
    }
  }

  // دالة الحذف (تحديث القائمة محلياً أيضاً)
  Future<void> deleteNotification(String docId, bool isOpened) async {
    // كود الحذف الخاص بك من الفايربيز
    notifications.removeWhere((doc) => doc.id == docId);
    filteredNotifications.removeWhere((doc) => doc.id == docId);
  }

  Future<void> markAsOpened(String docId) async {
    try {
      // 1️⃣ تحديث القائمة الأساسية محلياً فوراً لصالح الـ UX
      int mainIndex = notifications.indexWhere((n) => n.id == docId);
      if (mainIndex != -1) {
        notifications[mainIndex] = notifications[mainIndex].copyWith(
          isOpened: true,
          isRead: true,
        );
      }

      // 2️⃣ تحديث قائمة الفلترة فوراً
      int filteredIndex = filteredNotifications.indexWhere(
        (n) => n.id == docId,
      );
      if (filteredIndex != -1) {
        filteredNotifications[filteredIndex] =
            filteredNotifications[filteredIndex].copyWith(
              isOpened: true,
              isRead: true,
            );
      }

      // 3️⃣ إخطار الواجهة فوراً قبل انتظار السيرفر
      notifications.refresh();
      filteredNotifications.refresh();

      // 4️⃣ الرفع للسيرفر في الخلفية دون تعطيل واجهة المستخدم
      await _db
          .collection(StoreModel.getStoreCollectionName)
          .doc(storeId)
          .collection(NotificationModel.getCollectionName)
          .doc(docId)
          .update({
            NotificationModel.getFieldIsOpened: true,
            NotificationModel.getFieldIsRead: true,
          });
    } catch (e) {
      print("Error marking notification as opened: $e");
      // هنا اختياري: يمكنك إعادة القيمة لـ false إذا فشل الاتصال بالإنترنت تماماً
    }
  }

  /*
  Future<void> markAsOpened(String docId) async {
    try {
      // 1. التحديث في الفايربيز
      await _db
          .collection(StoreModel.getStoreCollectionName)
          .doc(storeId)
          .collection(NotificationModel.getCollectionName)
          .doc(docId)
          .update({
            NotificationModel.getFieldIsOpened: true,
            NotificationModel.getFieldIsRead: true,
          });

      // 2. تحديث القائمة الأساسية محلياً
      int mainIndex = notifications.indexWhere((n) => n.id == docId);
      if (mainIndex != -1) {
        notifications[mainIndex] = notifications[mainIndex].copyWith(
          isOpened: true,
          isRead: true,
        );
      }

      // 3. تحديث قائمة الفلترة المعروضة حالياً في نفس الوقت
      int filteredIndex = filteredNotifications.indexWhere(
        (n) => n.id == docId,
      );
      if (filteredIndex != -1) {
        filteredNotifications[filteredIndex] =
            filteredNotifications[filteredIndex].copyWith(
              isOpened: true,
              isRead: true,
            );
      }

      // 4. 🔥 تحديث قسري وشامل لـ GetX ليفهم التغيير في الذاكرة
      notifications.refresh();
      filteredNotifications.refresh();
    } catch (e) {
      print("Error marking notification as opened: $e");
    }
  }
  */
  /*
  // تحديث حالة الفتح لتمكين الحذف
  Future<void> markAsOpened(String docId) async {
    try {
      // 1. التحديث في قاعدة بيانات Firestore
      await _db
          .collection(StoreModel.getStoreCollectionName)
          .doc(storeId)
          .collection(NotificationModel.getCollectionName)
          .doc(docId)
          .update({
            NotificationModel.getFieldIsOpened: true,
            NotificationModel.getFieldIsRead: true,
          });

      // 2. 🌟 التحديث المحلي السحري
      int index = notifications.indexWhere((n) => n.id == docId);
      if (index != -1) {
        // تحديث العنصر داخل القائمة الأساسية باستخدام copyWith
        notifications[index] = notifications[index].copyWith(
          isOpened: true,
          isRead: true,
        );

        // 🔥 هنا السر: إجبار GetX على إخطار الـ UI بأن القائمة الأساسية تغيرت
        notifications.refresh();

        // 3. إعادة تطبيق الفلتر المحلي لتحديث قائمة filteredNotifications أيضاً
        applyFilter(selectedFilter.value);
      }
    } catch (e) {
      print("Error marking notification as opened: $e");
    }
  }
*/
  // تحديث حالة الفتح لتمكين الحذف
  /*Future<void> markAsOpened(String docId) async {
    await _db
        .collection(StoreModel.getStoreCollectionName)
        .doc(storeId)
        .collection(NotificationModel.getCollectionName)
        .doc(docId)
        .update({
          NotificationModel.getFieldIsOpened: true,
          NotificationModel.getFieldIsRead: true,
        });
    // 2. 🌟 التحديث المحلي السحري: ابحث عن العنصر وعدله باستخدام copyWith
    int index = notifications.indexWhere((n) => n.id == docId);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(
        isOpened: true,
        isRead: true,
      );
      applyFilter(
        selectedFilter.value,
      ); // إعادة تطبيق الفلتر ليرى الـ UI التحديث فوراً
    }
  }*/

  // حذف الإشعار
  Future<void> deleteNotificationFromFirstor(
    String docId,
    bool isOpened,
  ) async {
    if (!isOpened) {
      TLoaders.warningSnackBar(
        title: "تنبيه",
        message: "يجب فتح الإشعار أولاً قبل حذفه",
      );
      return;
    }
    await _db
        .collection(StoreModel.getStoreCollectionName)
        .doc(storeId)
        .collection(NotificationModel.getCollectionName)
        .doc(docId)
        .delete();
  }
}
