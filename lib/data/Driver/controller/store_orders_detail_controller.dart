import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/stor/models/cart_item_model.dart';
import 'package:stors_admin_panel/data/stor/models/store_orders_model.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class StoreOrdersDetailsController extends GetxController {
  final String storeId;
  StoreOrdersDetailsController(this.storeId);

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  var isLoading = true.obs;
  var orders = <StoreOrdersModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint(
      "🚀 [StoreOrdersDetailsController]: تم البدء بمعرف متجر: $storeId",
    );
    fetchStoreOrders();
  }

  void fetchStoreOrders() {
    try {
      isLoading.value = true;
      debugPrint("📡 [Firestore]: جاري بدء الاستماع للطلبات...");

      _db
          .collection(StoreOrdersModel.getOrderCollectionName)
          .where(StoreOrdersModel.getStoreId, isEqualTo: storeId)
          .where(
            StoreOrdersModel.getStatus,
            isEqualTo: OrderStatus.readyForPickup.name,
          )
          .snapshots()
          .listen(
            (snapshot) {
              debugPrint(
                "📦 [Firestore]: تم استلام تحديث جديد. عدد الوثائق: ${snapshot.docs.length}",
              );

              if (snapshot.docs.isEmpty) {
                debugPrint(
                  "⚠️ [Firestore]: لا توجد طلبات تطابق هذا الـ storeId والحالة المطلوبة.",
                );
              }

              try {
                final List<StoreOrdersModel> fetchedOrders = snapshot.docs.map((
                  doc,
                ) {
                  debugPrint("📝 [Mapping]: جاري معالجة الطلب رقم: ${doc.id}");
                  return StoreOrdersModel.fromSnapshot(doc);
                }).toList();

                orders.assignAll(fetchedOrders);
                debugPrint(
                  "✅ [Success]: تم تحديث القائمة بـ ${orders.length} طلبات.",
                );
              } catch (e) {
                debugPrint(
                  "❌ [Mapping Error]: خطأ أثناء تحويل البيانات (Model Mapping): $e",
                );
              }

              isLoading.value = false;
            },
            onError: (error) {
              debugPrint("❌ [Stream Error]: حدث خطأ في تدفق البيانات: $error");
              isLoading.value = false;
            },
          );
    } catch (e) {
      debugPrint("❌ [General Error]: خطأ غير متوقع في fetchStoreOrders: $e");
      isLoading.value = false;
    }
  }

  // تحديث حالة المنتج مع طباعة تفصيلية
  Future<void> _updateItemStatus(
    String orderId,
    int itemIndex,
    ItemStatus newStatus,
    ItemStatus requiredCurrentStatus,
  ) async {
    debugPrint(
      "🛠️ [Update]: جاري محاولة تحديث حالة المنتج في الطلب: $orderId",
    );
    try {
      DocumentReference ref = _db
          .collection(StoreOrdersModel.getOrderCollectionName)
          .doc(orderId);

      await _db.runTransaction((transaction) async {
        DocumentSnapshot snap = await transaction.get(ref);

        if (!snap.exists) {
          throw "الوثيقة غير موجودة في قاعدة البيانات";
        }

        final List<dynamic> itemsRaw = snap[StoreOrdersModel.getItems];
        List<CartItemModel> cartItems = itemsRaw
            .map((item) => CartItemModel.fromJson(item))
            .toList();

        debugPrint(
          "🔍 [Transaction]: حالة المنتج الحالية: ${cartItems[itemIndex].itemStatus}",
        );

        if (cartItems[itemIndex].itemStatus == requiredCurrentStatus) {
          cartItems[itemIndex].itemStatus = newStatus;

          transaction.update(ref, {
            StoreOrdersModel.getItems: cartItems
                .map((i) => i.toJson())
                .toList(),
          });
          debugPrint(
            "✅ [Transaction]: تمت عملية التحديث بنجاح في الـ Transaction.",
          );
        } else {
          debugPrint(
            "⚠️ [Transaction]: الحالة الحالية لا تطابق الحالة المطلوبة للتحديث.",
          );
        }
      });
    } catch (e) {
      debugPrint("❌ [Update Error]: فشل التحديث: $e");
      TLoaders.errorSnackBar(title: "خطأ", message: "فشل تحديث الحالة: $e");
    }
  }

  // التحقق من رمز المتجر

  Future<bool> finalizePickup({
    required String storeOrderId,
    required String mainOrderId,
    required String inputCode,
  }) async {
    debugPrint(
      "🔐 [Auth]: جاري إرسال رمز الاستلام للسيرفر للتحقق والمزامنة الأمنية.",
    );

    try {
      // 1. استدعاء الدالة السحابية من Firebase Functions
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'finalizeStoreOrderPickup',
      );

      // 2. تمرير المعطيات المطلوبة للسيرفر
      final response = await callable.call(<String, dynamic>{
        'storeOrderId': storeOrderId,
        'mainOrderId': mainOrderId,
        'inputCode': inputCode.trim(),
      });

      // 3. قراءة النتيجة العائدة من السيرفر
      if (response.data != null && response.data['success'] == true) {
        debugPrint(
          "🎉 [Success]: تمت مطابقة الرمز على السيرفر بنجاح، وتحديث الحالات لـ shipped.",
        );

        // إظهار رسالة نجاح للمندوب
        TLoaders.successSnackBar(
          title: "تم الاستلام بنجاح",
          message: "تم تأكيد الكود والطلب الآن يعتبر في حوزتك رسمياً.",
        );

        return true; // تعيد true تماماً كما كانت دالتك القديمة تفعل ليتحرك الـ UI
      }

      return false;
    } catch (e) {
      debugPrint(
        "❌ [Auth Error]: تفاصيل الفشل أثناء محاولة التحقق من الرمز: $e",
      );

      // استخلاص رسالة الخطأ الصارمة القادمة من السيرفر لعرضها للمندوب
      String errorMessage = "حدث خطأ أثناء عملية التأكيد.";

      if (e is FirebaseFunctionsException) {
        // هنا تلتقط الرسائل مثل (رمز الاستلام المدخل غير صحيح) أو (يجب تحديث المنتجات يدوياً أولاً)
        errorMessage = e.message ?? errorMessage;
      } else {
        errorMessage = e.toString();
      }

      // إظهار رسالة الخطأ بداخل السناكبوت في تطبيق المندوب
      TLoaders.errorSnackBar(
        title: "فشل تأكيد الاستلام",
        message: errorMessage,
      );

      return false; // تعيد false لتبقى الشاشة كما هي ولا يتخطى المندوب الخطوة
    }
  }

  /*
  Future<bool> finalizePickup(String orderId, String inputCode) async {
    debugPrint("🔐 [Auth]: جاري التحقق من رمز المتجر للطلب: $orderId");
    try {
      final orderDoc = await _db
          .collection(StoreOrdersModel.getOrderCollectionName)
          .doc(orderId)
          .get();

      String correctCode =
          orderDoc.data()?[StoreOrdersModel.getPickupCode] ?? "0000";
      debugPrint(
        "🔑 [Auth]: الرمز المدخل: $inputCode | الرمز الصحيح: $correctCode",
      );

      if (inputCode == correctCode) {
        final dBoyId = AuthenticationRepository.instance.authUser?.uid;
        if (dBoyId != null) {
          DeliveryRepository.instance.confirmPickup(
            storeOrderId: orderId,
            deliveryBoyId: dBoyId,
          );
        }

        debugPrint("🎉 [Success]: تم إنهاء الاستلام بنجاح.");
        return true;
      }
      debugPrint("🚫 [Auth]: الرمز غير صحيح.");
      return false;
    } catch (e) {
      debugPrint("❌ [Auth Error]: حدث خطأ أثناء عملية التأكيد: $e");
      return false;
    }
  }
*/
  bool isOrderReadyToFinalize(StoreOrdersModel order) {
    return order.items.every(
      (item) =>
          item.itemStatus == ItemStatus.shipped ||
          item.itemStatus == ItemStatus.rejected ||
          item.itemStatus == ItemStatus.pickupFailed_Confirmed,
    );
  }

  /*Future<void> markItemAsPickedUp(String orderId, int itemIndex) async {
    await _updateItemStatus(
      orderId,
      itemIndex,
      ItemStatus.shipped,
      ItemStatus.readyForPickup,
    );
  }*/

  // 1️⃣ السيناريو الأول: المندوب استلم المنتج بنجاح ويريد شحنه
  Future<void> markItemAsPickedUp({
    required String storeOrderId,
    required String mainOrderId,
    required String productId,
    String? variationId,
  }) async {
    await _callDeliveryUpdateService(
      storeOrderId: storeOrderId,
      mainOrderId: mainOrderId,
      productId: productId,
      variationId: variationId,
      newStatus: ItemStatus.shipped.name, // حالة الشحن الناجحة
    );
  }

  // 2️⃣ السيناريو الثاني: المندوب فشل في استلام المنتج ويريد طلب إلغاء أو مراجعة إدارية
  Future<void> requestItemCancellation({
    required String storeOrderId,
    required String mainOrderId,
    required String productId,
    String? variationId,
  }) async {
    await _callDeliveryUpdateService(
      storeOrderId: storeOrderId,
      mainOrderId: mainOrderId,
      productId: productId,
      variationId: variationId,
      newStatus:
          ItemStatus.pickupFailed_WaitingAction.name, // إثبات فشل الاستلام
    );
  }

  // 🛠️ الدالة المساعدة المركزية التي تتصل بـ Firebase Cloud Functions
  Future<void> _callDeliveryUpdateService({
    required String storeOrderId,
    required String mainOrderId,
    required String productId,
    String? variationId,
    required String newStatus,
  }) async {
    debugPrint(
      "🛠️ [Delivery Update]: محاولة تحديث حالة المنتج إلى ($newStatus) للطلب: $mainOrderId",
    );

    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'updateItemStatusByDelivery',
      );

      final response = await callable.call(<String, dynamic>{
        'storeOrderId': storeOrderId,
        'mainOrderId': mainOrderId,
        'productId': productId,
        'variationId': variationId ?? '',
        'newStatus': newStatus,
      });

      if (response.data['success'] == true) {
        debugPrint(
          "✅ [Delivery Update]: تم التحديث والإشعار بنجاح في السيرفر.",
        );
        TLoaders.successSnackBar(
          title: "نجاح العملية",
          message: "تم تحديث حالة المنتج بنجاح.",
        );
      }
    } catch (e) {
      debugPrint("❌ [Delivery Update Error]: فشل التحديث: $e");
      TLoaders.errorSnackBar(title: "خطأ في التحديث", message: e.toString());
    }
  }

  /*// 2️⃣ السيناريو الثاني: المندوب يواجه مشكلة ويريد طلب إلغاء المنتج
  Future<void> requestItemCancellation(String orderId, int itemIndex) async {
    await _updateItemStatus(
      orderId,
      itemIndex,
      ItemStatus.pickupFailed_WaitingAction,
      ItemStatus.readyForPickup,
    );
  }*/
}

