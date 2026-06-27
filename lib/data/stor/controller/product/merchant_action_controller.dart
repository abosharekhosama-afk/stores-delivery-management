import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stors_admin_panel/data/reposity/order/order_repository.dart';
import 'package:stors_admin_panel/data/reposity/repositories.authentication/authentication_repository.dart';
import 'package:stors_admin_panel/data/stor/models/store_orders_model.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';

class MerchantActionController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // قائمة لتخزين الطلبات التي تحتوي على منتجات تحتاج قرار
  var pendingActions = <StoreOrdersModel>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    fetchPendingActionItems();
    super.onInit();
  }

  void fetchPendingActionItems() {
    final currentStoreId = AuthenticationRepository
        .instance
        .authUser
        ?.uid; // استبدل هذا بالمعرف الحقيقي للتاجر
    // مراقبة الطلبات التي تخص هذا التاجر فقط وتحتوي على حالات معلقة
    _db
        .collection(StoreOrdersModel.getOrderCollectionName)
        .where(
          StoreOrdersModel.getStoreId,
          isEqualTo: currentStoreId,
        ) // معرف التاجر الحالي
        .snapshots()
        .listen((snapshot) {
          List<StoreOrdersModel> allOrders = snapshot.docs
              .map((doc) => StoreOrdersModel.fromSnapshot(doc))
              .toList();

          // تصفية الطلبات لعرض التي تحتوي على منتجات ينتظر فيها المندوب قرار التاجر
          pendingActions.value = allOrders.where((order) {
            return order.items.any(
              (item) =>
                  item.itemStatus == ItemStatus.pickupFailed_WaitingAction,
            );
          }).toList();

          isLoading.value = false;
        });
  }

  // الدالة التي كتبناها سابقاً لتنفيذ القرار
  Future<void> handleMerchantDecision(
    String orderId,
    String productId,
    ItemStatus decision,
  ) async {
    // إظهار لودينج بسيط
    try {
      await StoreOrderRepository.instance.updateItemStatusByProductId(
        orderId: orderId,
        productId: productId,
        newStatus: decision,
      );
      Get.back(); // إغلاق الديالوج بعد النجاح
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
