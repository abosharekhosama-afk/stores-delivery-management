import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/stor/models/cart_item_model.dart';
import 'package:stors_admin_panel/data/stor/models/store_orders_model.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/exceptions/firebase_exceptions.dart';
import 'package:stors_admin_panel/utils/exceptions/format_exceptions.dart';
import 'package:stors_admin_panel/utils/exceptions/platform_exceptions.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class StoreOrderRepository extends GetxController {
  static StoreOrderRepository get instance => Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // خريطة لتحديد التسلسل المنطقي للحالات (لمنع التاجر من إعادة منتج جاهز إلى قيد التجهيز)
  final Map<String, int> _statusOrder = {
    ItemStatus.pending.name: 0, // جديد
    ItemStatus.accepted.name: 1, // قيد التجهيز
    ItemStatus.readyForPickup.name: 2, // جاهز للاستلام
    ItemStatus.delivered.name: 3, // تم التسليم
    ItemStatus.rejected.name: -1, // مرفوض (حالة نهائية)
  };

  /* ------------------ وظيفة للمتجر: جلب طلباته فقط ------------------ */
  Stream<List<StoreOrdersModel>> getStoreOrdersStream(String storeId) {
    try {
      return _db
          .collection(StoreOrdersModel.getOrderCollectionName)
          .where(StoreOrdersModel.getStoreId, isEqualTo: storeId)
          .orderBy(StoreOrdersModel.getOrderDate, descending: true)
          .snapshots()
          .map((snapshot) {
            // طباعة عدد المستندات التي وصلت فعلياً من Firestore
            debugPrint("--- تم استقبال تحديث من Firestore ---");
            debugPrint("عدد المستندات الخام: ${snapshot.docs.length}");

            return snapshot.docs.map((doc) {
              try {
                return StoreOrdersModel.fromSnapshot(doc);
              } catch (e) {
                debugPrint("خطأ في تحويل المستند رقم ${doc.id}: $e");
                return StoreOrdersModel.empty(); // منع انهيار القائمة كاملة بسبب مستند واحد خطأ
              }
            }).toList();
          });
    } catch (e) {
      debugPrint("خطأ في إنشاء استعلام الـ Stream: $e");
      rethrow;
    }
  }

  DocumentSnapshot? lastDocument; // لتخزين آخر مستند تم جلبه

  /// جلب الطلبات مع Pagination
  Future<List<StoreOrdersModel>> getStoreOrders({
    required String storeId,
    int limit = 20,
  }) async {
    try {
      Query query = _db
          .collection(StoreOrdersModel.getOrderCollectionName)
          .where(StoreOrdersModel.getStoreId, isEqualTo: storeId)
          .orderBy(StoreOrdersModel.getOrderDate, descending: true)
          .limit(limit);

      // إذا كان هناك مستند سابق، ابدأ من بعده
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        lastDocument = snapshot.docs.last; // تحديث آخر مستند
      }

      return snapshot.docs
          .map((doc) => StoreOrdersModel.fromSnapshot(doc))
          .toList();
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

  /// 🔍 دالة البحث عن طلب معين في الفايربيز باستخدام رقم الطلب فقط وللمتجر الحالي
  Future<List<StoreOrdersModel>> searchOrdersInFirebase(
    String orderId,
    String storeId,
  ) async {
    try {
      // الاستعلام يبحث عن المستند الذي يطابق رقم المتجر ورقم الطلب معاً
      final snapshot = await _db
          .collection(StoreOrdersModel.getOrderCollectionName)
          .where(StoreOrdersModel.getStoreId, isEqualTo: storeId)
          .where(
            StoreOrdersModel.getStoreOrderId,
            isEqualTo: orderId,
          ) // أو اإستبدل 'id' بـ StoreOrdersModel.getOrderId إذا كان معرّفاً كـ Constant
          .get();

      // تحويل المستندات الناتجة إلى قائمة من الـ Model الخاص بك
      return snapshot.docs
          .map((doc) => StoreOrdersModel.fromSnapshot(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطأ غير متوقع أثناء البحث. الرجاء المحاولة مجدداً";
    }
  }

  /// 1. جلب جميع طلبات المتجر لحظياً (Stream)
  Stream<List<Map<String, dynamic>>> getMyStoreOrders(String storeId) {
    return _db
        .collection('StoreOrders')
        .where('storeId', isEqualTo: storeId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['storeOrderId'] =
                doc.id; // حفظ معرف المستند لتسهيل التعديل لاحقاً
            return data;
          }).toList(),
        );
  }

  Future<Map<String, dynamic>> updateItemStatus({
    required String mainOrderId,
    required String productId,
    required String
    variationId, // مرر القيمة الحقيقية للمنتج (حتى لو كانت فارغة)
    required ItemStatus currentStatus,
    required ItemStatus newStatus,
  }) async {
    try {
      // 1. التحقق المحلي الصارم قبل استهلاك موارد السيرفر
      if (currentStatus == ItemStatus.rejected ||
          currentStatus == ItemStatus.delivered) {
        throw 'لا يمكن التعديل على منتج حالته الحالية نهائية مقفلة.';
      }

      if (newStatus == ItemStatus.pending) {
        throw 'غير مسموح بإعادة المنتج إلى حالة قيد الانتظار بعد البدء في تجهيزه.';
      }

      // 2. استدعاء الدالة بأمان
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'updateItemStatusInCloud',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );

      final response = await callable.call(<String, dynamic>{
        'mainOrderId': mainOrderId.trim(),
        'productId': productId.trim(),
        'variationId': variationId
            .trim(), // سترسل "" إذا لم يكن هناك فاريشن وهو مطابق للسيرفر الآن
        'newStatus':
            newStatus.name, // يرسل اسم الحالة مثل 'accepted' أو 'delivered'
      });

      if (response.data != null && response.data['status'] == 'success') {
        return {
          'success': true,
          'message': response.data['message'] ?? 'تم تحديث الحالة بنجاح.',
        };
      } else {
        throw 'استجابة غير متوقعة من السيرفر.';
      }
    } on FirebaseFunctionsException catch (e) {
      // التقاط أخطاء الـ HttpsError القادمة من السيرفر وعرض رسالتها المكتوبة بالعربية بدقة
      throw e.message ?? 'حدث خطأ أثناء معالجة الطلب في السيرفر.';
    } catch (e) {
      throw e.toString();
    }
  }

  /*
  Future<void> updateItemStatus({
    required String mainOrderId,
    required String productId,
    required String variationId, // مرر قيمة فارغة "" إذا لم يكن للمنتج خيارات
    required ItemStatus
    currentStatus, // الحالة الحالية للمنتج المخزنة في الـ Model محلياً
    required ItemStatus newStatus,
    required String storeOrderId, // الحالة الجديدة المراد التغيير إليها
  }) async {
    try {
      // ==========================================
      // 1. التحقق المحلي (قبل إرسال الطلب للسيرفر)
      // ==========================================

      // أ) التحقق من الحالات النهائية
      if (currentStatus == 'rejected' || currentStatus == 'delivered') {
        TLoaders.errorSnackBar(
          title: 'عملية غير مسموحة',
          message:
              'لا يمكن التعديل على منتج حالته الحالية نهائية ($currentStatus).',
        );
        return; // إيقاف التنفيذ فوراً دون إرسال طلب للسيرفر
      }

      int currentIndex = _statusOrder[currentStatus] ?? 0;
      int nextIndex = _statusOrder[newStatus.name] ?? 0;

      // ب) التحقق من التسلسل الخطي (منع الرجوع للخلف إلا في حالة الرفض)
      if (newStatus != ItemStatus.rejected && nextIndex <= currentIndex) {
        TLoaders.errorSnackBar(
          title: 'خطأ في تسلسل الحالات',
          message: 'لا يمكن التراجع للخلف أو إعادة اختيار نفس الحالة الحالية.',
        );
        return; // إيقاف التنفيذ
      }

      // ج) منع إعادة المنتج لحالة معلق
      if (newStatus == ItemStatus.pending) {
        TLoaders.errorSnackBar(
          title: 'عملية مرفوضة',
          message:
              'لا يمكن إعادة المنتج إلى حالة "قيد الانتظار" بعد البدء في معالجته.',
        );
        return;
      }

      // ==========================================
      // 2. التنفيذ واستدعاء الـ Cloud Function
      // ==========================================

      // إظهار مؤشر الانتظار الجذاب للمستخدم
      TFullScreenLoader.openLoadingDialog(
        'جاري تحديث حالة المنتج على السيرفر...',
        TImages.defaultLoaderAnimation, // أو الـ Loader الخاص بك
      );

      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'updateItemStatusInCloud',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );

      final response = await callable.call(<String, dynamic>{
        'mainOrderId': mainOrderId,
        'productId': productId,
        'variationId': variationId,
        'newStatus': newStatus.name,
      });

      // إغلاق الـ Loader فوراً بعد استجابة السيرفر
      TFullScreenLoader.stopLoading();

      // معالجة النجاح
      if (response.data != null && response.data['status'] == 'success') {
        // 🌟 [ملاحظة تكتيكية]: هنا تقوم بتحديث الـ State المحلية في الكنترولر الخاص بك
        // ليراها المستخدم مباشرة في الواجهة بدون الحاجة لإعادة عمل Refresh كامل من قاعدة البيانات.

        TLoaders.successSnackBar(
          title: 'تم التحديث بنجاح 🎉',
          message:
              response.data['message'] ??
              'تم حفظ الحالات الجديدة وتأمين الطلب خطياً.',
        );
      }
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
*/
  /// 2. تحديث حالة منتج معين مع ضمان التسلسل
  /*
  Future<void> updateItemStatus({
    required String storeOrderId,
    required String mainOrderId,
    required String productId,
    required ItemStatus newStatus,
  }) async {
    try {
      // 1. جلب المستند أولاً
      final querySnapshot = await _db
          .collection(StoreOrdersModel.getOrderCollectionName)
          .where(StoreOrdersModel.getStoreId, isEqualTo: storeOrderId)
          .where(StoreOrdersModel.getMainOrderId, isEqualTo: mainOrderId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw 'لم يتم العثور على طلب المتجر المطلوب.';
      }

      final storeOrderRef = querySnapshot.docs.first.reference;

      await _db.runTransaction((transaction) async {
        DocumentSnapshot storeSnap = await transaction.get(storeOrderRef);
        if (!storeSnap.exists) throw 'الطلب غير موجود.';

        List<dynamic> rawItems = storeSnap['Items'] ?? [];
        List<CartItemModel> items = rawItems
            .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
            .toList();

        bool itemFound = false;

        for (var item in items) {
          if (item.productId == productId) {
            var currentStatus =
                item.itemStatus ??
                ItemStatus.pending.name; // تأكد من مسمى الحقل

            // التحقق من التسلسل
            int currentIndex = _statusOrder[currentStatus] ?? 0;
            int nextIndex = _statusOrder[newStatus.name] ?? 0;

            if (currentStatus == ItemStatus.rejected.name ||
                currentStatus == ItemStatus.delivered.name) {
              throw 'لا يمكن تعديل منتج مرفوض أو تم تسليمه.';
            }
            if (nextIndex <= currentIndex && newStatus != ItemStatus.rejected) {
              throw 'لا يمكن العودة للحالة السابقة.';
            }

            // تحديث الحالة
            item.itemStatus = newStatus;
            itemFound = true;
            break;
          }
        }

        if (!itemFound) throw 'المنتج غير موجود في هذا الطلب.';

        // تحويل للتحفيظ
        List<Map<String, dynamic>> itemsToSave = items
            .map((item) => item.toJson())
            .toList();

        // ✅ التحديث الوحيد المطلوب هنا: تحديث طلب المتجر
        // الكلاود فانكشن ستلتقط هذا التحديث وتقوم بالباقي تلقائياً
        transaction.update(storeOrderRef, {'Items': itemsToSave});
        _checkIfStoreOrderIsFullyReady(transaction, storeOrderRef, items);
        // ملاحظة: يمكنك إبقاء تحديث RejectedAmount هنا أو نقله للكلاود
        // يفضل إبقاؤه هنا إذا أردت استجابة فورية في واجهة المستخدم (Optimistic UI)
      });
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
*/
  /*Future<void> updateItemStatus({
    required String storeOrderId,
    required String mainOrderId,
    required String productId,
    required ItemStatus newStatus,
  }) async {
    try {
      final querySnapshot = await _db
          .collection(StoreOrdersModel.getOrderCollectionName)
          .where(StoreOrdersModel.getStoreId, isEqualTo: storeOrderId)
          .where(StoreOrdersModel.getMainOrderId, isEqualTo: mainOrderId)
          .limit(1) // نحتاج مستند واحد فقط
          .get();

      if (querySnapshot.docs.isEmpty)
        throw 'لم يتم العثور على طلب المتجر المطلوب.';

      await _db.runTransaction((transaction) async {
        final storeOrderRef = querySnapshot.docs.first.reference;
        final mainOrderRef = _db.collection('Orders').doc(mainOrderId);

        DocumentSnapshot storeSnap = await transaction.get(storeOrderRef);
        if (!storeSnap.exists) throw 'الطلب غير موجود في قاعدة البيانات.';

        // ✅ 1. التعديل الأول: تحويل الـ Map القادم من فايربيز إلى كائنات CartItemModel
        List<dynamic> rawItems = storeSnap['Items'] ?? [];
        List<CartItemModel> items = rawItems
            .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
        bool itemFound = false;
        double priceToRefund = 0.0;

        // البحث عن المنتج المطلوب داخل الطلب وتحديثه
        for (var item in items) {
          if (item.productId == productId) {
            var currentStatus = item.itemStatus ?? ItemStatus.pending.name;

            // --- التحقق من التسلسل (المنع من العودة للخلف) ---
            int currentIndex = _statusOrder[currentStatus] ?? 0;
            int nextIndex = _statusOrder[newStatus.name] ?? 0;

            if (currentStatus == ItemStatus.rejected.name ||
                currentStatus == ItemStatus.delivered.name) {
              throw 'لا يمكن تعديل منتج مرفوض أو تم تسليمه.';
            }
            if (nextIndex <= currentIndex && newStatus != ItemStatus.rejected) {
              throw 'لا يمكن العودة للحالة السابقة.';
            }
            // ------------------------------------------------

            item.itemStatus = newStatus;
            itemFound = true;

            // حساب المرتجع إذا تم الرفض
            if (newStatus == ItemStatus.rejected) {
              priceToRefund = (item.price * item.quantity).toDouble();
            }
            break;
          }
        }

        if (!itemFound) throw 'المنتج غير موجود في هذا الطلب.';

        // ✅ 2. التعديل الثاني: تحويل الكائنات مرة أخرى إلى Map قبل إرسالها لفايربيز
        List<Map<String, dynamic>> itemsToSave = items
            .map((item) => item.toJson())
            .toList();

        // تنفيذ التحديثات
        transaction.update(storeOrderRef, {'Items': itemsToSave});

        // إذا كان هناك رفض، نضيف المبلغ المرتجع للطلب الرئيسي للزبون
        if (priceToRefund > 0) {
          transaction.update(mainOrderRef, {
            'RejectedAmount': FieldValue.increment(priceToRefund),
          });
        }

        // فحص ما إذا كانت كل منتجات المتجر أصبحت "جاهزة"، لنغير حالة الطلب الكلي
        _checkIfStoreOrderIsFullyReady(transaction, storeOrderRef, items);
      });
    } catch (e) {
      throw e.toString();
    }
  }
*/
  /// دالة داخلية: لتحديث حالة المستند الكلي للمتجر ليظهر للمندوب
  void _checkIfStoreOrderIsFullyReady(
    Transaction transaction,
    DocumentReference ref,
    List<CartItemModel> items,
  ) {
    // 1. هل انتهى العمل على جميع العناصر؟ (سواء جهزت أو رفضت)
    bool allProcessed = items.every(
      (item) =>
          item.itemStatus == ItemStatus.readyForPickup ||
          item.itemStatus == ItemStatus.rejected,
    );

    // 2. هل يوجد عنصر واحد على الأقل جاهز فعلياً؟
    bool atLeastOneReady = items.any(
      (item) => item.itemStatus == ItemStatus.readyForPickup,
    );

    if (allProcessed) {
      if (atLeastOneReady) {
        // إذا انتهى الكل ويوجد شيء جاهز للاستلام
        transaction.update(ref, {StoreOrdersModel.getStatus: 'readyForPickup'});
      } else {
        // إذا انتهى الكل ولكن الجميع مرفوضون
        transaction.update(ref, {StoreOrdersModel.getStatus: 'rejected'});
      }
    }
  }

  /// [للتاجر] الموافقة على طلب المندوب بإلغاء المنتج لتعذر الاستلام
  Future<void> confirmItemCancellation(String orderId, String productId) async {
    // نحولها إلى rejected لأن الـ Cloud Function تراقب هذه الحالة لخصم المال
    await updateItemStatusByProductId(
      orderId: orderId,
      productId: productId,
      newStatus: ItemStatus.rejected,
    );

    // ملاحظة: يمكنك هنا إضافة إرسال إشعار للمندوب بأن التاجر وافق على الإلغاء
  }

  /// [للتاجر] رفض طلب المندوب بالإلغاء وإعادة المنتج للحالة الجاهزة
  Future<void> rejectItemCancellation(String orderId, String productId) async {
    await updateItemStatusByProductId(
      orderId: orderId,
      productId: productId,
      newStatus: ItemStatus.readyForPickup,
    );
  }

  // تحديث حالة المنتج مع طباعة تفصيلية
  Future<void> updateItemStatusByProductId({
    required String orderId,
    required String productId,
    required ItemStatus newStatus,
  }) async {
    debugPrint(
      "🛠️ [Merchant Decision]: محاولة معالجة طلب إلغاء المنتج $productId",
    );

    try {
      DocumentReference ref = _db
          .collection(StoreOrdersModel.getOrderCollectionName)
          .doc(orderId);

      await _db.runTransaction((transaction) async {
        DocumentSnapshot snap = await transaction.get(ref);

        if (!snap.exists) throw "الوثيقة غير موجودة";

        // 1. جلب المصفوفة وتحويلها
        final List<dynamic> itemsRaw = snap[StoreOrdersModel.getItems] ?? [];
        List<CartItemModel> cartItems = itemsRaw
            .map((item) => CartItemModel.fromJson(item))
            .toList();

        // 2. البحث عن المنتج المستهدف
        int index = cartItems.indexWhere((item) => item.productId == productId);

        if (index != -1) {
          // 3. القيد الصارم: التحديث مسموح فقط إذا كانت الحالة "انتظار قرار التاجر"
          if (cartItems[index].itemStatus ==
              ItemStatus.pickupFailed_WaitingAction) {
            // تحديث الحالة بناءً على قرار التاجر (إما Rejected للموافقة أو Ready للرفض)
            cartItems[index].itemStatus = newStatus;

            transaction.update(ref, {
              StoreOrdersModel.getItems: cartItems
                  .map((i) => i.toJson())
                  .toList(),
            });

            debugPrint("✅ [Transaction]: تم تنفيذ قرار التاجر بنجاح.");
          } else {
            // إذا كانت الحالة ليست "انتظار"، فهذا يعني أن التحديث قد تم مسبقاً أو هناك خطأ
            debugPrint(
              "⚠️ [Blocked]: المنتج ليس في حالة 'انتظار القرار'. الحالة الحالية: ${cartItems[index].itemStatus}",
            );
            throw "هذا المنتج تم معالجته مسبقاً أو حالته تغيرت.";
          }
        } else {
          debugPrint("⚠️ [Not Found]: المنتج غير موجود.");
        }
      });
    } catch (e) {
      debugPrint("❌ [Merchant Error]: $e");
      TLoaders.warningSnackBar(title: "تنبيه", message: e.toString());
    }
  }

  /* void _checkIfStoreOrderIsFullyReady(
    Transaction transaction,
    DocumentReference ref,
    List<CartItemModel> items,
  ) {
    bool allReadyOrRejected = items.every(
      (item) =>
          item.itemStatus == ItemStatus.readyForPickup ||
          item.itemStatus == ItemStatus.rejected,
    );

    if (allReadyOrRejected) {
      transaction.update(ref, {StoreOrdersModel.getStatus: 'readyForPickup'});
    }
  }
*/
}