/*
class StoreOrdersDetailsController extends GetxController {
  final String storeId;
  StoreOrdersDetailsController(this.storeId);

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  var isLoading = true.obs;
  var orders = <StoreOrdersModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchStoreOrders();
  }

  void fetchStoreOrders() {
    _db
        .collection(StoreOrdersModel.getOrderCollectionName)
        .where(StoreOrdersModel.getStoreId, isEqualTo: storeId)
        .where(
          StoreOrdersModel.getStatus,
          isEqualTo: OrderStatus.readyForPickup.name,
        )
        .snapshots()
        .listen((snapshot) {
          orders.assignAll(
            snapshot.docs
                .map((doc) => StoreOrdersModel.fromSnapshot(doc))
                .toList(),
          );
          isLoading.value = false;
        });
  }

  // 1. تحديث حالة المنتج إلى "تم الاستلام"
  Future<void> markItemAsPickedUp(String orderId, int itemIndex) async {
    await _updateItemStatus(
      orderId,
      itemIndex,
      ItemStatus.shipped,
      ItemStatus.readyForPickup,
    );
  }

  // 2. طلب إلغاء منتج (تغيير الحالة إلى انتظار تأكيد التاجر)
  Future<void> requestItemCancellation(String orderId, int itemIndex) async {
    await _updateItemStatus(
      orderId,
      itemIndex,
      ItemStatus.pickupFailed_WaitingAction,
      ItemStatus.readyForPickup,
    );
  }

  // دالة داخلية للتحديث الآمن عبر Transactions
  Future<void> _updateItemStatus(
    String orderId,
    int itemIndex,
    ItemStatus newStatus,
    ItemStatus requiredCurrentStatus,
  ) async {
    try {
      DocumentReference ref = _db
          .collection(StoreOrdersModel.getOrderCollectionName)
          .doc(orderId);

      await _db.runTransaction((transaction) async {
        DocumentSnapshot snap = await transaction.get(ref);

        // جلب البيانات وتحويلها لموديل
        final List<dynamic> itemsRaw = snap[StoreOrdersModel.getItems];
        List<CartItemModel> cartItems = itemsRaw
            .map((item) => CartItemModel.fromJson(item))
            .toList();

        // التأكد من الحالة قبل التعديل
        if (cartItems[itemIndex].itemStatus == requiredCurrentStatus) {
          cartItems[itemIndex].itemStatus = newStatus;

          // تحويل القائمة بالكامل إلى Maps قبل التحديث
          transaction.update(ref, {
            StoreOrdersModel.getItems: cartItems
                .map((i) => i.toJson())
                .toList(),
          });
        }
      });
      // ملاحظة: الـ Snapshots في fetchStoreOrders ستقوم بتحديث واجهة المستخدم تلقائياً
    } catch (e) {
      Get.snackbar(
        "خطأ",
        "فشل تحديث الحالة: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /*
  Future<void> _updateItemStatus(
    String orderId,
    int itemIndex,
    ItemStatus newStatus,
    ItemStatus requiredCurrentStatus,
  ) async {
    try {
      DocumentReference ref = _db
          .collection(StoreOrdersModel.getOrderCollectionName)
          .doc(orderId);
      await _db.runTransaction((transaction) async {
        DocumentSnapshot snap = await transaction.get(ref);
        final items = snap[StoreOrdersModel.getItems];
        List<CartItemModel> cartItems = items
            .map((item) => CartItemModel.fromJson(item))
            .toList();

        if (cartItems[itemIndex].itemStatus == requiredCurrentStatus) {
          cartItems[itemIndex].itemStatus = newStatus;
          transaction.update(ref, {StoreOrdersModel.getItems: cartItems});
        }
      });
    } catch (e) {
      Get.snackbar("خطأ", "فشل تحديث الحالة: $e");
    }
  }
*/
  // 3. التحقق من رمز المتجر وإنهاء الاستلام
  Future<bool> finalizePickup(String orderId, String inputCode) async {
    final orderDoc = await _db
        .collection(StoreOrdersModel.getOrderCollectionName)
        .doc(orderId)
        .get();
    String correctCode =
        orderDoc.data()?[StoreOrdersModel.getPickupCode] ?? "0000";

    if (inputCode == correctCode) {
      await _db
          .collection(StoreOrdersModel.getOrderCollectionName)
          .doc(orderId)
          .update({
            StoreOrdersModel.getStatus: OrderStatus.shipped.name,
            StoreOrdersModel.getPickupDate: Timestamp.now(),
          });
      return true;
    }
    return false;
  }

  // فحص هل جميع العناصر عولجت (استُلمت أو رُفضت نهائياً)
  bool isOrderReadyToFinalize(StoreOrdersModel order) {
    return order.items.every(
      (item) =>
          item.itemStatus == ItemStatus.shipped ||
          item.itemStatus == ItemStatus.rejected ||
          item.itemStatus == ItemStatus.pickupFailed_Confirmed,
    );
  }
}
*/
