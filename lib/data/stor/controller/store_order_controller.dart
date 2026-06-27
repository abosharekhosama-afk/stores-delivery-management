import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:stors_admin_panel/data/reposity/order/order_repository.dart';
import 'package:stors_admin_panel/data/reposity/repositories.authentication/authentication_repository.dart';
import 'package:stors_admin_panel/data/stor/models/cart_item_model.dart';
import 'package:stors_admin_panel/data/stor/models/store_orders_model.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/constants/image_strings.dart';
import 'package:stors_admin_panel/utils/popups/full_screen_loader%20copy.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

// استورد StoreOrderRepository هنا

class StoreOrderController extends GetxController {
  static StoreOrderController get instance => Get.find();
  final repository = Get.put(StoreOrderRepository());
  final _localStorage = GetStorage(); // للتخزين المحلي
  // القائمة الكاملة لكل المنتجات المطلوبة من المتجر
  var allStoreOrders = <StoreOrdersModel>[].obs;
  var allStoreItems = <CartItemModel>[].obs;
  var isLoading = false.obs;
  var isMoreLoading = false.obs; // لجلب المزيد
  bool hasMoreData = true;
  final scrollController = ScrollController();

  // --- 🔍 متغيرات البحث الجديدة ---
  final textSearchController = TextEditingController();
  var isSearchActive = false.obs; // لمتابعة هل شريط البحث مفتوح أم مغلق
  var isSearchingFirebase = false.obs; // مؤشر تحميل خاص بالبحث في الفايربيز
  var filteredOrders = <StoreOrdersModel>[]
      .obs; // القائمة التي ستعرض في الواجهة (تتغير ديناميكياً)
  var isUserSearchingNow =
      false.obs; // 🌟 أضف هذا المتغير لتتبع حالة ضغط زر البحث فعلياً
  @override
  void onInit() {
    super.onInit();
    loadLocalOrders(); // جلب البيانات المخزنة محلياً أولاً

    final user = AuthenticationRepository.instance.authUser;
    if (user != null) {
      fetchInitialOrders(user.uid);
    }

    // استماع للنزول لأسفل الشاشة
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        fetchMoreOrders(user?.uid ?? "");
      }
    });
  }

  /// جلب البيانات من التخزين المحلي
  void loadLocalOrders() {
    List<dynamic>? storedData = _localStorage.read<List<dynamic>>(
      'cached_orders',
    );
    if (storedData != null) {
      allStoreOrders.assignAll(
        storedData.map((e) => StoreOrdersModel.fromJson(e)).toList(),
      );
    }
  }

  /// الجلب الأول (20 طلب)
  Future<void> fetchInitialOrders(String storeId) async {
    try {
      isLoading.value = true;
      hasMoreData = true;
      repository.lastDocument = null; // إعادة ضبط الـ Pagination

      final orders = await repository.getStoreOrders(storeId: storeId);
      allStoreOrders.assignAll(orders);

      // تخزين البيانات محلياً
      _localStorage.write(
        'cached_orders',
        orders.map((e) => e.toJson()).toList(),
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب المزيد عند النزول
  Future<void> fetchMoreOrders(String storeId) async {
    if (isMoreLoading.value || !hasMoreData) return;

    try {
      isMoreLoading.value = true;
      final newOrders = await repository.getStoreOrders(storeId: storeId);

      if (newOrders.length < 20) hasMoreData = false;

      allStoreOrders.addAll(newOrders);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      isMoreLoading.value = false;
    }
  }

  /// 🧠 دالة البحث الذكي (محلي -> فايربيز)
  Future<void> searchOrders(String query) async {
    final trimQuery = query.trim().toLowerCase();
    if (trimQuery.isEmpty) {
      clearSearch();
      return;
    }
    isUserSearchingNow.value = true;
    // 1. البحث المحلي أولاً في القائمة الحالية (بناءً على رقم الطلب أو اسم العميل أو السعر مثلاً)
    final localResults = allStoreOrders.where((order) {
      final orderId = order.storeOrderId.toLowerCase();
      return orderId.contains(trimQuery);
    }).toList();

    if (localResults.isNotEmpty) {
      // إذا وجد نتائج محلياً، اعرضها فوراً
      filteredOrders.assignAll(localResults);
    } else {
      // 2. إذا لم يجد نتائج محلياً، نذهب للبحث في الفايربيز
      try {
        isSearchingFirebase.value = true;
        filteredOrders.clear(); // تنظيف الواجهة لعرض مؤشر التحميل

        // استدعاء دالة البحث من الـ Repository الخاص بك (يجب أن تبحث بـ orderId أو الحقل المطلوب)
        final String currentStoreId =
            AuthenticationRepository.instance.authUser?.uid ?? "";
        final firebaseResults = await repository.searchOrdersInFirebase(
          trimQuery,
          currentStoreId,
        );

        if (firebaseResults.isNotEmpty) {
          filteredOrders.assignAll(firebaseResults);
        } else {
          filteredOrders.clear(); // قائمة فارغة (لم يتم العثور على نتائج)
        }
      } catch (e) {
        TLoaders.errorSnackBar(
          title: "خطأ",
          message: "فشل البحث في السيرفر: $e",
        );
      } finally {
        isSearchingFirebase.value = false;
      }
    }
  }

  /// 🧹 دالة تنظيف الحقل وإعادة القائمة لطبيعتها
  void clearSearch() {
    textSearchController.clear();
    // إعادة تعيين القائمة المفلترة لتطابق القائمة الكاملة الأصلية
    filteredOrders.assignAll(allStoreOrders);
    isUserSearchingNow.value = false; // 🌟 إغلاق وضع البحث
  }

  /// 🚫 إغلاق البحث بالكامل
  void toggleSearchStatus() {
    isSearchActive.value = !isSearchActive.value;
    if (!isSearchActive.value) {
      clearSearch();
    }
  }

  // فلترة الطلبات (Orders)
  List<StoreOrdersModel> get pendingOrders =>
      allStoreOrders.where((o) => o.status == OrderStatus.pending).toList();
  List<StoreOrdersModel> get processingOrders =>
      allStoreOrders.where((o) => o.status == OrderStatus.accepted).toList();
  List<StoreOrdersModel> get readyOrders => allStoreOrders
      .where(
        (o) =>
            o.status == OrderStatus.readyForPickup ||
            o.status == OrderStatus.shipped,
      )
      .toList();
  List<StoreOrdersModel> get rejectedOrders =>
      allStoreOrders.where((o) => o.status == OrderStatus.rejected).toList();

  // الطلبات التي خرجت مع المندوب (تم استلامها من المتجر)
  List<StoreOrdersModel> get pickedUpOrders => allStoreOrders
      .where((order) => order.status == OrderStatus.shipped)
      .toList();

  // إذا كنت تريد عرض المنتجات (Items) التي استلمها المندوب بشكل منفصل
  List<CartItemModel> get pickedUpItems => allStoreItems
      .where((item) => item.itemStatus == ItemStatus.shipped)
      .toList();

  /// فلترة الطلبات بناءً على حالتها (لاستخدامها في تبويبات الواجهة)
  List<StoreOrdersModel> get newOrder => allStoreOrders
      .where((item) => item.status == OrderStatus.pending)
      .toList();

  List<StoreOrdersModel> get processingOrder => allStoreOrders
      .where((item) => item.status == OrderStatus.accepted)
      .toList();

  List<StoreOrdersModel> get readyOrder => allStoreOrders
      .where((item) => item.status == OrderStatus.readyForPickup)
      .toList();

  List<StoreOrdersModel> get rejectedOrder => allStoreOrders
      .where((item) => item.status == OrderStatus.rejected)
      .toList();

  /// فلترة المنتجات بناءً على حالتها (لاستخدامها في تبويبات الواجهة)
  List<CartItemModel> get newItems => allStoreItems
      .where((item) => item.itemStatus == ItemStatus.pending)
      .toList();

  List<CartItemModel> get processingItems => allStoreItems
      .where((item) => item.itemStatus == ItemStatus.accepted)
      .toList();

  List<CartItemModel> get readyItems => allStoreItems
      .where((item) => item.itemStatus == ItemStatus.readyForPickup)
      .toList();

  List<CartItemModel> get rejectedItems => allStoreItems
      .where((item) => item.itemStatus == ItemStatus.rejected)
      .toList();

  /// تغيير حالة المنتج
  Future<void> changeStatus({
    required String storeOrderId,
    required String mainOrderId,
    required String productId,
    required String variationId, // 🌟 تم إضافته لضمان التتبع الحرفي
    required ItemStatus status,
    required ItemStatus currentStatus,
  }) async {
    try {
      TFullScreenLoader.openLoadingDialog(
        'جاري تحديث الحالة وتأمين البيانات...',
        TImages.defaultLoaderAnimation,
      );

      // 1. التحديث الفعلي في السيرفر
      final result = await repository.updateItemStatus(
        mainOrderId: mainOrderId,
        productId: productId,
        variationId: variationId, // تمرير القيمة الحركية السليمة
        currentStatus: currentStatus,
        newStatus: status,
      );

      // 2. التحديث الفوري في الذاكرة المحلية (Local State Management) لضمان تفاعل واجهة الرسوميات
      int orderIndex = allStoreOrders.indexWhere(
        (o) => o.mainOrderId == mainOrderId,
      );

      if (orderIndex != -1) {
        // البحث عن المنتج المطابق حرفياً بالمعرفين: productId والـ variationId معاً
        int itemIndex = allStoreOrders[orderIndex].items.indexWhere(
          (i) =>
              i.productId == productId &&
              (i.variationId).trim() == variationId.trim(),
        );

        if (itemIndex != -1) {
          allStoreOrders[orderIndex].items[itemIndex].itemStatus = status;
          allStoreOrders.refresh(); // إعلام واجهات Obx بالتحديث الفوري
        }
      }

      TFullScreenLoader.stopLoading();
      TLoaders.successSnackBar(
        title: 'تم التحديث بنجاح 🎉',
        message:
            result['message'] ?? 'تم حفظ الحالات الجديدة على الداتابيز الحية.',
      );
    } catch (e) {
      TFullScreenLoader.stopLoading(); // تأمين إغلاق نافذة الانتظار عند حدوث أي استثناء
      TLoaders.errorSnackBar(
        title: 'عذراً، فشلت العملية',
        message: e.toString().replaceAll(
          'Exception: ',
          '',
        ), // تنظيف نص الخطأ المعروض للتاجر
      );
    }
  }

  /*
  Future<void> changeStatus(
    String storeOrderId,
    String mainOrderId,
    String productId,
    ItemStatus status,
    ItemStatus currentStatus,
  ) async {
    try {
      TFullScreenLoader.openLoadingDialog(
        'جاري تحديث الحالة...',
        TImages.defaultLoaderAnimation,
      );

      // 1. التحديث في قاعدة البيانات (Firebase)
      await repository.updateItemStatus(
        storeOrderId: storeOrderId,
        mainOrderId: mainOrderId,
        productId: productId,
        newStatus: status,
        variationId: '',
        currentStatus: currentStatus,
      );

      // 2. التحديث في الذاكرة المحلية (Local List)
      // نبحث عن الطلب في القائمة الموجودة في الكنترولر
      int orderIndex = allStoreOrders.indexWhere(
        (o) => o.mainOrderId == mainOrderId,
      );

      if (orderIndex != -1) {
        // نبحث عن المنتج داخل هذا الطلب
        int itemIndex = allStoreOrders[orderIndex].items.indexWhere(
          (i) => i.productId == productId,
        );

        if (itemIndex != -1) {
          // تحديث حالة المنتج داخل القائمة
          allStoreOrders[orderIndex].items[itemIndex].itemStatus = status;

          // السطر الأهم: إخبار GetX أن القائمة تغيرت ليقوم بتحديث Obx
          allStoreOrders.refresh();
        }
      }

      TFullScreenLoader.stopLoading();
      TLoaders.successSnackBar(
        title: 'تم',
        message: 'تم تحديث حالة المنتج بنجاح',
      );
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'عذراً', message: e.toString());
    }
  }
*/
  // دالة مساعدة للحصول على منتجات طلب معين
  List<CartItemModel> getItemsForOrder(String mainOrderId) {
    // استخدام firstWhereOrNull لضمان عدم حدوث خطأ إذا كانت القائمة فارغة
    final order = allStoreOrders.firstWhereOrNull(
      (o) => o.mainOrderId == mainOrderId,
    );
    return order?.items ?? [];
  }
}


  
  /*
  void fetchStoreOrders(String currentStoryId) {
    isLoading.value = true;

    repository
        .getStoreOrders(currentStoryId)
        .listen(
          (ordersList) {
            debugPrint(
              "RAW DATA: ${ordersList.length} orders found in Firestore for ID: $currentStoryId",
            );
            debugPrint(
              "عدد المستندات الواصلة من الفايربيز: ${ordersList.length}",
            ); // تأكد من الرقم هنا

            if (ordersList.isNotEmpty) {
              debugPrint(
                "أول طلب يحتوي على منتجات عددها: ${ordersList.first.items.length}",
              );
            }
            List<CartItemModel> flattenedItems =
                []; // قائمة مؤقتة لتجميع المنتجات

            for (var order in ordersList) {
              var mainOrderId = order.mainOrderId;
              List<CartItemModel> items = order.items ?? [];

              for (var item in items) {
                item.mainOrderId = mainOrderId;
                flattenedItems.add(
                  item,
                ); // ✅ استخدام add بدلاً من assignAll لتجميع كل شيء
              }
            }

            allStoreOrders.assignAll(ordersList);
            allStoreItems.assignAll(
              flattenedItems,
            ); // نستخدم assignAll هنا فقط في النهاية

            debugPrint("Total Orders: ${allStoreOrders.length}");
            debugPrint("Total Items: ${allStoreItems.length}");

            isLoading.value = false;
          },
          onError: (error) {
            // مهم جداً لمعرفة سبب توقف الـ Stream (مثل مشكلة الـ Index)
            debugPrint("Stream Error: $error");
            isLoading.value = false;
          },
        );
  }
*/
  /*
  /// جلب الطلبات وفك تفكيكها (Flattening) ليسهل عرضها في التبويبات
  void fetchStoreOrders(String currentStoreId) {
    isLoading.value = true;

    repository.getMyStoreOrders(currentStoreId).listen((ordersList) {
      List<Map<String, dynamic>> flattenedItems = [];

      for (var order in ordersList) {
        List<dynamic> items = order['items'] ?? [];
        for (var item in items) {
          // نضيف بيانات الطلب الأب للمنتج لكي نعرف لأي طلب ينتمي
          item['storeOrderId'] = order['storeOrderId'];
          item['mainOrderId'] = order['mainOrderId'];
          item['orderDate'] = order['orderDate'];
          flattenedItems.add(item);
        }
      }

      allStoreItems.assignAll(flattenedItems);
      isLoading.value = false;
    });
  }
*/

  /* Future<void> changeStatus(
    String storeOrderId,
    String mainOrderId,
    String productId,
    ItemStatus status,
  ) async {
    try {
      TFullScreenLoader.openLoadingDialog(
        'جاري تحديث الحالة...',
        TImages.defaultLoaderAnimation,
      );

      await repository.updateItemStatus(
        storeOrderId: storeOrderId,
        mainOrderId: mainOrderId,
        productId: productId,
        newStatus: status,
      );

      TFullScreenLoader.stopLoading();
      TLoaders.successSnackBar(
        title: 'تم',
        message: 'تم تحديث حالة المنتج بنجاح',
      );
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'عذراً', message: e.toString());
    }
  }
*/
  /*
  /// فلترة الطلبات بناءً على حالة مستند الطلب (StoreOrdersModel)
  List<StoreOrdersModel> get newOrders => allStoreOrders
      .where(
        (order) => order.status == OrderStatus.pending,
      ) // أو حسب الـ Enum لديك
      .toList();

  List<StoreOrdersModel> get processingOrders => allStoreOrders
      .where((order) => order.status == OrderStatus.processing)
      .toList();

  List<StoreOrdersModel> get readyOrders => allStoreOrders
      .where((order) => order.status == OrderStatus.shipped)
      .toList();
*/

  /*List<CartItemModel> getItemsForOrder(String mainOrderId) {
    final order = allStoreOrders.firstWhere(
      (o) => o.mainOrderId == mainOrderId,
    );
    return order.items ?? [];
  }*/

